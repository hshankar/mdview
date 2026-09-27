import CoreFoundation
import Foundation

private let openDocumentMessageID: Int32 = 1

private func messagePortCallback(
    _ port: CFMessagePort?,
    _ messageID: Int32,
    _ data: CFData?,
    _ info: UnsafeMutableRawPointer?
) -> Unmanaged<CFData>? {
    guard messageID == openDocumentMessageID,
          let data,
          let info,
          let path = String(data: data as Data, encoding: .utf8) else {
        return nil
    }

    let server = Unmanaged<ViewerMessageServer>.fromOpaque(info).takeUnretainedValue()
    server.receive(path: path)
    return nil
}

final class ViewerMessageServer {
    typealias OpenHandler = (URL) -> Void

    static var defaultPortName: String {
        "app.mdview.ipc.mdview.\(getuid())"
    }

    private var port: CFMessagePort?
    private var source: CFRunLoopSource?
    private let openHandler: OpenHandler

    init?(portName: String = defaultPortName, openHandler: @escaping OpenHandler) {
        self.openHandler = openHandler

        var context = CFMessagePortContext(
            version: 0,
            info: nil,
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        context.info = Unmanaged.passUnretained(self).toOpaque()

        var shouldFreeInfo = DarwinBoolean(false)
        guard let port = CFMessagePortCreateLocal(
            nil,
            portName as CFString,
            messagePortCallback,
            &context,
            &shouldFreeInfo
        ) else {
            return nil
        }

        self.port = port
        let source = CFMessagePortCreateRunLoopSource(nil, port, 0)
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    deinit {
        if let port {
            CFMessagePortInvalidate(port)
        }
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
    }

    fileprivate func receive(path: String) {
        let url = URL(fileURLWithPath: path).standardizedFileURL
        DispatchQueue.main.async { [openHandler] in
            openHandler(url)
        }
    }
}

enum ViewerMessageClient {
    static func openInRunningViewer(
        _ fileURL: URL,
        portName: String = ViewerMessageServer.defaultPortName
    ) -> Bool {
        guard let port = CFMessagePortCreateRemote(nil, portName as CFString) else {
            return false
        }

        let data = Data(fileURL.standardizedFileURL.path.utf8) as CFData
        let result = CFMessagePortSendRequest(
            port,
            openDocumentMessageID,
            data,
            0.25,
            0.25,
            nil,
            nil
        )
        return result == kCFMessagePortSuccess
    }
}

enum ViewerServerLauncher {
    static func launch(opening fileURL: URL, executablePath: String = CommandLine.arguments[0]) throws {
        let executableURL = URL(
            fileURLWithPath: executablePath,
            relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        ).standardizedFileURL

        let process = Process()
        process.executableURL = executableURL
        process.arguments = ["--server", fileURL.standardizedFileURL.path]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }
}
