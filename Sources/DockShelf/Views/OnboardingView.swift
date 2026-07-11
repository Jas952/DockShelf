import AVFoundation
import AppKit
import SwiftUI

struct OnboardingView: View {
    static let windowSize = NSSize(width: 500, height: 350)

    let demoURL: URL?
    let cancel: () -> Void
    let finish: () -> Void

    @State private var step: Step = .welcome
    @Namespace private var iconNamespace
    private let contentWidth: CGFloat = 320
    private let videoSize = CGSize(width: 128, height: 230)

    var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 26)
                .padding(.vertical, 18)

            Divider()

            footer
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .frame(width: Self.windowSize.width, height: Self.windowSize.height)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            welcomeStep
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
        case .demo:
            demoStep
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 14) {
            DockShelfAppIconView(size: 78)
                .matchedGeometryEffect(id: "appIcon", in: iconNamespace)

            VStack(spacing: 8) {
                Text("DockShelf is running in the background")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text("You won’t see a Dock icon. Use the DockShelf icon in the menu bar to show the launcher, open settings, or quit the app.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: contentWidth)

            HStack(spacing: 12) {
                DockShelfMenuBarSymbolView()

                Text("Look for this icon in the menu bar.")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .frame(width: contentWidth)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var demoStep: some View {
        HStack(alignment: .center, spacing: 22) {
            demoVideo

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Open DockShelf from the menu bar")
                        .font(.headline.weight(.semibold))
                        .multilineTextAlignment(.leading)

                    Text("The menu bar icon gives you access to the launcher and settings while the app stays out of the Dock.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 18)

                VStack(spacing: 8) {
                    DockShelfAppIconView(size: 104)
                        .matchedGeometryEffect(id: "appIcon", in: iconNamespace)

                    Text("Latest \(DockShelfIdentity.versionText)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(width: 250, height: videoSize.height, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var demoVideo: some View {
        Group {
            if let demoURL {
                LoopingVideoView(url: demoURL)
            } else {
                missingVideoPlaceholder
            }
        }
        .frame(width: videoSize.width, height: videoSize.height)
        .background(.black.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
    }

    private var missingVideoPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "play.rectangle")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(.secondary)

            Text("Demo video unavailable")
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Button("Cancel", role: .cancel) {
                cancel()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            switch step {
            case .welcome:
                Button("Next") {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
                        step = .demo
                    }
                }
                .keyboardShortcut(.defaultAction)

            case .demo:
                Button("Done") {
                    finish()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}

private enum Step {
    case welcome
    case demo
}

private struct LoopingVideoView: NSViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> LoopingVideoNSView {
        let view = LoopingVideoNSView()
        context.coordinator.configure(url: url, in: view)
        return view
    }

    func updateNSView(_ nsView: LoopingVideoNSView, context: Context) {
        context.coordinator.configure(url: url, in: nsView)
    }

    static func dismantleNSView(_ nsView: LoopingVideoNSView, coordinator: Coordinator) {
        coordinator.stop()
        nsView.playerLayer.player = nil
    }

    final class Coordinator {
        private var currentURL: URL?
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?

        func configure(url: URL, in view: LoopingVideoNSView) {
            guard currentURL != url else {
                return
            }

            currentURL = url
            let player = AVQueuePlayer()
            player.isMuted = true
            player.actionAtItemEnd = .none

            let item = AVPlayerItem(url: url)
            looper = AVPlayerLooper(player: player, templateItem: item)
            self.player = player
            view.playerLayer.player = player
            player.play()
        }

        func stop() {
            player?.pause()
            player = nil
            looper = nil
            currentURL = nil
        }
    }
}

private final class LoopingVideoNSView: NSView {
    let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        playerLayer.videoGravity = .resizeAspect
        layer?.addSublayer(playerLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}
