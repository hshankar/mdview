# mdview render benchmark

- Date: 2026-09-28T22:43:51-07:00
- Platform: macOS-15.7.4-arm64-arm-64bit
- Hardware: Chip: Apple M3 Pro; Total Number of Cores: 12 (6 performance and 6 efficiency); Memory: 18 GB
- Toolchain: Apple Swift version 6.2.4 (swiftlang-6.2.4.1.4 clang-1700.6.4.2)
- System CPU snapshot at suite start: CPU usage: 5.11% user, 9.24% sys, 85.64% idle
- System memory snapshot at suite start: PhysMem: 17G used (4171M wired, 6922M compressor), 286M unused.
- Samples per fixture: 6 (first load plus 5 warm loads)
- Metrics: WebKit load-to-DOM wall time; JavaScript rendering stages exclude WebKit process startup.
- Host CPU/RSS: `/usr/bin/time -l` for the benchmark host only; WebKit helper-process usage is excluded.

## Results

| Fixture | Markdown size | First-load wall | Warm wall median | Base64 median | Byte array median | UTF-8 median | Lexer median | HTML generation median | DOM insertion median | Highlight median | TOC median | Layout median | JS total median | Host CPU | Host max RSS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| prose-10kb | 18 KiB | 181.6 ms | 32.9 ms | 0.0 ms | 0.5 ms | 0.0 ms | 26.0 ms | 0.0 ms | 0.0 ms | 0.0 ms | 0.0 ms | 2.0 ms | 29.5 ms | 0.11 s | 69.8 MiB |
| prose-50kb | 53 KiB | 338.7 ms | 217.4 ms | 0.0 ms | 1.0 ms | 0.0 ms | 207.0 ms | 0.0 ms | 0.0 ms | 0.0 ms | 0.0 ms | 3.0 ms | 212.0 ms | 0.11 s | 70.3 MiB |
| prose-100kb | 106 KiB | 949.4 ms | 814.2 ms | 0.5 ms | 2.0 ms | 0.0 ms | 801.0 ms | 0.5 ms | 0.0 ms | 0.0 ms | 0.0 ms | 5.0 ms | 809.0 ms | 0.11 s | 71.3 MiB |
| code-heavy-100kb | 101 KiB | 268.1 ms | 144.7 ms | 0.0 ms | 2.0 ms | 0.0 ms | 0.0 ms | 0.5 ms | 0.5 ms | 100.0 ms | 0.0 ms | 29.0 ms | 133.5 ms | 0.13 s | 74.4 MiB |

## Raw samples

- prose-10kb wall: 181.6, 51.7, 36.6, 31.4, 31.9, 32.9 ms
- prose-50kb wall: 338.7, 221.9, 218.3, 217.4, 212.4, 214.1 ms
- prose-100kb wall: 949.4, 808.4, 814.2, 818.3, 820.8, 812.2 ms
- code-heavy-100kb wall: 268.1, 145.0, 142.1, 144.7, 144.3, 145.9 ms
