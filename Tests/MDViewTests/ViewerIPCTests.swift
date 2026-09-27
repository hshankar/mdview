import Foundation
import XCTest
@testable import MDView

final class ViewerIPCTests: XCTestCase {
    func testReturnsFalseWhenNoServerIsRunning() {
        XCTAssertFalse(
            ViewerMessageClient.openInRunningViewer(
                URL(fileURLWithPath: "/tmp/example.md"),
                portName: "mdview.tests.missing.\(UUID().uuidString)"
            )
        )
    }

    func testOnlyOneServerCanOwnAPortName() throws {
        let portName = "mdview.tests.owner.\(UUID().uuidString)"
        let first = try XCTUnwrap(ViewerMessageServer(portName: portName) { _ in })
        XCTAssertNil(ViewerMessageServer(portName: portName) { _ in })
        withExtendedLifetime(first) {}
    }

    func testSendsFilePathToRunningServer() throws {
        let received = expectation(description: "server receives path")
        let expectedURL = URL(fileURLWithPath: "/tmp/a document.md").standardizedFileURL
        let portName = "mdview.tests.\(UUID().uuidString)"
        let server = try XCTUnwrap(
            ViewerMessageServer(portName: portName) { url in
                XCTAssertEqual(url, expectedURL)
                received.fulfill()
            }
        )

        let sent = expectation(description: "client sends request")
        DispatchQueue.global().async {
            XCTAssertTrue(
                ViewerMessageClient.openInRunningViewer(expectedURL, portName: portName)
            )
            sent.fulfill()
        }

        wait(for: [sent, received], timeout: 2)
        withExtendedLifetime(server) {}
    }
}
