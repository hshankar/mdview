# mdview benchmark after launch optimizations

- Date: 2026-09-26T23:08:49-07:00
- Platform: macOS 15.7.4, arm64
- Runs per launch scenario: 5
- Memory settling time: 10 seconds
- Fixture: 192-byte local Markdown document

## Results

| Metric | Result |
| --- | ---: |
| Process-cold time to window, median | 161.9 ms |
| Process-cold time to window, mean | 154.3 ms |
| Warm-process time to new window, median | 22.5 ms |
| Warm-process time to new window, mean | 22.6 ms |
| Physical footprint after 10s | 80.0 MiB |
| Aggregate RSS after 10s | 138.0 MiB |
| Process count | 4 |
| Thread count | 27 |
| CPU snapshot after 10s | 0.0% |
| Installed payload | 0.378 MiB |
| Compressed payload | 0.119 MiB |

## Raw launch samples

- Process-cold: 177.1, 167.0, 161.9, 144.8, 120.6 ms
- Warm-process: 21.5, 18.8, 26.0, 22.5, 24.0 ms
