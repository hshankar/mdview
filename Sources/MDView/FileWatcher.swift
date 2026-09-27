import Foundation

struct FileWatcherError: LocalizedError {
    let directory: URL
    let code: Int32

    var errorDescription: String? {
        let reason = String(cString: strerror(code))
        return "Could not monitor \(directory.path): \(reason)"
    }
}

final class FileWatcher {
    typealias ChangeHandler = (Result<String, Error>) -> Void

    private let fileURL: URL
    private let queue: DispatchQueue
    private let source: DispatchSourceFileSystemObject
    private let changeHandler: ChangeHandler
    private var lastContents: Data
    private var pendingRead: DispatchWorkItem?
    private var reportedReadError = false

    init(
        fileURL: URL,
        debounceInterval: TimeInterval = 0.15,
        changeHandler: @escaping ChangeHandler
    ) throws {
        self.fileURL = fileURL
        self.changeHandler = changeHandler
        lastContents = try Data(contentsOf: fileURL)
        queue = DispatchQueue(label: "mdview.file-watcher", qos: .utility)

        let directory = fileURL.deletingLastPathComponent()
        let descriptor = open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else {
            throw FileWatcherError(directory: directory, code: errno)
        }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .attrib, .link, .rename, .delete],
            queue: queue
        )
        source.setCancelHandler {
            close(descriptor)
        }
        source.setEventHandler { [weak self] in
            guard let self else { return }
            pendingRead?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.readIfChanged()
            }
            pendingRead = workItem
            queue.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
        }
        source.resume()
    }

    deinit {
        pendingRead?.cancel()
        source.cancel()
    }

    private func readIfChanged() {
        do {
            let contents = try Data(contentsOf: fileURL)
            guard contents != lastContents else { return }
            lastContents = contents
            reportedReadError = false

            guard let markdown = String(data: contents, encoding: .utf8) else {
                throw CocoaError(.fileReadInapplicableStringEncoding)
            }
            deliver(.success(markdown))
        } catch {
            guard !reportedReadError else { return }
            reportedReadError = true
            deliver(.failure(error))
        }
    }

    private func deliver(_ result: Result<String, Error>) {
        DispatchQueue.main.async { [changeHandler] in
            changeHandler(result)
        }
    }
}
