import Foundation

enum LinkDisposition: Equatable {
    case allowInViewer
    case openExternally
    case deny
}

enum LinkPolicy {
    static func disposition(for url: URL) -> LinkDisposition {
        if url.isFileURL, url.fragment != nil {
            return .allowInViewer
        }

        switch url.scheme?.lowercased() {
        case "http", "https":
            return .openExternally
        default:
            return .deny
        }
    }
}
