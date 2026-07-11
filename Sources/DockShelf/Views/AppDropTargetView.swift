import AppKit
import SwiftUI

struct AppDropTargetView: NSViewRepresentable {
    let onTargeted: (Bool) -> Void
    let onDrop: ([URL]) -> Void

    func makeNSView(context: Context) -> DropTargetNSView {
        let view = DropTargetNSView()
        view.onTargeted = onTargeted
        view.onDrop = onDrop
        return view
    }

    func updateNSView(_ nsView: DropTargetNSView, context: Context) {
        nsView.onTargeted = onTargeted
        nsView.onDrop = onDrop
    }
}

final class DropTargetNSView: NSView {
    var onTargeted: ((Bool) -> Void)?
    var onDrop: (([URL]) -> Void)?

    private let acceptedTypes: [NSPasteboard.PasteboardType] = [
        .fileURL,
        .URL,
        NSPasteboard.PasteboardType("public.file-url"),
        NSPasteboard.PasteboardType("com.apple.application-bundle"),
        NSPasteboard.PasteboardType("NSFilenamesPboardType")
    ]

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes(acceptedTypes)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes(acceptedTypes)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        switch NSApp.currentEvent?.type {
        case .leftMouseDragged, .leftMouseUp:
            return self
        default:
            return nil
        }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard !applicationURLs(from: sender.draggingPasteboard).isEmpty else {
            return []
        }

        onTargeted?(true)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        applicationURLs(from: sender.draggingPasteboard).isEmpty ? [] : .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onTargeted?(false)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        onTargeted?(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = applicationURLs(from: sender.draggingPasteboard)
        guard !urls.isEmpty else {
            onTargeted?(false)
            return false
        }

        onDrop?(urls)
        onTargeted?(false)
        return true
    }

    private func applicationURLs(from pasteboard: NSPasteboard) -> [URL] {
        var urls: [URL] = []

        if
            let readURLs = pasteboard.readObjects(
                forClasses: [NSURL.self],
                options: [.urlReadingFileURLsOnly: true]
            ) as? [URL]
        {
            urls.append(contentsOf: readURLs)
        }

        if let filenames = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            urls.append(contentsOf: filenames.map { URL(fileURLWithPath: $0) })
        }

        for item in pasteboard.pasteboardItems ?? [] {
            for type in item.types {
                if let string = item.string(forType: type), let url = Self.url(from: string) {
                    urls.append(url)
                    continue
                }

                if let data = item.data(forType: type) {
                    if let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                    } else if let string = String(data: data, encoding: .utf8), let url = Self.url(from: string) {
                        urls.append(url)
                    }
                }
            }
        }

        var seen: Set<String> = []
        return urls.filter { url in
            guard url.pathExtension.localizedCaseInsensitiveCompare("app") == .orderedSame else {
                return false
            }

            let path = url.standardizedFileURL.path
            guard !seen.contains(path) else {
                return false
            }

            seen.insert(path)
            return true
        }
    }

    private static func url(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = URL(string: trimmed), url.isFileURL {
            return url
        }

        if trimmed.hasPrefix("/") {
            return URL(fileURLWithPath: trimmed)
        }

        return nil
    }
}
