import AppKit
import SwiftUI

struct LocalImage: View {
    let path: String

    var body: some View {
        if let image = NSImage(contentsOfFile: path) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "photo")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

struct AppIconImage: View {
    let app: ShelfApp

    var body: some View {
        let url = AppLauncher.applicationURL(for: app) ?? URL(fileURLWithPath: app.path)

        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .scaledToFit()
            .help(app.name)
    }
}
