# mdview render benchmark

- Date: 2026-09-28T21:12:57-07:00
- Platform: macOS-15.7.4-arm64-arm-64bit
- Hardware: Chip: Apple M3 Pro; Total Number of Cores: 12 (6 performance and 6 efficiency); Memory: 18 GB
- Toolchain: Apple Swift version 6.2.4 (swiftlang-6.2.4.1.4 clang-1700.6.4.2)
- System CPU snapshot at suite start: CPU usage: 11.69% user, 10.7% sys, 78.22% idle
- System memory snapshot at suite start: PhysMem: 17G used (4061M wired, 6901M compressor), 117M unused.
- Samples per fixture: 6 (first load plus 5 warm loads)
- Metrics: WebKit load-to-DOM wall time; JavaScript rendering stages exclude WebKit process startup.
- Host CPU/RSS: `/usr/bin/time -l` for the benchmark host only; WebKit helper-process usage is excluded.

## Results

| Fixture | Markdown size | First-load wall | Warm wall median | Marked median | Highlight median | TOC median | JS total median | Host CPU | Host max RSS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| prose-10kb | 18 KiB | 157.7 ms | 32.3 ms | 26.0 ms | 0.0 ms | 0.0 ms | 26.0 ms | 0.11 s | 68.7 MiB |
| prose-50kb | 53 KiB | 347.8 ms | 216.0 ms | 208.0 ms | 0.0 ms | 0.0 ms | 208.0 ms | 0.11 s | 69.1 MiB |
| prose-100kb | 106 KiB | 952.9 ms | 819.0 ms | 806.5 ms | 0.0 ms | 0.0 ms | 807.0 ms | 0.11 s | 71.1 MiB |
| code-heavy-100kb | 101 KiB | 275.7 ms | 145.3 ms | 4.0 ms | 102.0 ms | 0.5 ms | 105.5 ms | 0.13 s | 72.7 MiB |

## Raw samples

- prose-10kb wall: 157.7, 33.5, 32.3, 32.3, 32.5, 32.0 ms
- prose-50kb wall: 347.8, 218.0, 215.9, 215.6, 216.0, 216.9 ms
- prose-100kb wall: 952.9, 828.3, 819.0, 814.0, 822.4, 814.6 ms
- code-heavy-100kb wall: 275.7, 150.0, 144.8, 146.9, 145.0, 145.3 ms
