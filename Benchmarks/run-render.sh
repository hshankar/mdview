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

python3 - "$WORK_DIR" <<'PY'
import pathlib
import sys

output = pathlib.Path(sys.argv[1])
paragraph = (
    "mdview renders local Markdown with native macOS text selection, automatic reload, "
    "and a focused reading layout for technical documentation.\n\n"
)

def write_prose(name, target_bytes):
    parts = ["# Render benchmark\n\n"]
    size = len(parts[0].encode())
    section = 1
    while size < target_bytes:
        part = paragraph * 64
        if section % 8 == 0:
            part = f"## Section {section // 8}\n\n" + part
        parts.append(part)
        size += len(part.encode())
        section += 1
    (output / name).write_text("".join(parts))

def write_code_heavy(name, target_bytes):
    parts = []
    size = 0
    section = 1
    lines = "\n".join(
        f"let value{index} = Section(value: {index})" for index in range(100)
    )
    block = f"```swift\nstruct Section {{ let value: Int }}\n{lines}\n```\n\n"
    while size < target_bytes:
        part = f"## Code section {section}\n\n" + block
        parts.append(part)
        size += len(part.encode())
        section += 1
    (output / name).write_text("".join(parts))

write_prose("prose-10kb.md", 10 * 1024)
write_prose("prose-50kb.md", 50 * 1024)
write_prose("prose-100kb.md", 100 * 1024)
write_code_heavy("code-heavy-100kb.md", 100 * 1024)
PY

swiftc -O Benchmarks/render-benchmark.swift \
    -framework AppKit \
    -framework WebKit \
    -o "$HELPER"

for fixture in prose-10kb prose-50kb prose-100kb code-heavy-100kb; do
    "$HELPER" "$ROOT" "$WORK_DIR/$fixture.md" "$RUNS" > "$WORK_DIR/$fixture.json"
done

python3 - "$WORK_DIR" "$RUNS" <<'PY'
import datetime
import json
import platform
import statistics
import subprocess
import sys

work = sys.argv[1]
runs = int(sys.argv[2])
fixtures = ["prose-10kb", "prose-50kb", "prose-100kb", "code-heavy-100kb"]

def milliseconds(values):
    return f"{statistics.median(values):.1f}"

print("# mdview render benchmark")
print()
print(f"- Date: {datetime.datetime.now().astimezone().isoformat(timespec='seconds')}")
print(f"- Platform: {platform.platform()}")
print(f"- Samples per fixture: {runs} (first load plus {runs - 1} warm loads)")
print("- Metrics: WebKit load-to-DOM wall time; JavaScript rendering stages exclude WebKit process startup.")
print()
print("## Results")
print()
print("| Fixture | Markdown size | First-load wall | Warm wall median | Marked median | Highlight median | TOC median | JS total median |")
print("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
for fixture in fixtures:
    data = json.load(open(f"{work}/{fixture}.json"))
    samples = data["samples"]
    warm = samples[1:]
    render = [sample["render"] for sample in samples]
    print(
        f"| {fixture} | {data['bytes'] / 1024:.0f} KiB | "
        f"{samples[0]['wallMilliseconds']:.1f} ms | "
        f"{milliseconds([sample['wallMilliseconds'] for sample in warm])} ms | "
        f"{milliseconds([item['markdownMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['highlightingMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['outlineMilliseconds'] for item in render])} ms | "
        f"{milliseconds([item['totalMilliseconds'] for item in render])} ms |"
    )
print()
print("## Raw samples")
print()
for fixture in fixtures:
    data = json.load(open(f"{work}/{fixture}.json"))
    print(f"- {fixture} wall: " + ", ".join(f"{sample['wallMilliseconds']:.1f}" for sample in data["samples"]) + " ms")
PY
