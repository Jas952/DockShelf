import AppKit
import Foundation

enum DockStackService {
    static var stackRootURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
            .appendingPathComponent("DockShelf Stacks", isDirectory: true)
    }

    static var agentsFolderURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
            .appendingPathComponent("DockShelf Agents", isDirectory: true)
    }

    static func syncAgentsFolder(for groups: [ShelfGroup]) throws {
        let fileManager = FileManager.default
        let parentURL = agentsFolderURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true)

        if fileManager.fileExists(atPath: agentsFolderURL.path) {
            try fileManager.removeItem(at: agentsFolderURL)
        }

        try fileManager.createDirectory(at: agentsFolderURL, withIntermediateDirectories: true)

        var seenPaths: Set<String> = []
        var usedNames: Set<String> = []

        for app in groups.flatMap(\.apps) {
            guard !seenPaths.contains(app.path) else {
                continue
            }

            seenPaths.insert(app.path)
            let aliasURL = agentsFolderURL.appendingPathComponent(uniqueAliasName(for: app, usedNames: &usedNames))
            try createAlias(from: URL(fileURLWithPath: app.path), to: aliasURL)
        }

        applyAgentsFolderIcon()
    }

    static func syncStacks(for groups: [ShelfGroup]) throws {
        try FileManager.default.createDirectory(at: stackRootURL, withIntermediateDirectories: true)

        for group in groups {
            let groupURL = stackRootURL.appendingPathComponent(group.title, isDirectory: true)
            if FileManager.default.fileExists(atPath: groupURL.path) {
                try FileManager.default.removeItem(at: groupURL)
            }

            try FileManager.default.createDirectory(at: groupURL, withIntermediateDirectories: true)

            for app in group.apps {
                let aliasURL = groupURL.appendingPathComponent(app.name).appendingPathExtension("app")
                try createAlias(from: URL(fileURLWithPath: app.path), to: aliasURL)
            }
        }
    }

    static func revealStacksFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([stackRootURL])
    }

    static func revealAgentsFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([agentsFolderURL])
    }

    private static func createAlias(from sourceURL: URL, to aliasURL: URL) throws {
        let bookmark = try sourceURL.bookmarkData(
            options: [.suitableForBookmarkFile],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        try URL.writeBookmarkData(bookmark, to: aliasURL)
    }

    private static func uniqueAliasName(for app: ShelfApp, usedNames: inout Set<String>) -> String {
        let baseName = sanitizedFilename(app.name.isEmpty ? URL(fileURLWithPath: app.path).deletingPathExtension().lastPathComponent : app.name)
        var candidate = "\(baseName).app"
        var index = 2

        while usedNames.contains(candidate) {
            candidate = "\(baseName) \(index).app"
            index += 1
        }

        usedNames.insert(candidate)
        return candidate
    }

    private static func sanitizedFilename(_ name: String) -> String {
        let illegalCharacters = CharacterSet(charactersIn: "/:")
        let parts = name.components(separatedBy: illegalCharacters)
        let sanitized = parts.joined(separator: "-").trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitized.isEmpty ? "Application" : sanitized
    }

    private static func applyAgentsFolderIcon() {
        guard
            let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
            let icon = NSImage(contentsOf: iconURL)
        else {
            return
        }

        NSWorkspace.shared.setIcon(icon, forFile: agentsFolderURL.path, options: [])
    }
}
