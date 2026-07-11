import AppKit
import SwiftUI

enum DockShelfIdentity {
    static var appIcon: NSImage {
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            return icon
        }

        return NSApp.applicationIconImage
    }

    static var versionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        let version = shortVersion.flatMap { $0.isEmpty ? nil : $0 } ?? "1.0"

        if let buildVersion, !buildVersion.isEmpty, buildVersion != version {
            return "Version \(version) (\(buildVersion))"
        }

        return "Version \(version)"
    }
}

struct DockShelfAppIconView: View {
    let size: CGFloat

    var body: some View {
        Image(nsImage: DockShelfIdentity.appIcon)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.18), radius: size * 0.10, x: 0, y: size * 0.05)
    }
}

struct DockShelfMenuBarSymbolView: View {
    var body: some View {
        Image(systemName: "square.grid.2x2")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 26, height: 22)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}
