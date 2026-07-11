import AppKit
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            DockShelfAppIconView(size: 72)

            VStack(spacing: 4) {
                Text("DockShelf")
                    .font(.title3.weight(.semibold))

                Text(DockShelfIdentity.versionText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Text("A background launcher for grouped apps.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 280, height: 220)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
