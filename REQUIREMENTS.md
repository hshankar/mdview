# mdview Requirements

## 1. Product summary

`mdview` is a minimal, read-only Markdown viewer for macOS. It opens a Markdown file from the command line and renders it in a polished native window.

```sh
mdview <file>
```

The product should prioritize fast startup, low resource usage, excellent typography, and a distraction-free interface. It is a viewer, not a Markdown editor.

## 2. Goals

- Open a local Markdown file with one short command.
- Render Markdown beautifully in both light and dark mode.
- Highlight fenced code blocks.
- Support convenient, high-quality zooming.
- Resolve local images and other relative document resources correctly.
- Remain substantially lighter than Electron-based applications.
- Feel native on macOS.

## 3. Non-goals

The initial version will not provide:

- Markdown editing or live authoring controls
- Tabs, workspaces, notebooks, or document management
- Cloud synchronization
- Plugin support
- A complete general-purpose web browser
- Full support for arbitrary HTML, CSS, or JavaScript embedded in Markdown
- Cross-platform support

## 4. Target platform

- macOS is the initial and only required platform.
- Apple silicon must be supported.
- Intel support is desirable if it does not significantly complicate distribution.
- The viewer should use system frameworks where practical rather than bundling a browser runtime.

## 5. Command-line interface

### 5.1 Required invocation

```sh
mdview <file>
```

`<file>` may be relative or absolute. Paths containing spaces must work correctly.

### 5.2 Required behavior

- Resolve the supplied path to a canonical local file path.
- Open one viewer window containing the rendered document for each invocation.
- Use the filename as the window title.
- Return a clear error for a missing, unreadable, or unsupported file.
- Do not start a local HTTP server.
- Return the CLI process after handing the file to a detached viewer process.
- Reuse a warm viewer process for subsequent invocations.
- Exit the warm process after the final window has been closed and a bounded idle timeout has elapsed.

### 5.3 Possible future options

These are not required for the MVP:

```sh
mdview --theme light|dark|system <file>
mdview --allow-html <file>
mdview --no-watch <file>
mdview --version
mdview --help
```

## 6. Markdown rendering

### 6.1 Required Markdown support

The viewer must support CommonMark and these common GitHub-flavored extensions:

- Headings
- Paragraphs and line breaks
- Emphasis and strong emphasis
- Ordered and unordered lists
- Task lists
- Links
- Images
- Blockquotes
- Inline code
- Fenced code blocks
- Tables
- Strikethrough
- Horizontal rules

### 6.2 Relative resources

Relative resources must resolve from the directory containing the Markdown file.

For example, when opening `/project/docs/README.md`, this image must resolve to `/project/docs/images/demo.png`:

```md
![Demo](images/demo.png)
```

Local raster images should be supported. SVG support is desirable.

### 6.3 Raw HTML

- Raw HTML must be disabled, escaped, sanitized, or restricted by default.
- Markdown content must not be able to execute arbitrary JavaScript.
- A future explicit `--allow-html` option may enable a documented subset of HTML.

## 7. Visual design

- Use polished typography suitable for long-form reading.
- Use a comfortable maximum content width with responsive margins.
- Render headings, lists, quotes, tables, links, code, and task lists distinctly.
- Scale large images down to the available content width while preserving aspect ratio.
- Provide coordinated light and dark color schemes.
- Follow the macOS appearance by default and update when the system appearance changes.
- Keep the reading surface distraction-free; expose the table of contents only through an on-demand title-bar control.
- Provide a distinctive, high-resolution application icon for the Dock and minimized windows.
- Provide a print-friendly layout where practical.

## 8. Syntax highlighting

- Highlight fenced code blocks when a language is specified.
- Support a practical initial language set, including shell, JavaScript, TypeScript, JSON, Python, Rust, Go, Swift, HTML, CSS, YAML, TOML, and Markdown.
- Use coordinated light and dark highlighting themes.
- Fall back to unhighlighted monospace text for unknown languages.
- Bundle highlighting assets locally; normal rendering must not require network access.

## 9. Zoom

The viewer must support whole-page zoom so that text, code, images, and tables scale together.

Required shortcuts:

- `Command-+` or `Command-=`: zoom in
- `Command--`: zoom out
- `Command-0`: reset zoom

Zooming should:

- Re-render sharply rather than producing visibly blurred text.
- Keep the document usable across a practical zoom range.
- Preserve the reader's approximate location in the document.

Remembering the last zoom level is desirable but not required for the MVP.

## 10. Navigation and interaction

### 10.1 Required

- Scroll using trackpad, mouse, and keyboard.
- Select and copy text using normal macOS behavior.
- Navigate links to headings within the document.
- Open `http` and `https` links in the default system browser rather than inside the viewer.
- Support standard macOS quit and close-window shortcuts.

### 10.2 Current enhancements

- `Command-F` document search with next and previous match commands
- `Command-R` manual reload
- An on-demand, collapsible table-of-contents sidebar
- Standard macOS Window menu, Dock window list, and `Command-\`` window cycling

### 10.3 Future possibilities

- Drag and drop a Markdown file onto the window
- Open links to local Markdown files in the viewer
- Back and forward navigation for local Markdown links

## 11. Automatic reload

The viewer should monitor the open file and refresh when it changes on disk.

Reloading should:

- Be debounced to handle editors that save through multiple filesystem operations.
- Preserve scroll position where practical.
- Display a non-destructive error if the file temporarily disappears or cannot be read.
- Avoid unnecessary polling and CPU usage.

Automatic reload with debouncing and scroll-position preservation is implemented.

## 12. Performance and footprint

- Do not bundle Electron, Chromium, or another complete browser runtime.
- Use macOS system frameworks where possible.
- Start quickly enough to feel suitable for one-off file viewing.
- Remain effectively idle when the document is unchanged and the user is not interacting.
- Avoid continuous redraw loops.
- Load and highlight documents off the main UI thread when needed to keep the window responsive.
- Handle ordinary README files and moderately large technical documents smoothly.
- Block remote document resources by default.

Targets should be measured on a release build before setting hard limits. Initial goals are:

- A small distributable application/CLI, preferably in the tens of megabytes or less
- Steady-state memory substantially below typical Electron-based Markdown applications
- Negligible CPU usage while idle

## 13. Security and privacy

- Do not execute scripts from Markdown documents.
- Do not load rendering libraries, themes, fonts, or scripts from a CDN.
- Restrict navigation so the viewer cannot become a general-purpose browser.
- Open external web links through macOS after an explicit user action.
- Treat local Markdown as untrusted input and handle malformed content without crashing.
- Do not collect telemetry.
- Do not require network access for local documents.

## 14. Accessibility

- Render selectable, semantic text rather than a bitmap or canvas-only representation.
- Support standard macOS accessibility and keyboard navigation.
- Respect system font rendering and display scaling.
- Maintain adequate contrast in light and dark themes.
- Respect Reduce Motion where applicable.

## 15. Proposed implementation constraints

The preferred implementation is:

- Swift
- AppKit for application and window management
- `WKWebView` for document presentation
- A bundled CommonMark/GitHub-flavored Markdown parser (markdown-it with task-list support)
- A trimmed bundled highlight.js build
- Bundled HTML and CSS templates

The implementation should create its UI programmatically and avoid storyboards unless they provide a clear benefit.

`WKWebView` should load generated HTML with the Markdown file's parent directory as its base URL so relative images work correctly. Network and navigation behavior must be controlled through WebKit policies and an appropriate Content Security Policy.

This architecture is preferred over a custom GPU renderer because macOS already provides accelerated text, layout, accessibility, printing, and web rendering through system frameworks.

## 16. Distribution

- Provide an installable `mdview` command on the user's `PATH` through Homebrew or `make install`.
- Publish tagged source releases that build on Intel and Apple silicon Macs.
- Keep release source self-contained; do not require a package manager beyond the system Swift toolchain.
- Bundle all required templates, styles, and highlighting assets in source builds.
- Build and test Intel and Apple silicon source builds automatically in CI.
- A future signed and notarized `.app` bundle may support opening `.md` files from Finder while retaining the CLI entry point.

## 17. MVP acceptance criteria

The MVP is complete when all of the following are true:

1. Running `mdview README.md` opens a native macOS window.
2. The document renders headings, prose, lists, links, tables, images, quotes, and code blocks correctly.
3. Relative local images load from the Markdown file's directory.
4. Fenced code blocks have syntax highlighting.
5. Light and dark appearances follow the system setting.
6. `Command-+`, `Command--`, and `Command-0` control whole-page zoom.
7. External links open in the default browser.
8. Text can be selected and copied.
9. Embedded Markdown cannot execute arbitrary scripts.
10. The application uses no bundled Chromium/Electron runtime and consumes negligible CPU while idle.

## 18. Post-MVP possibilities

- Print and export to PDF
- Theme selection and custom CSS
- Copy buttons on code blocks
- Remembered window size, position, zoom, and scroll position
- Quick Look extension
- Finder file association
