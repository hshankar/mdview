import Foundation

enum DocumentRendererError: LocalizedError {
    case missingResource(String)
    case unreadableResource(String, Error)

    var errorDescription: String? {
        switch self {
        case let .missingResource(name):
            return "The bundled rendering resource '\(name)' is missing."
        case let .unreadableResource(name, error):
            return "The bundled rendering resource '\(name)' could not be read: \(error.localizedDescription)"
        }
    }
}

struct DocumentRenderer {
    private let template: String
    private let stylesheet: String
    private let markdownItScript: String
    private let taskListsScript: String
    private let highlightScript: String

    init(bundle: Bundle = .module) throws {
        template = try Self.loadResource("template", extension: "html", bundle: bundle)
        stylesheet = try Self.loadResource("document", extension: "css", bundle: bundle)
        markdownItScript = try Self.loadResource("markdown-it", extension: "js", bundle: bundle)
        taskListsScript = try Self.loadResource("markdown-it-task-lists", extension: "js", bundle: bundle)
        highlightScript = try Self.loadResource("highlight", extension: "js", bundle: bundle)
    }

    func render(markdown: String) -> String {
        let encodedMarkdown = Data(markdown.utf8).base64EncodedString()

        return template
            .replacingOccurrences(of: "{{DOCUMENT_STYLE}}", with: stylesheet)
            .replacingOccurrences(of: "{{MARKDOWN_IT_SCRIPT}}", with: markdownItScript)
            .replacingOccurrences(of: "{{TASK_LISTS_SCRIPT}}", with: taskListsScript)
            .replacingOccurrences(of: "{{HIGHLIGHT_SCRIPT}}", with: highlightScript)
            .replacingOccurrences(of: "{{MARKDOWN_BASE64}}", with: encodedMarkdown)
    }

    private static func loadResource(
        _ name: String,
        extension fileExtension: String,
        bundle: Bundle
    ) throws -> String {
        let filename = "\(name).\(fileExtension)"
        guard let url = bundle.url(forResource: name, withExtension: fileExtension) else {
            throw DocumentRendererError.missingResource(filename)
        }

        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw DocumentRendererError.unreadableResource(filename, error)
        }
    }
}
