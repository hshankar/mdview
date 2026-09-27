# mdview benchmark baseline

- Date: 2026-09-26T22:57:35-07:00
- Platform: macOS 15.7.4, arm64
- Runs per launch scenario: 5
- Memory settling time: 10 seconds
- Fixture: 192-byte local Markdown document

## Results

| Metric | Result |
| --- | ---: |
| Process-cold time to window, median | 229.7 ms |
| Process-cold time to window, mean | 275.3 ms |
| Warm-process time to new window, median | 211.2 ms |
| Warm-process time to new window, mean | 198.8 ms |
| Physical footprint after 10s | 79.0 MiB |
| Aggregate RSS after 10s | 139.5 MiB |
| Process count | 4 |
| Thread count | 33 |
| CPU snapshot after 10s | 0.2% |
| Installed payload | 0.346 MiB |
| Compressed payload | 0.105 MiB |

## Raw launch samples

- Process-cold: 511.0, 209.5, 231.9, 194.2, 229.7 ms
- Warm-process: 211.7, 211.2, 217.7, 195.2, 158.2 ms
