import AppKit
import SwiftUI

struct AboutView: View {
    @ObservedObject var updateController: UpdateController

    var body: some View {
        VStack(spacing: 14) {
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

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Updates")
                    .font(.headline)

                Toggle(
                    "Automatically check for updates",
                    isOn: Binding(
                        get: { updateController.automaticallyChecksForUpdates },
                        set: { updateController.automaticallyChecksForUpdates = $0 }
                    )
                )

                Toggle(
                    "Automatically download updates",
                    isOn: Binding(
                        get: { updateController.automaticallyDownloadsUpdates },
                        set: { updateController.automaticallyDownloadsUpdates = $0 }
                    )
                )

                HStack {
                    Spacer()

                    Button("Check for Updates…") {
                        updateController.checkForUpdates()
                    }
                    .disabled(!updateController.isReady)
                }
                .padding(.top, 2)
            }
            .font(.callout)
        }
        .padding(24)
        .frame(width: 330, height: 330)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
