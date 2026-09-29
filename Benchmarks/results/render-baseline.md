# mdview render benchmark

- Date: 2026-09-28T21:12:29-07:00
- Platform: macOS-15.7.4-arm64-arm-64bit
- Hardware: Chip: Apple M3 Pro; Total Number of Cores: 12 (6 performance and 6 efficiency); Memory: 18 GB
- Toolchain: Apple Swift version 6.2.4 (swiftlang-6.2.4.1.4 clang-1700.6.4.2)
- System CPU snapshot before report: CPU usage: 6.80% user, 9.68% sys, 83.51% idle
- System memory snapshot before report: PhysMem: 17G used (4058M wired, 7136M compressor), 400M unused.
- Samples per fixture: 6 (first load plus 5 warm loads)
- Metrics: WebKit load-to-DOM wall time; JavaScript rendering stages exclude WebKit process startup.
- Host CPU/RSS: `/usr/bin/time -l` for the benchmark host only; WebKit helper-process usage is excluded.

## Results

| Fixture | Markdown size | First-load wall | Warm wall median | Marked median | Highlight median | TOC median | JS total median | Host CPU | Host max RSS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| prose-10kb | 18 KiB | 157.2 ms | 34.2 ms | 27.0 ms | 0.0 ms | 0.0 ms | 27.5 ms | 0.11 s | 69.4 MiB |
| prose-50kb | 53 KiB | 337.5 ms | 216.2 ms | 207.5 ms | 0.0 ms | 0.0 ms | 207.5 ms | 0.11 s | 69.2 MiB |
| prose-100kb | 106 KiB | 955.8 ms | 824.5 ms | 812.0 ms | 0.0 ms | 0.0 ms | 812.0 ms | 0.11 s | 70.5 MiB |
| code-heavy-100kb | 101 KiB | 280.9 ms | 146.2 ms | 3.5 ms | 102.5 ms | 1.0 ms | 106.0 ms | 0.13 s | 73.4 MiB |

## Raw samples

- prose-10kb wall: 157.2, 34.5, 34.2, 33.2, 32.3, 34.6 ms
- prose-50kb wall: 337.5, 216.2, 216.9, 216.2, 215.8, 216.6 ms
- prose-100kb wall: 955.8, 824.5, 825.9, 824.1, 823.1, 827.8 ms
- code-heavy-100kb wall: 280.9, 150.4, 145.8, 146.9, 145.2, 146.2 ms
