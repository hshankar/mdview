import Foundation
import WebKit
import XCTest
@testable import MDView

private struct RenderedDocumentSnapshot: Decodable {
    let headingIDs: [String]
    let tableCount: Int
    let orderedListCount: Int
    let blockquoteText: String?
    let emphasisText: String?
    let strongText: String?
    let inlineCodeText: String?
    let hardBreakCount: Int
    let horizontalRuleCount: Int
    let taskCount: Int
    let checkedTaskCount: Int
    let disabledTaskCount: Int
    let strikethroughText: String?
    let automaticLink: String?
    let unsafeLinkCount: Int
    let unsafeImageCount: Int
    let rawScriptCount: Int
    let rawScriptExecuted: Bool
    let bodyText: String
    let codeClass: String?
    let imageSource: String?
}

private final class NavigationObserver: NSObject, WKNavigationDelegate {
    let finished: XCTestExpectation
    var error: Error?

    init(finished: XCTestExpectation) {
        self.finished = finished
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finished.fulfill()
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        self.error = error
        finished.fulfill()
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        self.error = error
        finished.fulfill()
    }
}

final class RenderingIntegrationTests: XCTestCase {
    @MainActor
    func testRendersRequiredMarkdownAndRejectsUnsafeMarkup() async throws {
        let markdown = """
        # Hello *World*
        ## Hello World
        # Hello World

        Paragraph with *emphasis*, **strong text**, and `inline code`.  
        This starts after a hard break.

        1. First ordered item
        2. Second ordered item

        > Quoted text

        ---

        - [ ] Open task
        - [x] Done task

        | Name | Value |
        | --- | ---: |
        | speed | fast |

        ~~removed~~

        https://example.com/path

        <script>window.mdviewCompromised = true</script>

        [unsafe](javascript:alert(1))

        ![unsafe](javascript:alert(1))

        ![Local image](images/demo.png)

        ```swift
        print("hello")
        ```
        """

        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 920, height: 760))
        let navigationFinished = expectation(description: "Markdown document loaded")
        let observer = NavigationObserver(finished: navigationFinished)
        webView.navigationDelegate = observer
        webView.loadHTMLString(
            try DocumentRenderer().render(markdown: markdown),
            baseURL: URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        )

        await fulfillment(of: [navigationFinished], timeout: 10)
        XCTAssertNil(observer.error)

        let script = """
        JSON.stringify({
          headingIDs: Array.from(document.querySelectorAll("#document h1, #document h2"), heading => heading.id),
          tableCount: document.querySelectorAll("#document table").length,
          orderedListCount: document.querySelectorAll("#document ol").length,
          blockquoteText: document.querySelector("#document blockquote")?.textContent.trim() ?? null,
          emphasisText: Array.from(document.querySelectorAll("#document em"))
            .find(element => element.textContent === "emphasis")?.textContent ?? null,
          strongText: document.querySelector("#document strong")?.textContent ?? null,
          inlineCodeText: document.querySelector("#document p code")?.textContent ?? null,
          hardBreakCount: document.querySelectorAll("#document p br").length,
          horizontalRuleCount: document.querySelectorAll("#document hr").length,
          taskCount: document.querySelectorAll("#document input.task-list-item-checkbox").length,
          checkedTaskCount: document.querySelectorAll("#document input.task-list-item-checkbox:checked").length,
          disabledTaskCount: document.querySelectorAll("#document input.task-list-item-checkbox:disabled").length,
          strikethroughText: document.querySelector("#document s")?.textContent ?? null,
          automaticLink: Array.from(document.querySelectorAll("#document a"))
            .find(link => link.textContent === "https://example.com/path")?.getAttribute("href") ?? null,
          unsafeLinkCount: Array.from(document.querySelectorAll("#document a"))
            .filter(link => link.getAttribute("href")?.startsWith("javascript:")).length,
          unsafeImageCount: Array.from(document.querySelectorAll("#document img"))
            .filter(image => image.getAttribute("src")?.startsWith("javascript:")).length,
          rawScriptCount: document.querySelectorAll("#document script").length,
          rawScriptExecuted: window.mdviewCompromised === true,
          bodyText: document.getElementById("document").textContent,
          codeClass: document.querySelector("#document pre code")?.className ?? null,
          imageSource: document.querySelector("#document img")?.getAttribute("src") ?? null
        })
        """
        let value = try await webView.evaluateJavaScript(script)
        let jsonString = try XCTUnwrap(value as? String)
        let json = try XCTUnwrap(jsonString.data(using: .utf8))
        let snapshot = try JSONDecoder().decode(RenderedDocumentSnapshot.self, from: json)

        XCTAssertEqual(snapshot.headingIDs, ["hello-world", "hello-world-1", "hello-world-2"])
        XCTAssertEqual(snapshot.tableCount, 1)
        XCTAssertEqual(snapshot.orderedListCount, 1)
        XCTAssertEqual(snapshot.blockquoteText, "Quoted text")
        XCTAssertEqual(snapshot.emphasisText, "emphasis")
        XCTAssertEqual(snapshot.strongText, "strong text")
        XCTAssertEqual(snapshot.inlineCodeText, "inline code")
        XCTAssertEqual(snapshot.hardBreakCount, 1)
        XCTAssertEqual(snapshot.horizontalRuleCount, 1)
        XCTAssertEqual(snapshot.taskCount, 2)
        XCTAssertEqual(snapshot.checkedTaskCount, 1)
        XCTAssertEqual(snapshot.disabledTaskCount, 2)
        XCTAssertEqual(snapshot.strikethroughText, "removed")
        XCTAssertEqual(snapshot.automaticLink, "https://example.com/path")
        XCTAssertEqual(snapshot.unsafeLinkCount, 0)
        XCTAssertEqual(snapshot.unsafeImageCount, 0)
        XCTAssertEqual(snapshot.rawScriptCount, 0)
        XCTAssertFalse(snapshot.rawScriptExecuted)
        XCTAssertTrue(snapshot.bodyText.contains("<script>window.mdviewCompromised = true</script>"))
        XCTAssertTrue(snapshot.bodyText.contains("[unsafe](javascript:alert(1))"))
        XCTAssertEqual(snapshot.codeClass, "language-swift hljs")
        XCTAssertEqual(snapshot.imageSource, "images/demo.png")
    }
}
