# mdview — native Markdown viewer for macOS

A fast, read-only Markdown viewer for local files on macOS. Launch it from the command line for live reload, native document search, and a collapsible outline—without Electron or a browser server.

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
- A Finder-compatible `MDView.app` created automatically during installation

## Requirements and compatibility

- macOS 13 or newer
- An Intel or Apple silicon Mac

The prebuilt release is universal, targets macOS 13, and does not require Swift or Xcode. The same download runs on both supported Mac architectures; users do not need to select a build based on their system.

Building from source requires Swift 5.10 or newer. CI tests the minimum Swift 5.10 toolchain as well as the current toolchain.

## Install with Homebrew

```sh
brew tap hshankar/tap
brew install hshankar/tap/mdview
```

If Homebrew asks you to trust the third-party tap, run `brew trust hshankar/tap` and repeat the install. Homebrew installs the prebuilt universal release, so this route does not require a Swift toolchain. The formula prints the stable path to its generated `MDView.app`; open it once to register the app with macOS.

## Install a prebuilt release

Download, verify, and install the latest universal release with:

```sh
curl -fsSL https://raw.githubusercontent.com/hshankar/mdview/main/install.sh | sh
```

The installer verifies the published SHA-256 checksum and code signature, installs the CLI under `/usr/local/bin` when writable or `$HOME/.local/bin` otherwise, and creates `$HOME/Applications/MDView.app`.

To install a specific release or choose custom locations:

```sh
curl -fsSL https://raw.githubusercontent.com/hshankar/mdview/v0.1.12/install.sh | \
  MDVIEW_VERSION=0.1.12 \
  MDVIEW_INSTALL_DIR="$HOME/.local/bin" \
  MDVIEW_APP_DIR="$HOME/Applications" \
  sh
```

Release binaries are currently ad-hoc signed rather than Developer ID signed and notarized.

## Build from source

Building requires Swift 5.10 or newer:

```sh
git clone https://github.com/hshankar/mdview.git
cd mdview
swift build -c release
.build/release/mdview README.md
```

Run tests and install the native-architecture build with:

```sh
swift test
make install PREFIX="$HOME/.local"
```

This installs the CLI and its resources under `$HOME/.local/bin` and creates `$HOME/Applications/MDView.app` for opening Markdown files from Finder. The app delegates to the installed CLI, so both are removed together with:

```sh
make uninstall PREFIX="$HOME/.local"
```

Set `APPDIR` to use a different application directory:

```sh
make install PREFIX="$HOME/.local" APPDIR="/Applications"
```

You can also create a development app at `.build/MDView.app` without installing:

```sh
make app
```

The command hands the file to a detached viewer process and returns immediately. Later invocations reuse that process and open another window. After the last viewer window closes, the process remains warm for five minutes and then exits automatically. `Command-Q` exits it immediately.

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

The native application shell is written in Swift using AppKit and `WKWebView`. A per-user Core Foundation message port forwards files from short-lived CLI invocations to the warm viewer process; it does not use a TCP port or HTTP server. Markdown is rendered offline with bundled copies of [markdown-it](https://github.com/markdown-it/markdown-it), [markdown-it-task-lists](https://github.com/revin/markdown-it-task-lists), and [highlight.js](https://github.com/highlightjs/highlight.js). See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for licenses.

Product scope and acceptance criteria are recorded in [`REQUIREMENTS.md`](REQUIREMENTS.md).

## Security

Report vulnerabilities through the process in [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE)
