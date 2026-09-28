import Foundation

enum LaunchRequest: Equatable {
    case view(URL)
    case serve(URL)
    case update
    case help
    case version
}

enum CLIError: LocalizedError, Equatable {
    case missingFile
    case tooManyArguments
    case unknownOption(String)
    case fileDoesNotExist(String)
    case pathIsNotAFile(String)

    var errorDescription: String? {
        switch self {
        case .missingFile:
            return "missing Markdown file\n\n\(CLI.usage)"
        case .tooManyArguments:
            return "only one Markdown file can be opened at a time\n\n\(CLI.usage)"
        case let .unknownOption(option):
            return "unknown option: \(option)\n\n\(CLI.usage)"
        case let .fileDoesNotExist(path):
            return "file does not exist: \(path)"
        case let .pathIsNotAFile(path):
            return "path is not a regular file: \(path)"
        }
    }
}

enum CLI {
    static let version = "0.1.5"

    static let usage = """
    Usage: mdview <file>

    Options:
      -h, --help       Show this help
      -v, --version    Show the version
      update           Install the latest release
    """

    static func parse(
        arguments: [String],
        fileManager: FileManager = .default
    ) throws -> LaunchRequest {
        guard let argument = arguments.first else {
            throw CLIError.missingFile
        }

        if argument == "update" {
            guard arguments.count == 1 else {
                throw CLIError.tooManyArguments
            }
            return .update
        }

        if argument == "--server" {
            guard arguments.count == 2 else {
                throw CLIError.missingFile
            }
            return .serve(try validatedFileURL(arguments[1], fileManager: fileManager))
        }

        guard arguments.count == 1 else {
            throw CLIError.tooManyArguments
        }

        switch argument {
        case "-h", "--help":
            return .help
        case "-v", "--version":
            return .version
        default:
            if argument.hasPrefix("-") {
                throw CLIError.unknownOption(argument)
            }
        }

        return .view(try validatedFileURL(argument, fileManager: fileManager))
    }

    private static func validatedFileURL(
        _ path: String,
        fileManager: FileManager
    ) throws -> URL {
        let expandedPath = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath).standardizedFileURL
        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw CLIError.fileDoesNotExist(path)
        }
        guard !isDirectory.boolValue else {
            throw CLIError.pathIsNotAFile(path)
        }
        return url
    }
}
