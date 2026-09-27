import Foundation

enum UpdateCommandError: LocalizedError {
    case helperMissing(URL)
    case helperFailed(Int32)

    var errorDescription: String? {
        switch self {
        case let .helperMissing(url):
            return "update helper is missing at \(url.path); run the installer once to upgrade this older installation"
        case let .helperFailed(status):
            return "update failed with exit status \(status)"
        }
    }
}

enum UpdateCommand {
    static let helperName = "mdview-update"

    static func helperURL(for executableURL: URL) -> URL {
        executableURL.deletingLastPathComponent().appendingPathComponent(helperName)
    }

    static func run(executableURL: URL? = nil) throws {
        let executableURL = executableURL
            ?? Bundle.main.executableURL
            ?? URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
        let helperURL = helperURL(for: executableURL)

        guard FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            throw UpdateCommandError.helperMissing(helperURL)
        }

        let process = Process()
        process.executableURL = helperURL
        var environment = ProcessInfo.processInfo.environment
        environment["MDVIEW_INSTALL_DIR"] = executableURL.deletingLastPathComponent().path
        process.environment = environment
        try process.run()
        process.waitUntilExit()

        guard process.terminationReason == .exit, process.terminationStatus == 0 else {
            throw UpdateCommandError.helperFailed(process.terminationStatus)
        }
    }
}
