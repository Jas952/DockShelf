import AppKit
import Foundation

final class ShelfStore: ObservableObject {
    @Published var groups: [ShelfGroup] {
        didSet {
            repairSelectedGroup()
            save()
        }
    }
    @Published var selectedGroupID: ShelfGroup.ID? {
        didSet {
            UserDefaults.standard.set(selectedGroupID?.uuidString, forKey: selectedGroupKey)
        }
    }

    private let defaultsKey = "dockShelf.groups.v1"
    private let selectedGroupKey = "dockShelf.selectedGroup.v1"
    private let seededDevinKey = "dockShelf.seededDevin.v2"

    init() {
        if
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let decoded = try? JSONDecoder().decode([ShelfGroup].self, from: data),
            !decoded.isEmpty
        {
            groups = decoded
        } else {
            groups = ShelfGroup.sampleData
        }

        let selectedGroupString = UserDefaults.standard.string(forKey: selectedGroupKey)
        selectedGroupID = selectedGroupString.flatMap(UUID.init(uuidString:))
        repairSelectedGroup()
        repairApplicationLinks()
        seedDevinIfNeeded()
        save()
    }

    func addGroup() {
        let nextX = (groups.map(\.xPosition).max() ?? 360) + 220
        groups.append(ShelfGroup(title: "Новая группа", xPosition: nextX))
        selectedGroupID = groups.last?.id
    }

    func removeGroups(at offsets: IndexSet) {
        groups.remove(atOffsets: offsets)
    }

    func reset() {
        groups = ShelfGroup.sampleData
        selectedGroupID = groups.first?.id
    }

    var allApps: [ShelfApp] {
        var seen: Set<String> = []
        var apps: [ShelfApp] = []

        for app in groups.flatMap(\.apps) {
            let key = app.bundleIdentifier ?? app.path
            guard !seen.contains(key) else {
                continue
            }

            seen.insert(key)
            apps.append(app)
        }

        return apps
    }

    var selectedGroup: ShelfGroup? {
        guard let selectedGroupID else {
            return groups.first
        }

        return groups.first(where: { $0.id == selectedGroupID }) ?? groups.first
    }

    var selectedApps: [ShelfApp] {
        selectedGroup?.apps ?? []
    }

    var selectedTitle: String {
        get {
            selectedGroup?.title ?? "Agents"
        }
        set {
            ensureSelectedGroup()
            guard let index = selectedGroupIndex else {
                return
            }

            groups[index].title = newValue
        }
    }

    @discardableResult
    func addApps(at urls: [URL], to groupID: ShelfGroup.ID? = nil) -> Int {
        let appURLs = urls.filter(Self.isApplicationBundle)
        guard !appURLs.isEmpty else {
            return 0
        }

        let targetIndex: Array<ShelfGroup>.Index?
        if let groupID, let index = groups.firstIndex(where: { $0.id == groupID }) {
            targetIndex = index
        } else {
            ensureSelectedGroup()
            targetIndex = selectedGroupIndex
        }

        guard let targetIndex else {
            return 0
        }

        let existingKeys = Set(groups[targetIndex].apps.map { $0.bundleIdentifier ?? $0.path })
        let newApps = appURLs
            .map { url in
                ShelfApp(name: Self.appName(for: url), path: url.path)
            }
            .filter { !existingKeys.contains($0.bundleIdentifier ?? $0.path) }

        guard !newApps.isEmpty else {
            return 0
        }

        var updatedGroups = groups
        updatedGroups[targetIndex].apps.append(contentsOf: newApps)
        updatedGroups[targetIndex].fitWidthToApps()
        groups = updatedGroups

        return newApps.count
    }

    func selectGroup(_ group: ShelfGroup) {
        selectedGroupID = group.id
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(groups) else {
            return
        }

        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private var selectedGroupIndex: Array<ShelfGroup>.Index? {
        guard let selectedGroupID else {
            return groups.indices.first
        }

        return groups.firstIndex(where: { $0.id == selectedGroupID }) ?? groups.indices.first
    }

    private func ensureSelectedGroup() {
        if groups.isEmpty {
            groups.append(ShelfGroup(title: "Apps", xPosition: 390))
        }

        repairSelectedGroup()
    }

    private func repairSelectedGroup() {
        if let selectedGroupID, groups.contains(where: { $0.id == selectedGroupID }) {
            return
        }

        selectedGroupID = groups.first?.id
    }

    private func repairApplicationLinks() {
        guard !groups.isEmpty else {
            return
        }

        let devinURL = Self.firstExistingDevinURL()

        for groupIndex in groups.indices {
            for appIndex in groups[groupIndex].apps.indices {
                let app = groups[groupIndex].apps[appIndex]

                if Self.isDevinLike(app), let devinURL {
                    groups[groupIndex].apps[appIndex] = ShelfApp(
                        id: app.id,
                        name: Self.appName(for: devinURL),
                        path: devinURL.path
                    )
                    continue
                }

                if app.bundleIdentifier == nil, FileManager.default.fileExists(atPath: app.path) {
                    groups[groupIndex].apps[appIndex] = ShelfApp(
                        id: app.id,
                        name: app.name,
                        path: app.path
                    )
                }
            }
        }
    }

    private func seedDevinIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seededDevinKey) else {
            return
        }

        if groups.isEmpty {
            groups.append(ShelfGroup(title: "Apps", xPosition: 390))
        }

        if groups.flatMap(\.apps).contains(where: Self.isDevinLike) {
            UserDefaults.standard.set(true, forKey: seededDevinKey)
            return
        }

        if let url = Self.firstExistingDevinURL() {
            groups[0].apps.append(ShelfApp(name: Self.appName(for: url), path: url.path))
            groups[0].fitWidthToApps()
        }

        UserDefaults.standard.set(true, forKey: seededDevinKey)
    }

    private static func isApplicationBundle(_ url: URL) -> Bool {
        if url.pathExtension.localizedCaseInsensitiveCompare("app") == .orderedSame {
            return true
        }

        return (try? url.resourceValues(forKeys: [.isApplicationKey]).isApplication) == true
    }

    private static func appName(for url: URL) -> String {
        if
            let bundle = Bundle(url: url),
            let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        {
            return displayName
        }

        if
            let bundle = Bundle(url: url),
            let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
        {
            return name
        }

        return url.deletingPathExtension().lastPathComponent
    }

    private static func isDevinLike(_ app: ShelfApp) -> Bool {
        let values = [
            app.name,
            URL(fileURLWithPath: app.path).deletingPathExtension().lastPathComponent,
            app.bundleIdentifier ?? ""
        ]
        .map { $0.lowercased() }

        return values.contains("devin")
            || values.contains("devine")
            || values.contains("divine")
            || values.contains("com.exafunction.windsurf")
    }

    private static func firstExistingDevinURL() -> URL? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.exafunction.windsurf") {
            return url
        }

        let homeApplications = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications")
            .path
        let roots = ["/Applications", "/System/Applications", homeApplications]
        let names = ["Devin.app", "Devine.app", "Divine.app"]

        for root in roots {
            for name in names {
                let url = URL(fileURLWithPath: root).appendingPathComponent(name)
                let path = url.path
                if FileManager.default.fileExists(atPath: path) {
                    return url
                }
            }
        }

        return nil
    }
}
