# mdview render benchmark

- Date: 2026-09-28T22:52:38-07:00
- Platform: macOS-15.7.4-arm64-arm-64bit
- Hardware: Chip: Apple M3 Pro; Total Number of Cores: 12 (6 performance and 6 efficiency); Memory: 18 GB
- Toolchain: Apple Swift version 6.2.4 (swiftlang-6.2.4.1.4 clang-1700.6.4.2)
- Markdown parser: markdown-it 15.0.2 with markdown-it-task-lists 2.1.1
- System CPU snapshot at suite start: CPU usage: 8.87% user, 10.64% sys, 80.48% idle
- System memory snapshot at suite start: PhysMem: 17G used (4557M wired, 7274M compressor), 139M unused.
- Samples per fixture: 6 (first load plus 5 warm loads)
- Metrics: WebKit load-to-DOM wall time; JavaScript rendering stages exclude WebKit process startup.
- Host CPU/RSS: `/usr/bin/time -l` for the benchmark host only; WebKit helper-process usage is excluded.

## Results

| Fixture | Markdown size | First-load wall | Warm wall median | Base64 median | Byte array median | UTF-8 median | Parser median | HTML generation median | DOM insertion median | Highlight median | TOC median | Layout median | JS total median | Host CPU | Host max RSS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| prose-10kb | 18 KiB | 147.5 ms | 9.5 ms | 0.0 ms | 0.0 ms | 0.0 ms | 2.0 ms | 0.0 ms | 0.0 ms | 0.0 ms | 0.0 ms | 1.0 ms | 3.5 ms | 0.12 s | 71.2 MiB |
| prose-50kb | 53 KiB | 144.5 ms | 13.9 ms | 0.0 ms | 1.0 ms | 0.0 ms | 3.0 ms | 0.0 ms | 0.0 ms | 0.0 ms | 0.0 ms | 3.0 ms | 8.0 ms | 0.11 s | 71.3 MiB |
| prose-100kb | 106 KiB | 154.5 ms | 20.7 ms | 0.0 ms | 2.0 ms | 0.0 ms | 5.0 ms | 0.0 ms | 0.5 ms | 0.0 ms | 0.0 ms | 5.0 ms | 13.0 ms | 0.11 s | 72.2 MiB |
| code-heavy-100kb | 101 KiB | 300.0 ms | 154.1 ms | 0.0 ms | 2.0 ms | 0.0 ms | 2.0 ms | 0.0 ms | 0.5 ms | 106.0 ms | 1.0 ms | 31.5 ms | 143.0 ms | 0.16 s | 75.2 MiB |

## Raw samples

- prose-10kb wall: 147.5, 9.5, 9.7, 14.8, 9.2, 9.5 ms
- prose-50kb wall: 144.5, 13.8, 14.6, 13.9, 13.8, 15.8 ms
- prose-100kb wall: 154.5, 20.7, 20.1, 22.1, 21.9, 20.2 ms
- code-heavy-100kb wall: 300.0, 153.3, 156.6, 159.5, 154.1, 152.9 ms
