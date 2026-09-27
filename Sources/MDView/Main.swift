import AppKit
import Foundation

@main
@MainActor
struct MDViewApp {
    static func main() {
        do {
            switch try CLI.parse(arguments: Array(CommandLine.arguments.dropFirst())) {
            case .help:
                print(CLI.usage)
            case .version:
                print("mdview \(CLI.version)")
            case let .view(fileURL):
                if !ViewerMessageClient.openInRunningViewer(fileURL) {
                    try ViewerServerLauncher.launch(opening: fileURL)
                }
            case let .serve(fileURL):
                runApplication(opening: fileURL)
            case .update:
                try UpdateCommand.run()
            }
        } catch {
            let message = "mdview: \(error.localizedDescription)\n"
            FileHandle.standardError.write(Data(message.utf8))
            exit(EXIT_FAILURE)
        }
    }

    private static func runApplication(opening fileURL: URL) {
        let application = NSApplication.shared
        let delegate = AppDelegate(fileURL: fileURL)
        application.delegate = delegate
        application.setActivationPolicy(.regular)

        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}
