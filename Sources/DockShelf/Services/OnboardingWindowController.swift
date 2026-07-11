import AppKit
import SwiftUI

final class OnboardingWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private var isCompleting = false
    private var terminatesOnClose = true

    func showAtLaunch() {
        show(terminatesOnClose: true)
    }

    func showManually() {
        show(terminatesOnClose: false)
    }

    private func show(terminatesOnClose: Bool) {
        self.terminatesOnClose = terminatesOnClose

        if let window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }

        let view = OnboardingView(
            demoURL: Bundle.main.url(forResource: "OnboardingDemo", withExtension: "mov"),
            cancel: { [weak self] in
                self?.cancel()
            },
            finish: { [weak self] in
                self?.complete()
            }
        )

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: OnboardingView.windowSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to DockShelf"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.contentView = NSHostingView(rootView: view)
        window.center()
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func cancel() {
        if terminatesOnClose {
            NSApp.terminate(nil)
        } else {
            closeWithoutTerminating()
        }
    }

    private func complete() {
        closeWithoutTerminating()
    }

    private func closeWithoutTerminating() {
        isCompleting = true
        window?.close()
        window = nil
        isCompleting = false
    }

    func windowWillClose(_ notification: Notification) {
        window = nil

        if terminatesOnClose && !isCompleting {
            NSApp.terminate(nil)
        }
    }
}
