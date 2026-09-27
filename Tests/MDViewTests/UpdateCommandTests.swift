import Foundation
import XCTest
@testable import MDView

final class UpdateCommandTests: XCTestCase {
    func testFindsUpdaterBesideExecutable() {
        let executable = URL(fileURLWithPath: "/opt/mdview/bin/mdview")

        XCTAssertEqual(
            UpdateCommand.helperURL(for: executable).path,
            "/opt/mdview/bin/mdview-update"
        )
    }

    func testRunsUpdaterBesideExecutableWithItsInstallationDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let executable = directory.appendingPathComponent("mdview")
        let output = directory.appendingPathComponent("output")
        let helper = UpdateCommand.helperURL(for: executable)
        let script = "#!/bin/sh\nprintf '%s' \"$MDVIEW_INSTALL_DIR\" > '\(output.path)'\n"
        try Data(script.utf8).write(to: helper)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: helper.path
        )

        try UpdateCommand.run(executableURL: executable)
        XCTAssertEqual(try String(contentsOf: output, encoding: .utf8), directory.path)
    }

    func testReportsMissingUpdaterClearly() {
        let executable = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("mdview")

        XCTAssertThrowsError(try UpdateCommand.run(executableURL: executable)) { error in
            XCTAssertEqual(
                error.localizedDescription,
                "update helper is missing at \(executable.deletingLastPathComponent().appendingPathComponent("mdview-update").path); run the installer once to upgrade this older installation"
            )
        }
    }
}
