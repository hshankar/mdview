import Foundation
import XCTest
@testable import MDView

final class LinkPolicyTests: XCTestCase {
    func testOpensWebLinksExternally() {
        XCTAssertEqual(
            LinkPolicy.disposition(for: URL(string: "https://example.com/docs")!),
            .openExternally
        )
        XCTAssertEqual(
            LinkPolicy.disposition(for: URL(string: "http://example.com")!),
            .openExternally
        )
    }

    func testAllowsLocalDocumentAnchors() {
        XCTAssertEqual(
            LinkPolicy.disposition(for: URL(string: "file:///notes/#heading")!),
            .allowInViewer
        )
    }

    func testDeniesOtherSchemesAndLocalFiles() {
        XCTAssertEqual(
            LinkPolicy.disposition(for: URL(string: "javascript:alert(1)")!),
            .deny
        )
        XCTAssertEqual(
            LinkPolicy.disposition(for: URL(fileURLWithPath: "/private/notes/secret.txt")),
            .deny
        )
        XCTAssertEqual(
            LinkPolicy.disposition(for: URL(string: "mailto:someone@example.com")!),
            .deny
        )
    }
}
