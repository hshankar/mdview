import CoreGraphics
import Foundation

struct Configuration {
    let executable: String
    let ownerName: String
    let keepProcess: Bool
    let arguments: [String]

    init(arguments: [String]) {
        guard arguments.count >= 4, let separator = arguments.firstIndex(of: "--") else {
            fputs(
                "usage: window-benchmark <executable> <window-owner-name> [--keep] -- <arguments...>\n",
                stderr
            )
            exit(2)
        }

        executable = arguments[1]
        ownerName = arguments[2]
        keepProcess = arguments[3..<separator].contains("--keep")
        self.arguments = Array(arguments[(separator + 1)...])
    }
}

func visibleWindows() -> [[String: Any]] {
    CGWindowListCopyWindowInfo(
        [.optionOnScreenOnly, .excludeDesktopElements],
        .zero
    ) as? [[String: Any]] ?? []
}

func windowID(_ window: [String: Any]) -> CGWindowID? {
    (window[kCGWindowNumber as String] as? NSNumber)?.uint32Value
}

let configuration = Configuration(arguments: CommandLine.arguments)
let windowsBeforeLaunch = Set(visibleWindows().compactMap(windowID))

let process = Process()
process.executableURL = URL(fileURLWithPath: configuration.executable)
process.arguments = configuration.arguments
process.standardOutput = FileHandle.nullDevice
process.standardError = FileHandle.nullDevice

let start = DispatchTime.now().uptimeNanoseconds
try process.run()
let launchedPID = process.processIdentifier
var ownerPID: Int32?

while DispatchTime.now().uptimeNanoseconds - start < 5_000_000_000 {
    ownerPID = visibleWindows().first(where: { window in
        guard let id = windowID(window), !windowsBeforeLaunch.contains(id) else {
            return false
        }
        let pid = (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value
        let name = window[kCGWindowOwnerName as String] as? String
        return pid == launchedPID || name == configuration.ownerName
    }).flatMap { window in
        (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value
    }

    if ownerPID != nil {
        break
    }
    usleep(2_000)
}

let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000

if !configuration.keepProcess, process.isRunning {
    process.terminate()
    process.waitUntilExit()
}

guard let ownerPID else {
    fputs("No new window appeared within five seconds.\n", stderr)
    if process.isRunning {
        process.terminate()
    }
    exit(1)
}

print(String(format: "%.1f %d %d", elapsed, launchedPID, ownerPID))
