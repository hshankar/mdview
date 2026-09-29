# mdview render benchmark

- Date: 2026-09-28T22:21:54-07:00
- Platform: macOS-15.7.4-arm64-arm-64bit
- Hardware: Chip: Apple M3 Pro; Total Number of Cores: 12 (6 performance and 6 efficiency); Memory: 18 GB
- Toolchain: Apple Swift version 6.2.4 (swiftlang-6.2.4.1.4 clang-1700.6.4.2)
- System CPU snapshot at suite start: CPU usage: 4.79% user, 9.25% sys, 85.94% idle
- System memory snapshot at suite start: PhysMem: 17G used (4176M wired, 6361M compressor), 125M unused.
- Samples per fixture: 6 (first load plus 5 warm loads)
- Metrics: WebKit load-to-DOM wall time; JavaScript rendering stages exclude WebKit process startup.
- Host CPU/RSS: `/usr/bin/time -l` for the benchmark host only; WebKit helper-process usage is excluded.

## Results

| Fixture | Markdown size | First-load wall | Warm wall median | Parse median | DOM insertion median | Highlight median | TOC median | Layout median | JS total median | Host CPU | Host max RSS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| prose-10kb | 18 KiB | 152.9 ms | 32.4 ms | 26.0 ms | 0.0 ms | 0.0 ms | 0.0 ms | 1.0 ms | 27.5 ms | 0.11 s | 69.3 MiB |
| prose-50kb | 53 KiB | 337.0 ms | 213.2 ms | 204.5 ms | 0.0 ms | 0.0 ms | 0.0 ms | 3.0 ms | 207.0 ms | 0.11 s | 68.7 MiB |
| prose-100kb | 106 KiB | 941.4 ms | 813.7 ms | 801.5 ms | 0.5 ms | 0.0 ms | 0.0 ms | 5.0 ms | 807.5 ms | 0.11 s | 71.3 MiB |
| code-heavy-100kb | 101 KiB | 308.5 ms | 145.8 ms | 3.0 ms | 1.0 ms | 101.5 ms | 0.5 ms | 29.5 ms | 135.0 ms | 0.16 s | 70.8 MiB |

## Raw samples

- prose-10kb wall: 152.9, 33.3, 31.7, 32.2, 32.4, 33.0 ms
- prose-50kb wall: 337.0, 216.8, 212.8, 211.7, 213.2, 213.9 ms
- prose-100kb wall: 941.4, 816.3, 809.8, 826.3, 813.7, 807.5 ms
- code-heavy-100kb wall: 308.5, 147.2, 147.4, 145.8, 142.5, 142.2 ms
