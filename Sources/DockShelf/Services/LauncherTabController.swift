import AppKit
import SwiftUI

final class LauncherTabController {
    private let launcherPanelController: LauncherPanelController
    private let settings: LauncherSettings
    private var panel: NSPanel?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    init(launcherPanelController: LauncherPanelController, settings: LauncherSettings) {
        self.launcherPanelController = launcherPanelController
        self.settings = settings
    }

    func show() {
        if panel == nil {
            let rootView = LauncherTabView(
                clickAction: { [weak self] in
                    guard let self, self.settings.activationMode == .click else {
                        return
                    }

                    self.launcherPanelController.toggle()
                },
                hoverAction: { [weak self] in
                    guard let self, self.settings.activationMode == .hover else {
                        return
                    }

                    self.launcherPanelController.show()
                }
            )

            let panel = NSPanel(
                contentRect: tabFrame(),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.title = "DockShelf Tab"
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.hidesOnDeactivate = false
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: rootView)
            self.panel = panel
        }

        startMouseMonitoringIfNeeded()
        panel?.setFrame(tabFrame(), display: true)
        updateVisibilityForCurrentMouseLocation()
    }

    private func tabFrame() -> CGRect {
        let screen = NSScreen.main
        let screenFrame = screen?.frame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visible = screen?.visibleFrame ?? screenFrame
        let width: CGFloat = 22
        let height: CGFloat = 30
        let bottomDockHeight = max(0, visible.minY - screenFrame.minY)
        let y: CGFloat

        if bottomDockHeight > height + 12 {
            y = screenFrame.minY + (bottomDockHeight - height) / 2
        } else {
            y = visible.minY + 4
        }

        return CGRect(
            x: screenFrame.maxX - width - 34,
            y: y,
            width: width,
            height: height
        )
    }

    private func startMouseMonitoringIfNeeded() {
        guard globalMouseMonitor == nil, localMouseMonitor == nil else {
            return
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] _ in
            self?.updateVisibilityForCurrentMouseLocation()
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { [weak self] event in
            self?.updateVisibilityForCurrentMouseLocation()
            return event
        }
    }

    private func updateVisibilityForCurrentMouseLocation() {
        guard let panel else {
            return
        }

        panel.setFrame(tabFrame(), display: true)

        if isMouseInDockAnimationZone() {
            panel.orderOut(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    private func isMouseInDockAnimationZone() -> Bool {
        guard let screen = NSScreen.main, let panel else {
            return false
        }

        let visible = screen.visibleFrame
        let screenFrame = screen.frame
        let mouse = NSEvent.mouseLocation

        guard visible.minY > screenFrame.minY + 8 else {
            return false
        }

        if panel.frame.insetBy(dx: -12, dy: -12).contains(mouse) {
            return false
        }

        return mouse.y < visible.minY && mouse.x < panel.frame.minX - 16
    }
}
