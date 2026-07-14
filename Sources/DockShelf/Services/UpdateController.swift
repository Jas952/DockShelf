import Combine
import Foundation
import Sparkle

final class UpdateController: ObservableObject {
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    @Published private(set) var isReady = false

    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    var automaticallyDownloadsUpdates: Bool {
        get { updaterController.updater.automaticallyDownloadsUpdates }
        set { updaterController.updater.automaticallyDownloadsUpdates = newValue }
    }

    func start() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.start()
            }
            return
        }

        guard !isReady else {
            return
        }

        do {
            try updaterController.updater.start()
            isReady = true
        } catch {
            NSLog("DockShelf updater failed to start: \(error.localizedDescription)")
        }
    }

    func checkForUpdates() {
        guard isReady, updaterController.updater.canCheckForUpdates else {
            return
        }

        updaterController.checkForUpdates(nil)
    }
}
