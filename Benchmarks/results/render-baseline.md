# mdview render benchmark

- Date: 2026-09-28T21:03:49-07:00
- Platform: macOS-15.7.4-arm64-arm-64bit
- Samples per fixture: 6 (first load plus 5 warm loads)
- Metrics: WebKit load-to-DOM wall time; JavaScript rendering stages exclude WebKit process startup.

## Results

| Fixture | Markdown size | First-load wall | Warm wall median | Marked median | Highlight median | TOC median | JS total median |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| prose-10kb | 18 KiB | 181.7 ms | 32.6 ms | 26.0 ms | 0.0 ms | 0.0 ms | 26.0 ms |
| prose-50kb | 53 KiB | 347.7 ms | 215.5 ms | 207.5 ms | 0.0 ms | 0.0 ms | 207.5 ms |
| prose-100kb | 106 KiB | 953.1 ms | 806.6 ms | 798.0 ms | 0.0 ms | 0.0 ms | 798.0 ms |
| code-heavy-100kb | 101 KiB | 265.9 ms | 145.0 ms | 4.0 ms | 102.0 ms | 0.0 ms | 105.5 ms |

## Raw samples

- prose-10kb wall: 181.7, 51.6, 32.7, 31.7, 32.6, 31.8 ms
- prose-50kb wall: 347.7, 212.0, 215.5, 217.6, 216.8, 209.5 ms
- prose-100kb wall: 953.1, 806.6, 815.3, 795.3, 818.7, 798.7 ms
- code-heavy-100kb wall: 265.9, 151.3, 145.0, 140.0, 143.1, 145.9 ms
