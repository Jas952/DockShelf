import SwiftUI

@main
struct DockShelfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        MenuBarExtra("DockShelf", systemImage: "square.grid.2x2") {
            MenuBarContentView(coordinator: coordinator)
        }
        .menuBarExtraStyle(.menu)

        Window("DockShelf Settings", id: "settings") {
            ContentView(
                store: coordinator.store,
                launcherSettings: coordinator.launcherSettings,
                loginItemService: coordinator.loginItemService
            )
                .frame(minWidth: 780, minHeight: 520)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Window("About DockShelf", id: "about") {
            AboutView(updateController: coordinator.updateController)
        }
        .windowResizability(.contentSize)
    }
}
