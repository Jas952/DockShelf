import Foundation

enum LauncherActivationMode: String, CaseIterable, Identifiable {
    case click
    case hover

    var id: String { rawValue }

    var title: String {
        switch self {
        case .click:
            return "По нажатию"
        case .hover:
            return "При наведении"
        }
    }
}

enum LauncherPanelAnchor: String, CaseIterable, Identifiable {
    case top
    case middle
    case bottom

    var id: String { rawValue }
}

final class LauncherSettings: ObservableObject {
    @Published var activationMode: LauncherActivationMode {
        didSet {
            UserDefaults.standard.set(activationMode.rawValue, forKey: activationModeKey)
        }
    }

    @Published var panelAnchor: LauncherPanelAnchor {
        didSet {
            UserDefaults.standard.set(panelAnchor.rawValue, forKey: panelAnchorKey)
        }
    }

    private let activationModeKey = "dockShelf.launcherActivationMode.v1"
    private let panelAnchorKey = "dockShelf.launcherPanelAnchor.v1"

    init() {
        let activationRawValue = UserDefaults.standard.string(forKey: activationModeKey)
        let anchorRawValue = UserDefaults.standard.string(forKey: panelAnchorKey)

        activationMode = activationRawValue.flatMap(LauncherActivationMode.init(rawValue:)) ?? .click
        panelAnchor = anchorRawValue.flatMap(LauncherPanelAnchor.init(rawValue:)) ?? .bottom
    }
}
