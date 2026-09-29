#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
RUNS=${RUNS:-6}
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/mdview-render-benchmark.XXXXXX")
HELPER="$WORK_DIR/render-benchmark"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

if (( RUNS < 2 )); then
    echo "RUNS must be at least 2 (one initial render and one warm render)." >&2
    exit 2
fi

SYSTEM_SNAPSHOT=$(top -l 1 -n 0)
export SYSTEM_SNAPSHOT
FIXTURE_DIR="$ROOT/Benchmarks/Fixtures"

swiftc -O Benchmarks/render-benchmark.swift \
    -framework AppKit \
    -framework WebKit \
    -o "$HELPER"

for fixture in prose-10kb prose-50kb prose-100kb code-heavy-100kb; do
    /usr/bin/time -l "$HELPER" "$ROOT" "$FIXTURE_DIR/$fixture.md" "$RUNS" \
        > "$WORK_DIR/$fixture.json" \
        2> "$WORK_DIR/$fixture.time"
done

python3 - "$WORK_DIR" "$FIXTURE_DIR" "$RUNS" <<'PY'
import datetime
import json
import os
import platform
import statistics
import subprocess
import sys

work = sys.argv[1]
fixture_dir = sys.argv[2]
runs = int(sys.argv[3])
fixtures = ["prose-10kb", "prose-50kb", "prose-100kb", "code-heavy-100kb"]

def milliseconds(values):
    return f"{statistics.median(values):.1f}"

print("# mdview render benchmark")
print()
print(f"- Date: {datetime.datetime.now().astimezone().isoformat(timespec='seconds')}")
hardware = subprocess.run(
    ["system_profiler", "SPHardwareDataType"], capture_output=True, text=True, check=True
).stdout
cpu = next((line.strip() for line in hardware.splitlines() if "Chip:" in line or "Processor Name:" in line), "Unknown")
cores = next((line.strip() for line in hardware.splitlines() if "Total Number of Cores:" in line), "Unknown")
memory = next((line.strip() for line in hardware.splitlines() if "Memory:" in line), "Unknown")
top = os.environ["SYSTEM_SNAPSHOT"]
cpu_snapshot = next((line.strip() for line in top.splitlines() if line.startswith("CPU usage:")), "Unknown")
memory_snapshot = next((line.strip() for line in top.splitlines() if line.startswith("PhysMem:")), "Unknown")
swift = subprocess.run(["swift", "--version"], capture_output=True, text=True, check=True).stdout.splitlines()[0]

print(f"- Platform: {platform.platform()}")
print(f"- Hardware: {cpu}; {cores}; {memory}")
print(f"- Toolchain: {swift}")
print("- Markdown parser: markdown-it 15.0.2 with markdown-it-task-lists 2.1.1")
print(f"- System CPU snapshot at suite start: {cpu_snapshot}")
print(f"- System memory snapshot at suite start: {memory_snapshot}")
print(f"- Samples per fixture: {runs} (first load plus {runs - 1} warm loads)")
print("- Metrics: WebKit load-to-DOM wall time; JavaScript rendering stages exclude WebKit process startup.")
print("- Host CPU/RSS: `/usr/bin/time -l` for the benchmark host only; WebKit helper-process usage is excluded.")
print()
print("## Results")
print()
print("| Fixture | Markdown size | First-load wall | Warm wall median | Base64 median | Byte array median | UTF-8 median | Parser median | HTML generation median | DOM insertion median | Highlight median | TOC median | Layout median | JS total median | Host CPU | Host max RSS |")
print("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
for fixture in fixtures:
    data = json.load(open(f"{work}/{fixture}.json"))
    samples = data["samples"]
    warm = samples[1:]
    render = [sample["render"] for sample in samples]
    time_output = open(f"{work}/{fixture}.time").read().splitlines()
    timing = time_output[0].split()
    user_seconds = float(timing[2])
    system_seconds = float(timing[4])
    max_rss_bytes = int(next(line.split()[0] for line in time_output if "maximum resident set size" in line))
    print(
        f"| {fixture} | {data['bytes'] / 1024:.0f} KiB | "
        f"{samples[0]['wallMilliseconds']:.1f} ms | "
        f"{milliseconds([sample['wallMilliseconds'] for sample in warm])} ms | "
        f"{milliseconds([item['base64DecodeMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['byteArrayMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['utf8DecodeMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['parserMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['htmlGenerationMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['domInsertionMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['highlightingMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['outlineMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['layoutMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['totalMilliseconds'] for item in render])} ms | "
        f"{user_seconds + system_seconds:.2f} s | {max_rss_bytes / 1024 / 1024:.1f} MiB |"
    )
print()
print("## Raw samples")
print()
for fixture in fixtures:
    data = json.load(open(f"{work}/{fixture}.json"))
    print(f"- {fixture} wall: " + ", ".join(f"{sample['wallMilliseconds']:.1f}" for sample in data["samples"]) + " ms")
PY
