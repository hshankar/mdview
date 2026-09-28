import Foundation

enum LinkDisposition: Equatable {
    case openExternally
    case deny
}

enum LinkPolicy {
    static func disposition(for url: URL) -> LinkDisposition {
        switch url.scheme?.lowercased() {
        case "http", "https":
            return .openExternally
        default:
            return .deny
        }
    }
}
