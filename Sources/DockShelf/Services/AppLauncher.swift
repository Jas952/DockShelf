import AppKit
import Foundation

enum AppLauncher {
    static func applicationURL(for app: ShelfApp) -> URL? {
        if
            let bundleIdentifier = app.bundleIdentifier,
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        {
            return url
        }

        let url = URL(fileURLWithPath: app.path)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        return url
    }

    static func open(_ app: ShelfApp) {
        guard let url = applicationURL(for: app) else {
            NSSound.beep()
            return
        }

        NSWorkspace.shared.openApplication(
            at: url,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }
}
