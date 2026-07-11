import SwiftUI

struct LauncherTabView: View {
    let clickAction: () -> Void
    let hoverAction: () -> Void

    var body: some View {
        Button {
            clickAction()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            if isHovering {
                hoverAction()
            }
        }
        .help("DockShelf")
    }
}
