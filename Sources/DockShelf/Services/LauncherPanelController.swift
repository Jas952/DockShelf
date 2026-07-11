import AppKit
import Combine
import QuartzCore
import SwiftUI

final class LauncherPanelController: ObservableObject {
    private let store: ShelfStore
    private let settings: LauncherSettings
    private var panel: NSPanel?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var closeWorkItem: DispatchWorkItem?
    private var dragPreviewAnchor: LauncherPanelAnchor?
    private var cancellables: Set<AnyCancellable> = []
    private let width: CGFloat = LauncherPanelView.preferredWidth
    private let edgePadding: CGFloat = 14

    init(store: ShelfStore, settings: LauncherSettings) {
        self.store = store
        self.settings = settings
        observeStoreChanges()
    }

    func toggle() {
        if panel?.isVisible == true {
            close()
        } else {
            show()
        }
    }

    func show() {
        closeWorkItem?.cancel()
        closeWorkItem = nil

        if panel == nil {
            let rootView = LauncherPanelView(
                store: store,
                launch: { [weak self] app in
                    AppLauncher.open(app)
                    self?.close()
                },
                close: { [weak self] in
                    self?.close()
                },
                beginPanelDrag: { [weak self] in
                    self?.beginPanelDrag()
                },
                updatePanelDrag: { [weak self] in
                    self?.updatePanelDrag()
                },
                endPanelDrag: { [weak self] in
                    self?.endPanelDrag()
                }
            )

            let panel = NSPanel(
                contentRect: hiddenFrame(),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.title = "DockShelf"
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.hidesOnDeactivate = false
            panel.level = .floating
            panel.animationBehavior = .none
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: rootView)
            self.panel = panel
        }

        startOutsideClickMonitoringIfNeeded()

        guard let panel else {
            return
        }

        if panel.isVisible {
            panel.setFrame(visibleFrame(), display: true, animate: false)
            panel.orderFrontRegardless()
            return
        }

        panel.setFrame(hiddenFrame(), display: false, animate: false)
        panel.orderFrontRegardless()
        panel.animator().setFrame(visibleFrame(), display: true)
    }

    func beginPanelDrag() {
        closeWorkItem?.cancel()
        closeWorkItem = nil
        dragPreviewAnchor = settings.panelAnchor
    }

    func updatePanelDrag() {
        guard let panel, panel.isVisible else {
            return
        }

        let targetAnchor = nearestAnchor(toScreenY: NSEvent.mouseLocation.y)
        guard targetAnchor != dragPreviewAnchor else {
            return
        }

        dragPreviewAnchor = targetAnchor
        animatePanel(to: visibleFrame(for: targetAnchor), duration: 0.12)
    }

    func endPanelDrag() {
        guard panel?.isVisible == true else {
            return
        }

        let targetAnchor = nearestAnchor(toScreenY: NSEvent.mouseLocation.y)
        settings.panelAnchor = targetAnchor
        animatePanel(to: visibleFrame(for: targetAnchor), duration: 0.18)
        dragPreviewAnchor = nil
    }

    func close() {
        guard let panel else {
            return
        }

        closeWorkItem?.cancel()
        panel.animator().setFrame(hiddenFrame(), display: true)

        let workItem = DispatchWorkItem { [weak self, weak panel] in
            guard let self, panel === self.panel else {
                return
            }

            panel?.orderOut(nil)
            self.closeWorkItem = nil
        }

        closeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: workItem)
    }

    private func visibleFrame(for anchor: LauncherPanelAnchor? = nil) -> CGRect {
        let visible = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let maxHeight = min(visible.height - 56, 620)
        let appCount = max(store.groups.map { $0.apps.count }.max() ?? 0, store.selectedApps.count)
        let headerHeight: CGFloat = 30
        let contentHeight: CGFloat

        if appCount == 0 {
            contentHeight = 7 + headerHeight + 8 + 78 + 7
        } else {
            let appRowsHeight = CGFloat(appCount) * 64 + CGFloat(max(appCount - 1, 0)) * 10
            contentHeight = 7 + headerHeight + 6 + appRowsHeight + 13
        }

        let height = min(max(contentHeight, 94), maxHeight)
        let y = originY(for: anchor ?? settings.panelAnchor, height: height, visibleFrame: visible)

        return CGRect(
            x: visible.maxX - width - edgePadding,
            y: y,
            width: width,
            height: height
        )
    }

    private func hiddenFrame() -> CGRect {
        var frame = visibleFrame()
        frame.origin.x = (NSScreen.main?.visibleFrame.maxX ?? frame.maxX) + 8
        return frame
    }

    private func originY(for anchor: LauncherPanelAnchor, height: CGFloat, visibleFrame: CGRect) -> CGFloat {
        let minY = visibleFrame.minY + 8
        let maxY = visibleFrame.maxY - height - 18
        let rawY: CGFloat

        switch anchor {
        case .top:
            rawY = maxY
        case .middle:
            rawY = visibleFrame.midY - height / 2
        case .bottom:
            rawY = visibleFrame.minY + 40
        }

        return max(minY, min(rawY, maxY))
    }

    private func nearestAnchor(toScreenY screenY: CGFloat) -> LauncherPanelAnchor {
        LauncherPanelAnchor.allCases.min { left, right in
            abs(visibleFrame(for: left).midY - screenY) < abs(visibleFrame(for: right).midY - screenY)
        } ?? .bottom
    }

    private func animatePanel(to frame: CGRect, duration: TimeInterval) {
        guard let panel else {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        }
    }

    private func startOutsideClickMonitoringIfNeeded() {
        guard globalClickMonitor == nil, localClickMonitor == nil else {
            return
        }

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closeIfClickIsOutsidePanel()
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.closeIfClickIsOutsidePanel()
            return event
        }
    }

    private func closeIfClickIsOutsidePanel() {
        guard let panel, panel.isVisible else {
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        guard !panel.frame.contains(mouseLocation) else {
            return
        }

        close()
    }

    private func observeStoreChanges() {
        store.$groups
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateVisibleFrame()
            }
            .store(in: &cancellables)

        store.$selectedGroupID
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateVisibleFrame()
            }
            .store(in: &cancellables)
    }

    private func updateVisibleFrame() {
        guard let panel, panel.isVisible else {
            return
        }

        panel.setFrame(visibleFrame(), display: true, animate: false)
    }
}
