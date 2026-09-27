# Performance benchmark

This directory contains the repeatable benchmark used to track `mdview` launch speed, memory use, CPU use, and distribution size.

## Run

```sh
Benchmarks/run.sh > result.md
```

Optional environment variables:

- `MDVIEW_BIN`: release executable to test; defaults to `.build/release/mdview`
- `RUNS`: launch samples per scenario; defaults to `5`
- `SETTLE_SECONDS`: delay before memory measurement; defaults to `10`

## Definitions

- **Process-cold time to window:** all `mdview` processes are terminated before each invocation. OS filesystem and framework caches are not purged.
- **Warm-process time to new window:** one instance remains running, then each invocation is timed until an additional visible window appears.
- **Physical footprint:** `footprint` summary for the application and newly created WebKit helper processes.
- **Aggregate RSS:** sum reported by `ps`; shared pages may be counted more than once.

Window timing uses `CGWindowListCopyWindowInfo` and stops when a new layer-zero window owned by `mdview` appears. It measures visible-window latency, not completion of document rendering.

Keep `run.sh`, `window-benchmark.swift`, and `fixture.md` unchanged when comparing results. Changes to methodology require a new benchmark version and a new baseline.
