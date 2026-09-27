#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
RUNS=${RUNS:-5}
SETTLE_SECONDS=${SETTLE_SECONDS:-10}
MDVIEW_BIN=${MDVIEW_BIN:-"$ROOT/.build/release/mdview"}
FIXTURE="$ROOT/Benchmarks/fixture.md"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/mdview-benchmark.XXXXXX")
HELPER="$WORK_DIR/window-benchmark"

cleanup() {
    pkill -x mdview 2>/dev/null || true
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

cd "$ROOT"
swift build -c release >/dev/null
swiftc -O Benchmarks/window-benchmark.swift -o "$HELPER"

stop_processes() {
    pkill -x mdview 2>/dev/null || true
    sleep 0.5
}

benchmark_process_cold_launches() {
    : > "$WORK_DIR/process-cold"
    for ((run = 1; run <= RUNS; run++)); do
        stop_processes
        "$HELPER" "$MDVIEW_BIN" mdview -- "$FIXTURE" >> "$WORK_DIR/process-cold"
    done
    stop_processes
}

benchmark_warm_process_launches() {
    : > "$WORK_DIR/warm-process"
    stop_processes
    "$HELPER" "$MDVIEW_BIN" mdview --keep -- "$FIXTURE" >/dev/null
    sleep 0.5
    for ((run = 1; run <= RUNS; run++)); do
        "$HELPER" "$MDVIEW_BIN" mdview -- "$FIXTURE" >> "$WORK_DIR/warm-process"
        sleep 0.2
    done
    stop_processes
}

benchmark_memory() {
    stop_processes
    ps -axo pid=,command= > "$WORK_DIR/processes-before"
    "$MDVIEW_BIN" "$FIXTURE" >/dev/null 2>"$WORK_DIR/mdview.stderr" &
    sleep "$SETTLE_SECONDS"
    ps -axo pid=,command= > "$WORK_DIR/processes-after"

    local pids pid_csv rss_kib cpu threads footprint_mib
    pids=$(python3 - "$WORK_DIR/processes-before" "$WORK_DIR/processes-after" <<'PY'
import sys

def read(path):
    result = {}
    with open(path) as source:
        for line in source:
            fields = line.strip().split(None, 1)
            if len(fields) == 2:
                result[int(fields[0])] = fields[1]
    return result

before, after = read(sys.argv[1]), read(sys.argv[2])
selected = []
for pid, command in after.items():
    is_new_webkit = pid not in before and "com.apple.WebKit." in command
    executable = command.split()[0]
    is_mdview = executable.endswith("/mdview") or executable == "mdview"
    if is_new_webkit or is_mdview:
        selected.append(pid)
print(" ".join(map(str, selected)))
PY
)

    if [[ -z "$pids" ]]; then
        echo "Could not identify mdview processes." >&2
        exit 1
    fi

    pid_csv=$(tr ' ' ',' <<<"$pids")
    rss_kib=$(ps -o rss= -p "$pid_csv" | awk '{ total += $1 } END { print total + 0 }')
    cpu=$(ps -o %cpu= -p "$pid_csv" | awk '{ total += $1 } END { printf "%.1f", total + 0 }')
    threads=0
    for pid in $pids; do
        count=$(ps -M -p "$pid" 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
        threads=$((threads + count))
    done

    footprint --noCategories $pids > "$WORK_DIR/footprint" 2>/dev/null
    footprint_mib=$(python3 - "$WORK_DIR/footprint" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
match = re.search(r"Summary Footprint:\s+([0-9.]+)\s+(KB|MB|GB)", text)
if not match:
    match = re.search(r"Footprint:\s+([0-9.]+)\s+(KB|MB|GB)", text)
if not match:
    raise SystemExit("Unable to parse footprint output")
value, unit = float(match.group(1)), match.group(2)
scale = {"KB": 1 / 1024, "MB": 1, "GB": 1024}[unit]
print(f"{value * scale:.1f}")
PY
)

    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$rss_kib" "$footprint_mib" "$cpu" "$threads" "$(wc -w <<<"$pids" | tr -d ' ')" \
        > "$WORK_DIR/memory"
    stop_processes
}

benchmark_process_cold_launches
benchmark_warm_process_launches
benchmark_memory

installed_bytes=$(
    {
        stat -f %z "$MDVIEW_BIN"
        find "$(dirname "$MDVIEW_BIN")/mdview_MDView.bundle" -type f -exec stat -f %z {} \;
    } | awk '{ total += $1 } END { print total }'
)
tar -czf "$WORK_DIR/mdview.tar.gz" -C "$(dirname "$MDVIEW_BIN")" \
    "$(basename "$MDVIEW_BIN")" mdview_MDView.bundle
archive_bytes=$(stat -f %z "$WORK_DIR/mdview.tar.gz")

python3 - \
    "$WORK_DIR" "$RUNS" "$SETTLE_SECONDS" \
    "$installed_bytes" "$archive_bytes" <<'PY'
import datetime
import os
import platform
import statistics
import sys

work, runs, settle, installed, archive = sys.argv[1:]

def timings(name):
    with open(os.path.join(work, name)) as source:
        return [float(line.split()[0]) for line in source if line.strip()]

def memory():
    with open(os.path.join(work, "memory")) as source:
        rss, footprint, cpu, threads, processes = source.read().split("\t")
    return {
        "rss": int(rss) / 1024,
        "footprint": float(footprint),
        "cpu": float(cpu),
        "threads": int(threads),
        "processes": int(processes),
    }

def mib(value):
    return int(value) / 1024 / 1024

process_cold = timings("process-cold")
warm_process = timings("warm-process")
mem = memory()

print("# mdview benchmark result")
print()
print(f"- Date: {datetime.datetime.now().astimezone().isoformat(timespec='seconds')}")
print(f"- Platform: {platform.platform()}")
print(f"- Runs per launch scenario: {runs}")
print(f"- Memory settling time: {settle} seconds")
print(f"- Fixture: 192-byte local Markdown document")
print()
print("## Results")
print()
print("| Metric | Result |")
print("| --- | ---: |")
print(f"| Process-cold time to window, median | {statistics.median(process_cold):.1f} ms |")
print(f"| Process-cold time to window, mean | {statistics.mean(process_cold):.1f} ms |")
print(f"| Warm-process time to new window, median | {statistics.median(warm_process):.1f} ms |")
print(f"| Warm-process time to new window, mean | {statistics.mean(warm_process):.1f} ms |")
print(f"| Physical footprint after {settle}s | {mem['footprint']:.1f} MiB |")
print(f"| Aggregate RSS after {settle}s | {mem['rss']:.1f} MiB |")
print(f"| Process count | {mem['processes']} |")
print(f"| Thread count | {mem['threads']} |")
print(f"| CPU snapshot after {settle}s | {mem['cpu']:.1f}% |")
print(f"| Installed payload | {mib(installed):.3f} MiB |")
print(f"| Compressed payload | {mib(archive):.3f} MiB |")
print()
print("## Raw launch samples")
print()
print(f"- Process-cold: {', '.join(f'{x:.1f}' for x in process_cold)} ms")
print(f"- Warm-process: {', '.join(f'{x:.1f}' for x in warm_process)} ms")
PY
