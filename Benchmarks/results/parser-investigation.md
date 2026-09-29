# Markdown parser investigation

- Date: 2026-09-28
- Platform: macOS 15.7.4, Apple M3 Pro (12 cores), 18 GB memory
- Runtime under test: `WKWebView` / JavaScriptCore
- Fixture: committed files under `Benchmarks/Fixtures`

## Corrected diagnosis

The original aggregate timer started before source decoding and was labeled as Markdown parsing. Splitting the pipeline further showed that Base64 decoding, byte-array creation, and UTF-8 decoding together account for approximately 2 ms for the 106 KiB prose fixture. Marked's block lexer accounts for approximately 801 ms of the 809 ms JavaScript render time.

For the 106 KiB prose fixture, the six-sample baseline reports:

| Stage | Median |
| --- | ---: |
| Base64 decode | 0.5 ms |
| Byte-array creation | 2.0 ms |
| UTF-8 decode | 0.0 ms |
| Marked lexer | 801.0 ms |
| HTML generation | 0.5 ms |
| DOM insertion | 0.0 ms |
| Layout | 5.0 ms |
| JavaScript total | 809.0 ms |

The same Marked bundle parses this fixture in approximately 2 ms after warm-up under Node/V8. Node results therefore do not predict performance in `WKWebView`.

## Block-count scaling

Exploratory `WKWebView` measurements held source size at approximately 100 KiB while changing the number of blank-line-separated prose blocks:

| Paragraph blocks | Marked lexer |
| ---: | ---: |
| 1 | 24 ms |
| 10 | 27 ms |
| 100 | 112 ms |
| 500 | 502 ms |
| 1,000 | 986 ms |

The cost follows block count much more strongly than byte count. Marked repeatedly consumes source prefixes using `substring`; the results are consistent with an unfavorable interaction between that lexer design and JavaScriptCore's string/regular-expression behavior. This is a behavioral diagnosis rather than a JavaScriptCore implementation profile.

Disabling GFM reduced the 106 KiB prose lexer from roughly 801 ms to 601 ms, but remained far above the 200 ms target and removed required features.

## Marked versions and warm-up

One-sample `WKWebView` measurements of the 106 KiB prose fixture using default rendering:

| Marked version | Lexer |
| --- | ---: |
| 9.1.6 | 803 ms |
| 12.0.2 | 798 ms |
| 15.0.12 | 797 ms |
| 17.0.1 | 807 ms |
| 18.0.14 | approximately 801 ms |

Four consecutive lexes in the same page measured 784 ms for the first run and 804 ms for the median of the next three. Keeping the JavaScript context alive and allowing JIT warm-up does not resolve the issue.

## Alternative parser comparison

The browser bundles were substituted temporarily into the same offscreen `WKWebView` harness. Three samples were collected per fixture. The alternative-parser timer includes parsing and HTML generation.

| Parser | Fixture | First wall | Warm wall | Parser | JS total |
| --- | --- | ---: | ---: | ---: | ---: |
| Marked 18.0.14 | prose-100kb | 949 ms | 814 ms | 801 ms lexer | 809 ms |
| markdown-it 15.0.2 | prose-100kb | 153 ms | 20 ms | 4 ms | 13 ms |
| commonmark.js 0.31.2 | prose-100kb | 151 ms | 19 ms | 2 ms | 9 ms |
| markdown-it 15.0.2 | code-heavy-100kb | 278 ms | 147 ms | 2 ms | 139 ms |
| commonmark.js 0.31.2 | code-heavy-100kb | 271 ms | 147 ms | 2 ms | 136 ms |

Code-heavy completion remains dominated by highlight.js (approximately 102 ms) and layout (approximately 30 ms), not the Markdown parser.

## Options

### 1. Replace Marked with markdown-it (recommended)

Advantages:

- Reduces the measured 106 KiB prose parser stage from approximately 801 ms to 4 ms.
- Meets the 200 ms complete-render target for the current 100 KiB fixtures in the benchmark harness.
- Supports CommonMark, tables, and strikethrough.
- Can disable raw HTML and rejects unsafe `javascript:` link destinations.
- MIT licensed and available as a self-contained browser bundle.

Required compatibility work:

- Enable linkification to retain GFM-style bare URL links.
- Add task-list handling; markdown-it core leaves `[ ]` and `[x]` markers as text.
- Assign stable heading IDs after DOM insertion or through a renderer rule so the table of contents and fragment links continue to work.
- Add parser-level fixtures/tests for tables, task lists, strikethrough, links, images, fenced code, raw HTML, unsafe URLs, and duplicate headings.
- Update bundled-resource attribution and notices.

The minified browser bundle is approximately 115 KiB versus approximately 47 KiB for Marked. The roughly 68 KiB increase is insignificant relative to the existing application resources and measured speedup.

### 2. Use commonmark.js

It is slightly faster in the exploratory benchmark, but does not provide the required GFM tables, task lists, or strikethrough without additional extensions. Its browser bundle is also larger than markdown-it. It is not the best fit for the documented feature set.

### 3. Use native cmark-gfm

A native C parser should be fast and provides authoritative GFM behavior. It would avoid JavaScript parser-runtime variability, but adds a native dependency, Swift/C integration, source-distribution and Homebrew build complexity, and a new HTML handoff path. This is a reasonable future option if markdown-it proves insufficient, but disproportionate for the current bottleneck.

### 4. Patch or fork Marked

A cursor-based lexer could avoid repeatedly consuming source prefixes while preserving Marked behavior. This would require maintaining a parser fork and tracking upstream grammar/security fixes. All tested Marked versions exhibit the problem, so version selection alone does not help.

### 5. Split Markdown and invoke Marked per chunk

This is fast for the synthetic prose case but unsafe as a general parser optimization. Blank lines and headings do not reliably delimit independent Markdown because lists, blockquotes, reference definitions, fenced blocks, and HTML blocks can span apparent boundaries. A correct splitter approaches the complexity of a Markdown parser.

### 6. Move Marked to a worker or progressively render it

A worker could keep the UI responsive, and progressive rendering could improve first-visible-content latency, but neither reduces the approximately 801 ms lexer cost or meets the 200 ms complete-render target. These are secondary techniques, not a fix for this bottleneck.

## Recommended implementation order

1. Replace Marked with markdown-it while preserving all required syntax and security behavior through regression tests.
2. Re-run the committed benchmark and save an after-result.
3. Lazily highlight off-screen code blocks to improve the separate code-heavy bottleneck.
4. Load the rendering shell once and update only Markdown on reload to reduce warm-reload navigation overhead.

## Implementation result

markdown-it 15.0.2 with markdown-it-task-lists 2.1.1 was integrated and measured with six samples per fixture. The complete report is in [`render-after-markdown-it.md`](render-after-markdown-it.md).

| 106 KiB prose metric | Marked baseline | markdown-it | Improvement |
| --- | ---: | ---: | ---: |
| First-load wall | 949.4 ms | 154.5 ms | 83.7% |
| Warm wall median | 814.2 ms | 20.7 ms | 97.5% |
| Parser stage | 801.0 ms | 5.0 ms | 99.4% |
| JavaScript total | 809.0 ms | 13.0 ms | 98.4% |

The 101 KiB code-heavy JavaScript total remained in the same range (133.5 ms before and 143.0 ms after). Its parser stage is only 2.0 ms; syntax highlighting and layout account for nearly all remaining work.
