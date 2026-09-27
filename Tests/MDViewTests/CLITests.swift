import Foundation
import XCTest
@testable import MDView

final class CLITests: XCTestCase {
    func testParsesExistingFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("README.md")
        try Data("# Hello".utf8).write(to: file)

        XCTAssertEqual(try CLI.parse(arguments: [file.path]), .view(file.standardizedFileURL))
        XCTAssertEqual(
            try CLI.parse(arguments: ["--server", file.path]),
            .serve(file.standardizedFileURL)
        )
    }

    func testParsesHelpAndVersion() throws {
        XCTAssertEqual(try CLI.parse(arguments: ["--help"]), .help)
        XCTAssertEqual(try CLI.parse(arguments: ["-v"]), .version)
        XCTAssertEqual(try CLI.parse(arguments: ["update"]), .update)
    }

    func testRejectsMissingArgument() {
        XCTAssertThrowsError(try CLI.parse(arguments: [])) { error in
            XCTAssertEqual(error as? CLIError, .missingFile)
        }
    }

    func testRejectsUnknownOption() {
        XCTAssertThrowsError(try CLI.parse(arguments: ["--wat"])) { error in
            XCTAssertEqual(error as? CLIError, .unknownOption("--wat"))
        }
    }

    func testRejectsDirectory() {
        XCTAssertThrowsError(
            try CLI.parse(arguments: [FileManager.default.temporaryDirectory.path])
        ) { error in
            XCTAssertEqual(
                error as? CLIError,
                .pathIsNotAFile(FileManager.default.temporaryDirectory.path)
            )
        }
    }
}
