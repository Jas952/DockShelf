import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var coordinator: AppCoordinator
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Show Panel") {
            coordinator.toggleLauncher()
        }
        .keyboardShortcut(" ", modifiers: [.option])

        Button("Settings") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "settings")
        }

        Button("Welcome") {
            coordinator.showWelcomeWindow()
        }

        Button("About DockShelf") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "about")
        }

        Divider()

        Button("Quit DockShelf") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
