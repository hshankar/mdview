import Foundation
import XCTest
@testable import MDView

final class FileWatcherTests: XCTestCase {
    func testReportsDebouncedAtomicFileChanges() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("README.md")
        try Data("first".utf8).write(to: file)

        let changed = expectation(description: "file change delivered")
        changed.assertForOverFulfill = true
        var receivedMarkdown: String?
        let watcher = try FileWatcher(fileURL: file, debounceInterval: 0.05) { result in
            switch result {
            case let .success(markdown):
                receivedMarkdown = markdown
                changed.fulfill()
            case let .failure(error):
                XCTFail("Unexpected watcher error: \(error)")
            }
        }

        try Data("second".utf8).write(to: file, options: .atomic)
        try Data("final".utf8).write(to: file, options: .atomic)

        wait(for: [changed], timeout: 2)
        XCTAssertEqual(receivedMarkdown, "final")
        withExtendedLifetime(watcher) {}
    }
}
