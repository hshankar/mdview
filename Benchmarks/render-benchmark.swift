import AppKit
import Foundation
import WebKit

struct RenderMetrics: Codable {
    let base64DecodeMilliseconds: Double
    let byteArrayMilliseconds: Double
    let utf8DecodeMilliseconds: Double
    let parserMilliseconds: Double
    let htmlGenerationMilliseconds: Double
    let domInsertionMilliseconds: Double
    let highlightingMilliseconds: Double
    let outlineMilliseconds: Double
    let layoutMilliseconds: Double
    let totalMilliseconds: Double
    let complete: Bool
    let headingCount: Int
    let codeBlockCount: Int
}

struct Sample: Codable {
    let wallMilliseconds: Double
    let render: RenderMetrics
}

struct Result: Codable {
    let file: String
    let bytes: Int
    let samples: [Sample]
}

final class Benchmark: NSObject, WKNavigationDelegate {
    private let html: String
    private let baseURL: URL
    private let remainingRuns: Int
    private let markdownBytes: Int
    private let webView: WKWebView
    private let window: NSWindow
    private var samples: [Sample] = []
    private var loadStartedAt: DispatchTime?

    init(html: String, baseURL: URL, markdownBytes: Int, runs: Int) {
        self.html = html
        self.baseURL = baseURL
        self.markdownBytes = markdownBytes
        remainingRuns = runs

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        webView = WKWebView(frame: .zero, configuration: configuration)
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        super.init()
        window.contentView = webView
        webView.navigationDelegate = self
    }

    func run() {
        loadNextRun()
        NSApplication.shared.run()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        collectMetrics()
    }

    private func collectMetrics() {
        webView.evaluateJavaScript("JSON.stringify(window.mdviewRenderMetrics)") { [self] value, error in
            guard error == nil,
                  let json = value as? String,
                  let data = json.data(using: .utf8),
                  let render = try? JSONDecoder().decode(RenderMetrics.self, from: data),
                  let loadStartedAt else {
                fputs("Could not collect WebKit render metrics.\n", stderr)
                exit(1)
            }

            guard render.complete else {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(5)) { [weak self] in
                    self?.collectMetrics()
                }
                return
            }

            let wallMilliseconds = Double(DispatchTime.now().uptimeNanoseconds - loadStartedAt.uptimeNanoseconds)
                / 1_000_000
            samples.append(Sample(wallMilliseconds: wallMilliseconds, render: render))

            if samples.count == remainingRuns {
                let result = Result(file: baseURL.path, bytes: markdownBytes, samples: samples)
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                FileHandle.standardOutput.write(try! encoder.encode(result))
                exit(EXIT_SUCCESS)
            } else {
                loadNextRun()
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        fputs("WebKit navigation failed: \(error.localizedDescription)\n", stderr)
        exit(1)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        fputs("WebKit navigation failed: \(error.localizedDescription)\n", stderr)
        exit(1)
    }

    private func loadNextRun() {
        loadStartedAt = .now()
        webView.loadHTMLString(html, baseURL: baseURL)
    }
}

func usage() -> Never {
    fputs("usage: render-benchmark <repository-root> <markdown-file> [runs]\n", stderr)
    exit(2)
}

guard CommandLine.arguments.count == 3 || CommandLine.arguments.count == 4 else { usage() }
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fileURL = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
let runs = CommandLine.arguments.count == 4 ? Int(CommandLine.arguments[3]) ?? 0 : 5
guard runs > 0 else { usage() }

func resource(_ name: String) throws -> String {
    try String(contentsOf: root.appendingPathComponent("Sources/MDView/Resources/\(name)"), encoding: .utf8)
}

let markdown = try String(contentsOf: fileURL, encoding: .utf8)
let html = try resource("template.html")
    .replacingOccurrences(of: "{{DOCUMENT_STYLE}}", with: resource("document.css"))
    .replacingOccurrences(of: "{{MARKDOWN_IT_SCRIPT}}", with: resource("markdown-it.js"))
    .replacingOccurrences(of: "{{TASK_LISTS_SCRIPT}}", with: resource("markdown-it-task-lists.js"))
    .replacingOccurrences(of: "{{HIGHLIGHT_SCRIPT}}", with: resource("highlight.js"))
    .replacingOccurrences(of: "{{MARKDOWN_BASE64}}", with: Data(markdown.utf8).base64EncodedString())

NSApplication.shared.setActivationPolicy(.prohibited)
Benchmark(
    html: html,
    baseURL: fileURL.deletingLastPathComponent(),
    markdownBytes: markdown.utf8.count,
    runs: runs
).run()
