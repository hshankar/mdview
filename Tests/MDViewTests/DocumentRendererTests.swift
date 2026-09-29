import Foundation
import XCTest
@testable import MDView

final class DocumentRendererTests: XCTestCase {
    func testEmbedsMarkdownAsBase64InsteadOfExecutableMarkup() throws {
        let markdown = "# Hello\n<script>alert('no')</script>"
        let html = try DocumentRenderer().render(markdown: markdown)

        XCTAssertFalse(html.contains(markdown))
        XCTAssertTrue(html.contains(Data(markdown.utf8).base64EncodedString()))
        XCTAssertTrue(html.contains("html: false"))
    }

    func testBuildsCompleteOfflineDocument() throws {
        let html = try DocumentRenderer().render(markdown: "```swift\nprint(1)\n```")

        XCTAssertTrue(html.hasPrefix("<!doctype html>"))
        XCTAssertTrue(html.contains("Content-Security-Policy"))
        XCTAssertTrue(html.contains("img-src file: data:"))
        XCTAssertFalse(html.contains("img-src file: data: http: https:"))
        XCTAssertTrue(html.contains("window.markdownit"))
        XCTAssertTrue(html.contains("window.markdownitTaskLists"))
        XCTAssertTrue(html.contains("hljs.highlightElement"))
        XCTAssertTrue(html.contains("prefers-color-scheme: dark"))
        XCTAssertTrue(html.contains("table-of-contents"))
        XCTAssertTrue(html.contains("mdviewToggleSidebar"))
        XCTAssertTrue(html.contains("toc-disclosure"))
        XCTAssertFalse(html.contains("{{DOCUMENT_STYLE}}"))
        XCTAssertFalse(html.contains("{{MARKDOWN_BASE64}}"))
        XCTAssertFalse(html.contains("{{MARKDOWN_IT_SCRIPT}}"))
        XCTAssertFalse(html.contains("{{TASK_LISTS_SCRIPT}}"))
    }
}
