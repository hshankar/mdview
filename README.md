# mdview

A small, read-only Markdown viewer for macOS.

```sh
mdview README.md
```

`mdview` uses the system WebKit framework, so it can provide high-quality typography and native interaction without bundling Chromium or running a local server.

## Current features

- GitHub-flavored Markdown, including tables, task lists, and strikethrough
- Syntax highlighting for fenced code blocks
- Responsive light and dark themes that follow macOS
- Whole-page zoom with `Command-=`, `Command--`, and `Command-0`
- Relative local images
- Automatic reload after atomic or in-place file saves
- Scroll-position preservation during reload
- External links open in the default browser
- Raw HTML is shown as text instead of executed
- Bundled rendering assets; no CDN or network connection is needed for local files
- Immediate native window while WebKit initializes in the background
- A warm viewer process makes subsequent invocations open new windows quickly

## Requirements

- macOS 13 or newer
- Swift 5.10 or newer to build

The current release target is Apple silicon. Swift can also build the package for Intel macOS on an Intel machine or with an appropriate universal-build workflow.

## Build and run

```sh
swift build -c release
.build/release/mdview README.md
```

Run the test suite with:

```sh
swift test
```

## Install

The default installation prefix is `/usr/local`:

```sh
make install
```

A user-local installation can be made without `sudo`:

```sh
make install PREFIX="$HOME/.local"
```

Ensure the selected `bin` directory is on `PATH`, then run:

```sh
mdview /path/to/document.md
```

The command hands the file to a detached viewer process and returns immediately. Later invocations reuse that process and open another window. After the last viewer window closes, the process remains warm for five minutes and then exits automatically. `Command-Q` exits it immediately.

The installation includes the `mdview_MDView.bundle` resource directory next to the executable. Both are required. Remove them with the same prefix using:

```sh
make uninstall PREFIX="$HOME/.local"
```

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `Command-=` | Zoom in |
| `Command--` | Zoom out |
| `Command-0` | Reset zoom |
| `Command-R` | Reload from disk |
| `Command-F` | Find in document |
| `Command-C` | Copy selected text |
| `Command-W` | Close window |
| `Command-Q` | Quit |

## Security model

Documents are treated as untrusted input:

- Markdown source is transferred to the rendering page as Base64 rather than interpolated markup.
- Raw HTML is escaped.
- A restrictive Content Security Policy blocks forms, objects, frames, and network connections.
- User-activated HTTP and HTTPS links are handed to the default browser.
- Other top-level navigation is denied.

Remote images explicitly referenced by a document may still be fetched by WebKit. Local rendering libraries and styles are always loaded from the bundled resources.

## Architecture

The native application shell is written in Swift using AppKit and `WKWebView`. A per-user Core Foundation message port forwards files from short-lived CLI invocations to the warm viewer process; it does not use a TCP port or HTTP server. Markdown is rendered offline with bundled copies of [Marked](https://github.com/markedjs/marked) and [highlight.js](https://github.com/highlightjs/highlight.js). See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for licenses.

Product scope and acceptance criteria are recorded in [`REQUIREMENTS.md`](REQUIREMENTS.md).
