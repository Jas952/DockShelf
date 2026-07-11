import AppKit
import Combine
import Foundation

final class AppCoordinator: ObservableObject {
    let store: ShelfStore
    let launcherSettings: LauncherSettings
    let loginItemService: LoginItemService
    let launcherPanelController: LauncherPanelController
    let launcherTabController: LauncherTabController

    private let hotKeyManager: HotKeyManager
    private let onboardingWindowController = OnboardingWindowController()
    private var cancellables: Set<AnyCancellable> = []

    init() {
        let store = ShelfStore()
        let launcherSettings = LauncherSettings()
        self.store = store
        self.launcherSettings = launcherSettings
        self.loginItemService = LoginItemService()
        self.launcherPanelController = LauncherPanelController(store: store, settings: launcherSettings)
        self.launcherTabController = LauncherTabController(
            launcherPanelController: launcherPanelController,
            settings: launcherSettings
        )
        self.hotKeyManager = HotKeyManager {}

        let launcherPanelController = self.launcherPanelController
        hotKeyManager.registerOptionSpace {
            DispatchQueue.main.async {
                launcherPanelController.toggle()
            }
        }

        DispatchQueue.main.async {
            self.launcherTabController.show()
            self.onboardingWindowController.showAtLaunch()
        }
    }

    func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
    }

    func syncAgentsFolder() {
        do {
            try DockStackService.syncAgentsFolder(for: store.groups)
            DockStackService.revealAgentsFolder()
        } catch {
            NSLog("DockShelf failed to sync agents folder: \(error.localizedDescription)")
        }
    }

    func toggleLauncher() {
        launcherPanelController.toggle()
    }

    func showLauncher() {
        launcherPanelController.show()
    }

    func showWelcomeWindow() {
        onboardingWindowController.showManually()
    }
}
