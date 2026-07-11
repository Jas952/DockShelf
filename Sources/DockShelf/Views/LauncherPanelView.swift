import SwiftUI

struct LauncherPanelView: View {
    static let coreWidth: CGFloat = 90
    static let categoryListWidth: CGFloat = 148
    static let preferredWidth: CGFloat = coreWidth + categoryListWidth

    @ObservedObject var store: ShelfStore
    let launch: (ShelfApp) -> Void
    let close: () -> Void
    let beginPanelDrag: () -> Void
    let updatePanelDrag: () -> Void
    let endPanelDrag: () -> Void

    @State private var isDropTargeted = false
    @State private var showsCategoryFan = false
    @State private var appListOpacity = 1.0
    @State private var categoryAnimationToken = UUID()
    @State private var hoverDismissToken = UUID()
    @State private var isPanelHovered = false
    @State private var isDraggingPanel = false

    private var visibleApps: [ShelfApp] {
        store.selectedApps
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                CategoryListView(
                    groups: store.groups,
                    selectedGroupID: store.selectedGroupID,
                    select: { group in
                        withAnimation(.easeInOut(duration: 0.16)) {
                            store.selectGroup(group)
                        }
                    }
                )
                .frame(width: Self.categoryListWidth, height: proxy.size.height)
                .offset(x: showsCategoryFan ? 0 : Self.categoryListWidth - 22)
                .opacity(showsCategoryFan ? 1 : 0)
                .allowsHitTesting(showsCategoryFan)
                .accessibilityHidden(!showsCategoryFan)
                .animation(.easeOut(duration: 0.20), value: showsCategoryFan)

                ZStack {
                    corePanel

                    AppDropTargetView(
                        onTargeted: { targeted in
                            withAnimation(.easeInOut(duration: 0.18)) {
                                isDropTargeted = targeted
                            }
                        },
                        onDrop: { urls in
                            withAnimation(.easeInOut(duration: 0.20)) {
                                store.addApps(at: urls)
                                isDropTargeted = false
                            }
                        }
                    )
                }
                .frame(width: Self.coreWidth)
            }
            .frame(width: Self.preferredWidth, height: proxy.size.height, alignment: .trailing)
        }
        .frame(width: Self.preferredWidth)
        .contentShape(Rectangle())
        .onHover { hovering in
            handlePanelHover(hovering)
        }
        .onChange(of: store.selectedGroupID) { _ in
            softenAppListChange()
        }
        .onChange(of: store.selectedApps) { _ in
            softenAppListChange()
        }
    }

    private var corePanel: some View {
        VStack(spacing: visibleApps.isEmpty ? 8 : 6) {
            headerArea

            if visibleApps.isEmpty {
                dropSlot
            } else if isDropTargeted {
                insertMarker
            }

            appList
                .opacity(appListOpacity)
                .scaleEffect(appListOpacity < 1 ? 0.985 : 1, anchor: .top)
                .animation(.easeInOut(duration: 0.18), value: isDropTargeted)
                .animation(.easeInOut(duration: 0.22), value: appListOpacity)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 7)
        .frame(width: Self.coreWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.12),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private var headerArea: some View {
        VStack(spacing: 3) {
            titleField
            dragHandle
        }
        .frame(width: 78)
        .contentShape(Rectangle())
        .highPriorityGesture(panelSnapDragGesture)
    }

    private var titleField: some View {
        Button {
            toggleCategoryList()
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 12, height: 18)

                Text(store.selectedTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                .frame(width: 60, alignment: .center)
            }
            .frame(width: 78, height: 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Показать категории")
    }

    private var dragHandle: some View {
        Capsule(style: .continuous)
            .fill(isDraggingPanel ? Color.accentColor.opacity(0.65) : Color.secondary.opacity(0.36))
            .frame(width: 28, height: 3)
            .frame(width: 78, height: 9)
            .contentShape(Rectangle())
            .help("Потяните вверх или вниз для привязки панели")
    }

    private var panelSnapDragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { _ in
                if !isDraggingPanel {
                    isDraggingPanel = true
                    hoverDismissToken = UUID()
                    beginPanelDrag()
                }

                updatePanelDrag()
            }
            .onEnded { _ in
                guard isDraggingPanel else {
                    return
                }

                endPanelDrag()
                isDraggingPanel = false
            }
    }

    private func toggleCategoryList() {
        withAnimation(.easeInOut(duration: 0.16)) {
            showsCategoryFan.toggle()
        }
    }

    private func handlePanelHover(_ hovering: Bool) {
        isPanelHovered = hovering
        hoverDismissToken = UUID()

        guard !hovering else {
            return
        }

        let token = hoverDismissToken
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard hoverDismissToken == token, !isPanelHovered, !isDropTargeted, !isDraggingPanel else {
                return
            }

            withAnimation(.easeInOut(duration: 0.14)) {
                showsCategoryFan = false
            }

            close()
        }
    }

    private var dropSlot: some View {
        RoundedRectangle(cornerRadius: 13, style: .continuous)
            .stroke(
                isDropTargeted ? Color.accentColor.opacity(0.75) : Color.secondary.opacity(0.45),
                style: StrokeStyle(lineWidth: 1.4, dash: [5, 4])
            )
            .frame(width: 78, height: 78)
            .overlay {
                Image(systemName: "app.dashed")
                    .font(.system(size: 31, weight: .regular))
                    .foregroundStyle(isDropTargeted ? Color.accentColor : Color.secondary)
            }
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(isDropTargeted ? Color.accentColor.opacity(0.10) : Color.primary.opacity(0.035))
            )
            .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .help("Перетащите сюда приложение")
    }

    private var insertMarker: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color.accentColor.opacity(0.10))
            .frame(width: 78, height: 64)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        Color.accentColor.opacity(0.45),
                        style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                    )
            )
            .overlay(
                Image(systemName: "app.dashed")
                    .font(.system(size: 25, weight: .regular))
                    .foregroundStyle(Color.accentColor.opacity(0.70))
            )
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.88, anchor: .top)),
                removal: .opacity.combined(with: .scale(scale: 0.96, anchor: .top))
            ))
    }

    @ViewBuilder
    private var appList: some View {
        if visibleApps.isEmpty {
            Spacer(minLength: 0)
        } else {
            VStack(spacing: 10) {
                ForEach(visibleApps) { app in
                    Button {
                        launch(app)
                    } label: {
                        AppIconImage(app: app)
                            .frame(width: 52, height: 52)
                            .frame(width: 78, height: 64)
                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .help(app.name)
                }
            }
            .padding(.bottom, 6)
            .animation(.easeInOut(duration: 0.20), value: isDropTargeted)
        }
    }

    private func softenAppListChange() {
        let token = UUID()
        categoryAnimationToken = token

        withAnimation(.easeInOut(duration: 0.08)) {
            appListOpacity = 0.72
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            guard categoryAnimationToken == token else {
                return
            }

            withAnimation(.easeInOut(duration: 0.18)) {
                appListOpacity = 1
            }
        }
    }
}

private struct CategoryListView: View {
    let groups: [ShelfGroup]
    let selectedGroupID: ShelfGroup.ID?
    let select: (ShelfGroup) -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(groups) { group in
                Button {
                    select(group)
                } label: {
                    CategoryDialItem(title: group.title, isSelected: group.id == selectedGroupID)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.trailing, 12)
        .padding(.top, 24)
        .frame(width: LauncherPanelView.categoryListWidth)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

private struct CategoryDialItem: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: isSelected ? "folder.fill" : "folder")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

            Text(title)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(width: 108, alignment: .leading)
        .background(.regularMaterial, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(
                    isSelected ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.10),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(isSelected ? 0.22 : 0.12), radius: 8, x: 0, y: 4)
    }
}
