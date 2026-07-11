import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store: ShelfStore
    @ObservedObject var launcherSettings: LauncherSettings
    @ObservedObject var loginItemService: LoginItemService

    @State private var selection: ShelfGroup.ID?
    @State private var statusMessage: String?

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let binding = selectedGroupBinding {
                GroupEditorView(
                    store: store,
                    launcherSettings: launcherSettings,
                    loginItemService: loginItemService,
                    statusMessage: $statusMessage,
                    group: binding
                )
            } else {
                EmptySelectionView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openApplicationsFolder()
                } label: {
                    Image(systemName: "folder")
                }
                .help("Открыть Applications")
                .accessibilityLabel("Открыть Applications")
            }
        }
        .onAppear {
            selection = selection ?? store.selectedGroupID ?? store.groups.first?.id
        }
        .onChange(of: selection) { groupID in
            store.selectedGroupID = groupID
        }
        .onChange(of: store.selectedGroupID) { groupID in
            selection = groupID
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(store.groups) { group in
                    Label(group.title, systemImage: "folder")
                        .tag(group.id)
                }
                .onDelete { offsets in
                    store.removeGroups(at: offsets)
                    selection = store.groups.first?.id
                }
            }
            .listStyle(.sidebar)

            Divider()

            HStack {
                Button {
                    store.addGroup()
                    selection = store.groups.last?.id
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 22)
                }
                .help("Добавить категорию")

                Button {
                    removeSelectedGroup()
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 24, height: 22)
                }
                .disabled(selection == nil || store.groups.count <= 1)
                .help("Удалить выбранную категорию")

                Spacer()
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .navigationTitle("Категории")
        .navigationSplitViewColumnWidth(min: 176, ideal: 176, max: 176)
    }

    private var selectedGroupBinding: Binding<ShelfGroup>? {
        guard let selection, let index = store.groups.firstIndex(where: { $0.id == selection }) else {
            return nil
        }

        return $store.groups[index]
    }

    private func syncDockStacks() {
        do {
            try DockStackService.syncStacks(for: store.groups)
            DockStackService.revealStacksFolder()
            statusMessage = "Dock-папки обновлены. Перетащите нужную папку в Dock."
        } catch {
            statusMessage = "Не удалось обновить Dock-папки: \(error.localizedDescription)"
        }
    }

    private func openApplicationsFolder() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications", isDirectory: true))
    }

    private func removeSelectedGroup() {
        guard let selection, store.groups.count > 1 else {
            return
        }

        store.groups.removeAll { $0.id == selection }
        self.selection = store.groups.first?.id
    }

    private func syncAgentsFolder() {
        do {
            try DockStackService.syncAgentsFolder(for: store.groups)
            DockStackService.revealAgentsFolder()
            statusMessage = "DockShelf Agents обновлена. Перетащите папку в правую часть Dock."
        } catch {
            statusMessage = "Не удалось обновить Agents-папку: \(error.localizedDescription)"
        }
    }
}

private struct EmptySelectionView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(.secondary)

            Text("Выберите категорию")
                .font(.title3.weight(.semibold))

            Text("Добавьте приложения, чтобы они появились в DockShelf Agents.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct GroupEditorView: View {
    @ObservedObject var store: ShelfStore
    @ObservedObject var launcherSettings: LauncherSettings
    @ObservedObject var loginItemService: LoginItemService
    @Binding var statusMessage: String?
    @Binding var group: ShelfGroup
    @State private var appPickerStatus: String?
    @State private var isEditingTitle = false
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            compactSettingsBar
            appsSection
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(group.title)
    }

    private var compactSettingsBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                titleEditor
                    .frame(minWidth: 120, idealWidth: 180, maxWidth: 240, alignment: .leading)

                Spacer(minLength: 16)

                Toggle("Автозапуск", isOn: Binding(
                    get: { loginItemService.isEnabled },
                    set: { enabled in
                        do {
                            try loginItemService.setEnabled(enabled)
                            statusMessage = enabled ? "Автозапуск включен." : "Автозапуск выключен."
                        } catch {
                            statusMessage = "Не удалось изменить автозапуск: \(error.localizedDescription)"
                        }
                    }
                ))
                .toggleStyle(.checkbox)
                .fixedSize(horizontal: true, vertical: false)
                .help("Автозапуск при входе")

                Spacer()
                    .frame(width: 22)

                Picker("Вызов", selection: $launcherSettings.activationMode) {
                    ForEach(LauncherActivationMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 190)
                .layoutPriority(1)
            }

            if let compactStatus {
                Text(compactStatus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var compactStatus: String? {
        appPickerStatus ?? statusMessage
    }

    @ViewBuilder
    private var titleEditor: some View {
        if isEditingTitle {
            TextField("Название", text: $group.title)
                .textFieldStyle(.plain)
                .font(.body.weight(.semibold))
                .focused($isTitleFocused)
                .onSubmit {
                    isEditingTitle = false
                }
                .onAppear {
                    isTitleFocused = true
                }
        } else {
            Button {
                isEditingTitle = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text(group.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Нажмите, чтобы переименовать")
        }
    }

    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Приложения")
                    .font(.headline)

                Spacer()

                Button {
                    pickApps()
                } label: {
                    Label("Добавить", systemImage: "app.badge.plus")
                }

                Button {
                    DockStackService.revealAgentsFolder()
                } label: {
                    Label("Папка", systemImage: "folder")
                }
            }

            VStack(spacing: 0) {
                if group.apps.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 30, weight: .regular))
                            .foregroundStyle(.secondary)

                        Text("Нет приложений")
                            .font(.headline)

                        Text("Добавьте приложения в эту категорию.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 220)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(group.apps) { app in
                                AppRow(app: app) {
                                    AppLauncher.open(app)
                                } removeAction: {
                                    group.apps.removeAll { $0.id == app.id }
                                }

                                if app.id != group.apps.last?.id {
                                    Divider()
                                        .padding(.leading, 54)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func pickApps() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Выберите одно или несколько приложений для категории \(group.title)."
        panel.prompt = "Добавить"
        panel.resolvesAliases = true
        panel.treatsFilePackagesAsDirectories = false

        NSApp.activate(ignoringOtherApps: true)

        if panel.runModal() == .OK {
            let addedCount = store.addApps(at: panel.urls, to: group.id)
            store.selectedGroupID = group.id
            appPickerStatus = addedCount == 0
                ? "Ничего не добавлено: приложения уже есть в этой категории или выбран не .app bundle."
                : "Добавлено приложений: \(addedCount)."
        }
    }
}

private struct AppRow: View {
    let app: ShelfApp
    let openAction: () -> Void
    let removeAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            AppIconImage(app: app)
                .frame(width: 28, height: 28)

            Text(app.name)
                .font(.body.weight(.medium))
                .lineLimit(1)
                .help(app.path)

            Spacer()

            Button {
                openAction()
            } label: {
                Image(systemName: "play")
            }
            .buttonStyle(.borderless)
            .help("Открыть приложение")

            Button(role: .destructive) {
                removeAction()
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .help("Убрать из категории")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }
}
