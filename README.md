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
- Collapsible table of contents from the sidebar button in the title bar
- Standard Window menu and Dock list for open documents
- Relative local images
- Automatic reload after atomic or in-place file saves
- Scroll-position preservation during reload
- External links open in the default browser
- Raw HTML is shown as text instead of executed
- Bundled rendering assets; no CDN or network connection is needed for local files
- Immediate native window while WebKit initializes in the background
- A warm viewer process makes subsequent invocations open new windows quickly
- Custom Dock and minimized-window icon

## Requirements

- macOS 13 or newer
- An Intel or Apple silicon Mac

Release archives are universal and do not require Swift, Xcode, Homebrew, or another language runtime on the destination Mac.

## Install a release

Download the installer, review it if desired, then run it:

```sh
curl -fsSLO https://raw.githubusercontent.com/hshankar/mdview/main/install.sh
sh install.sh
```

The installer downloads the latest release, verifies its SHA-256 checksum, and installs into `/usr/local/bin` when writable. Otherwise it uses `~/.local/bin` and prints the required `PATH` entry.

To install a specific version, download the installer from that tag and set `MDVIEW_VERSION`:

```sh
curl -fsSLO https://raw.githubusercontent.com/hshankar/mdview/v0.1.6/install.sh
MDVIEW_VERSION=0.1.6 MDVIEW_INSTALL_DIR="$HOME/.local/bin" sh install.sh
```

The command hands the file to a detached viewer process and returns immediately. Later invocations reuse that process and open another window. After the last viewer window closes, the process remains warm for five minutes and then exits automatically. `Command-Q` exits it immediately.

> Releases are currently ad-hoc signed, not Developer ID signed or notarized. Gatekeeper may require an explicit approval before macOS opens `mdview` for the first time.

## Update

Update an existing installation with:

```sh
mdview update
```

It stops any warm viewer process, downloads the latest release, verifies its SHA-256 checksum, and replaces `mdview`, `mdview-update`, and the adjacent resource bundle in the same installation directory.

## Uninstall

For a default user-local installation:

```sh
make uninstall PREFIX="$HOME/.local"
```

For another installation directory, remove `mdview`, `mdview-update`, and `mdview_MDView.bundle` from that directory.

## Build from source

Building requires Swift 5.10 or newer:

```sh
swift build -c release
.build/release/mdview README.md
```

Run tests and install the native-architecture build with:

```sh
swift test
make install PREFIX="$HOME/.local"
```

Build a distributable Intel and Apple silicon archive with:

```sh
scripts/package-release.sh 0.1.6 dist
```

The installed `mdview` executable and adjacent `mdview_MDView.bundle` resource directory are both required. Remove a source installation with:

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
| `Command-G` | Find next |
| `Shift-Command-G` | Find previous |
| `Command-C` | Copy selected text |
| `Command-W` | Close window |
| `Command-\`` | Show next window |
| `Shift-Command-\`` | Show previous window |
| `Command-Q` | Quit |

## Security model

Documents are treated as untrusted input:

- Markdown source is transferred to the rendering page as Base64 rather than interpolated markup.
- Raw HTML is escaped.
- A restrictive Content Security Policy blocks forms, objects, frames, and network connections.
- User-activated HTTP and HTTPS links are handed to the default browser.
- Other top-level navigation is denied.

Remote images and media are blocked. Local rendering libraries, styles, and relative document resources are always loaded from bundled or local files.

## Architecture

The native application shell is written in Swift using AppKit and `WKWebView`. A per-user Core Foundation message port forwards files from short-lived CLI invocations to the warm viewer process; it does not use a TCP port or HTTP server. Markdown is rendered offline with bundled copies of [Marked](https://github.com/markedjs/marked) and [highlight.js](https://github.com/highlightjs/highlight.js). See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for licenses.

Product scope and acceptance criteria are recorded in [`REQUIREMENTS.md`](REQUIREMENTS.md).

## License

[MIT](LICENSE)
