// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import SwiftUI
import UIKit

extension TabTrayViewController {
    private var normalTabPanel: TabDisplayPanelViewController? {
        childPanelControllers.compactMap { $0.topViewController as? TabDisplayPanelViewController }
            .first { $0.panelType == .tabs }
    }

    private var visibleGroupTabs: [Tab] {
        guard let controller = tabGroupsController, let tabManager else { return [] }
        let ids = Set(controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)))
        return tabManager.normalTabs.filter { ids.contains($0.tabUUID) }
    }

    func setupTabGroupsUI() {
        guard TabGroupsFeatureFlag.isEnabled, let controller = tabGroupsController,
              tabGroupsTopHost == nil else { return }
        controller.onChange = { [weak self] _ in
            guard let self, TabGroupsFeatureFlag.isEnabled else { return }
            self.normalTabPanel?.tabDisplayView.refreshGroupFilter()
            self.refreshTabGroupsUI()
            if let tabManager = self.tabManager, let selectedTab = tabManager.selectedTab {
                let count = selectedTab.isPrivate ? tabManager.privateTabs.count : tabManager.normalTabs.count
                store.dispatch(ToolbarModernAction.numberOfTabsChanged(count: count),
                               forWindowUUID: self.windowUUID)
            }
        }
        normalTabPanel?.tabDisplayView.onSelectionChange = { [weak self] in self?.refreshTabGroupsUI() }
        normalTabPanel?.tabDisplayView.onCreateGroupForTab = { [weak self] id in
            self?.showGroupEditor(tabIDs: [id])
        }
        normalTabPanel?.tabDisplayView.onMoveTabToGroup = { [weak self] tabID, groupID in
            guard let self, TabGroupsFeatureFlag.isEnabled, let tabManager = self.tabManager else { return }
            TabGroupsTabActions(controller: controller, tabManager: tabManager).moveTab(tabID, to: groupID)
            self.refreshTabGroupsUI()
        }
        tabGroupsNativeToolbar = TabGroupsTrayNativeToolbar { [weak self] in self?.handleTabGroupsBarAction($0) }
        let host = UIHostingController(rootView: AnyView(EmptyView()))
        tabGroupsTopHost = host
        addChild(host)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            host.view.heightAnchor.constraint(greaterThanOrEqualToConstant: TabGroupsTrayBarMetrics.topHeight)
        ])
        host.didMove(toParent: self)
        refreshTabGroupsUI()
    }

    func refreshTabGroupsUI() {
        guard TabGroupsFeatureFlag.isEnabled, let controller = tabGroupsController,
              let tabManager, let topHost = tabGroupsTopHost else { return }
        let normalIDs = tabManager.normalTabs.map(\.tabUUID)
        controller.reconcile(normalTabIDs: normalIDs)
        let group = controller.state.groups.first { $0.id == controller.state.selectedGroupID }
        let displayView = normalTabPanel?.tabDisplayView
        let selectedCount = tabTrayState.selectedPanel == .tabs && displayView?.isSelectingTabs == true
            ? displayView?.selectedTabIDs.count : nil
        let theme = retrieveTheme()
        let isDefaultGroup = group.map { TabGroupColorPalette.isDefault($0.color) } == true
        let colors = TabGroupsTrayBarViewModel.Colors.themed(
            theme, isDefaultGroup: tabTrayState.selectedPanel == .tabs && isDefaultGroup)
        let selectedPanel = tabTrayState.selectedPanel
        let countTitle = tabGroupsCountTitle(controller.visibleTabIDs(normalTabIDs: normalIDs).count)
        let model = TabGroupsTrayBarViewModel(
            destinationTitle: group?.title ?? countTitle,
            isGroupSelected: group != nil && selectedPanel == .tabs,
            selectedPanel: selectedPanel,
            doneAccessibilityLabel: String.TabGroups.Accessibility.DoneButton,
            addTabAccessibilityLabel: String.TabGroups.Accessibility.NewTabButton,
            finishSelectionAccessibilityLabel: String.TabGroups.Accessibility.DoneButton,
            colors: colors,
            groupIcon: group?.icon,
            groupColor: group.map { Color(TabGroupColorPalette.color(for: $0.color, theme: theme)) },
            selectedTabCount: selectedCount)
        let menuModel = TabGroupsContextMenuViewModel(
            destinationTitle: model.destinationTitle,
            showsGroupActions: group != nil,
            tabCount: visibleGroupTabs.count,
            moreAccessibilityLabel: String.TabGroups.Accessibility.OptionsButton,
            colors: colors)
        topHost.rootView = makeTabGroupsHeader(model: model, menuModel: menuModel)
        tabGroupsNativeToolbar?.update(viewModel: model, usesGlassButtons: theme.isNova)
        updateToolbarItems()
        topHost.view.isHidden = tabTrayState.selectedPanel != .tabs
        if let selectionView = tabGroupsSelectionDisplayView, let displayView {
            selectionView.applyTheme(theme: theme)
            selectionView.updateSelectedTabsPreview(from: displayView.tabsState)
            tabGroupsSelectionHost?.rootView = selectedTabsSheet(displayView: selectionView,
                                                                 colors: colors,
                                                                 tint: model.activeTint)
        }
    }

    private func makeTabGroupsHeader(model: TabGroupsTrayBarViewModel,
                                     menuModel: TabGroupsContextMenuViewModel) -> AnyView {
        let pickerModel = makeTabGroupsPickerModel()
        let onBarAction: (TabGroupsTrayBarAction) -> Void = { [weak self] in self?.handleTabGroupsBarAction($0) }
        let onPickerAction: (TabGroupsPickerAction) -> Void = { [weak self] in self?.handleTabGroupsPickerAction($0) }
        let onMenuAction: (TabGroupsContextMenuAction) -> Void = { [weak self] in self?.handleTabGroupsMenuAction($0) }
        let header = TabGroupsTrayTopBar(viewModel: model, onAction: onBarAction) {
            TabGroupsDestinationMenuView(viewModel: pickerModel, onAction: onPickerAction) {
                TabGroupsDestinationControlLabel(viewModel: model)
            }
        } moreControl: {
            TabGroupsContextMenuView(viewModel: menuModel, onAction: onMenuAction)
        } selectionControls: {
            self.selectionControls(model: model)
        }
        return AnyView(header)
    }

    private func tabGroupsCountTitle(_ count: Int) -> String {
        count == 1 ? "1 Tab"
            : String(format: "%@ Tabs", count.formatted())
    }

    private func handleTabGroupsBarAction(_ action: TabGroupsTrayBarAction) {
        guard TabGroupsFeatureFlag.isEnabled else { return }
        switch action {
        case .addTab:
            if tabTrayState.selectedPanel == .syncedTabs { didSelectSection(panelType: .tabs) }
            newTabButtonTapped()
        case .selectPanel(let panel):
            normalTabPanel?.tabDisplayView.isSelectingTabs = false
            let panelType: TabTrayPanelType = switch panel {
            case .tabs: .tabs
            case .privateTabs: .privateTabs
            case .syncedTabs: .syncedTabs
            }
            didSelectSection(panelType: panelType)
        case .done:
            doneButtonTapped()
        case .finishSelection:
            normalTabPanel?.tabDisplayView.isSelectingTabs = false
            refreshTabGroupsUI()
        case .toggleSelectAll:
            normalTabPanel?.tabDisplayView.toggleSelectionOfAllTabs()
        case .showSelections:
            showSelectedTabs()
        case .createGroupFromSelection:
            let ids = normalTabPanel?.tabDisplayView.selectedTabIDs ?? []
            if !ids.isEmpty { showGroupEditor(tabIDs: Array(ids)) }
        }
    }

    private func selectionControls(model: TabGroupsTrayBarViewModel) -> some View {
        HStack(spacing: 0) {
            Menu {
                Button(role: .destructive) { [weak self] in self?.closeSelectedTabs() } label: {
                    Label(String(format: String.TabsTray.TabTrayCloseTabsTitle, (model.selectedTabCount ?? 0).formatted()),
                          systemImage: "xmark")
                }
            } label: {
                TabGroupsSelectionActionLabel(title: String.TabGroups.CloseSelectionButton, color: model.colors.primaryText)
            }
            .accessibilityIdentifier("tabGroupsTray.closeSelectedTabs")
            selectionMoveMenu(model: model)
        }
    }

    @ViewBuilder
    private func selectionMoveMenu(model: TabGroupsTrayBarViewModel) -> some View {
        let destinations = makeTabGroupsPickerModel().switcherDestinations
        let availableIDs = Set(destinations.filter { destination in
            destination.id == "mobile"
                || tabGroupsController?.canMoveTabs(to: UUID(uuidString: destination.id)) == true
        }.map(\.id))
        let menu = Menu {
            Section(String(format: String.TabGroups.MoveTabsToTitle, (model.selectedTabCount ?? 0).formatted())) {
                ForEach(destinations) { [weak self] destination in
                    Toggle(isOn: Binding(get: { [weak self] in
                        (self?.tabGroupsController?.state.selectedGroupID?.uuidString ?? "mobile") == destination.id
                    }, set: { [weak self] isSelected in
                        guard isSelected else { return }
                        self?.moveSelectedTabs(to: destination.id == "mobile" ? nil : UUID(uuidString: destination.id))
                    })) {
                        Label {
                            Text(destination.title)
                        } icon: {
                            if let icon = destination.icon {
                                Image(uiImage: icon.badgeImage(color: UIColor(destination.color ?? model.activeTint)))
                                    .renderingMode(.original)
                            } else {
                                Image(StandardImageIdentifiers.Large.deviceMobileGradient)
                                    .renderingMode(.original)
                            }
                        }
                    }
                    .disabled(!availableIDs.contains(destination.id))
                }
                Button { [weak self] in
                    self?.handleTabGroupsBarAction(.createGroupFromSelection)
                } label: {
                    Label(String.TabGroups.NewTabGroupMenu, image: StandardImageIdentifiers.Large.newTabGroup)
                }
            }
        } label: {
            TabGroupsSelectionActionLabel(title: String.TabGroups.MoveSelectionButton, color: model.colors.primaryText)
        }
        .accessibilityIdentifier("tabGroupsTray.moveSelectionToGroup")
        if #available(iOS 16.4, *) {
            menu.menuActionDismissBehavior(.enabled)
        } else {
            menu
        }
    }

    private func closeSelectedTabs() {
        guard TabGroupsFeatureFlag.isEnabled, let controller = tabGroupsController, let tabManager,
              let ids = normalTabPanel?.tabDisplayView.selectedTabIDs, !ids.isEmpty else { return }
        let tabs = tabManager.normalTabs.filter { ids.contains($0.tabUUID) }
        normalTabPanel?.tabDisplayView.isSelectingTabs = false
        TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs(tabs)
        refreshTabGroupsUI()
    }

    private func moveSelectedTabs(to groupID: TabGroupID?) {
        guard TabGroupsFeatureFlag.isEnabled, let controller = tabGroupsController, let tabManager,
              controller.canMoveTabs(to: groupID),
              controller.state.selectedGroupID != groupID,
              let selectedIDs = normalTabPanel?.tabDisplayView.selectedTabIDs, !selectedIDs.isEmpty else { return }
        let normalIDs = tabManager.normalTabs.map(\.tabUUID)
        normalTabPanel?.tabDisplayView.isSelectingTabs = false
        controller.moveTabs(normalIDs.filter { selectedIDs.contains($0) }, to: groupID, normalTabIDs: normalIDs)
        if let id = controller.preferredTabID(normalTabIDs: normalIDs), let tab = tabManager.getTabForUUID(uuid: id) {
            tabManager.selectTab(tab)
        }
        refreshTabGroupsUI()
    }

    private func showSelectedTabs() {
        guard let source = normalTabPanel?.tabDisplayView, !source.selectedTabIDs.isEmpty else { return }
        let displayView = TabDisplayView(panelType: .tabs, state: source.tabsState, windowUUID: windowUUID)
        displayView.tabGroupsController = tabGroupsController
        displayView.selectionProvider = { [weak source] in source?.selectedTabIDs ?? [] }
        displayView.onToggleSelection = { [weak source] in source?.toggleTabSelection($0) }
        displayView.isSelectingTabs = true
        displayView.showsOnlySelectedTabs = true
        displayView.applyTheme(theme: retrieveTheme())
        displayView.refreshGroupFilter()
        tabGroupsSelectionDisplayView = displayView
        let theme = retrieveTheme()
        let group = tabGroupsController?.state.groups.first { $0.id == tabGroupsController?.state.selectedGroupID }
        let colors = TabGroupsTrayBarViewModel.Colors.themed(
            theme, isDefaultGroup: group.map { TabGroupColorPalette.isDefault($0.color) } == true)
        let tint = group.map { Color(TabGroupColorPalette.color(for: $0.color, theme: theme)) } ?? colors.emphasis
        let host = UIHostingController(rootView: selectedTabsSheet(displayView: displayView,
                                                                   colors: colors,
                                                                   tint: tint))
        tabGroupsSelectionHost = host
        host.view.backgroundColor = .clear
        host.modalPresentationStyle = .pageSheet
        let detent = UISheetPresentationController.Detent.large()
        if #available(iOS 26.1, *) {
            detent.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        }
        host.sheetPresentationController?.detents = [detent]
        present(host, animated: true)
    }

    private func selectedTabsSheet(displayView: TabDisplayView,
                                   colors: TabGroupsTrayBarViewModel.Colors,
                                   tint: Color) -> AnyView {
        AnyView(TabGroupsSelectedTabsSheet(selectedTabCount: normalTabPanel?.tabDisplayView.selectedTabIDs.count ?? 0,
                                           colors: colors,
                                           tint: tint,
                                           onDone: { [weak self] in self?.dismiss(animated: true) }) {
            TabGroupsSelectedTabsContent(displayView: displayView)
        })
    }

    private func makeTabGroupsPickerModel() -> TabGroupsPickerViewModel {
        let theme = retrieveTheme()
        let controller = tabGroupsController
        let count = tabManager?.normalTabs.filter { $0.groupID == nil }.count ?? 0
        let destinations: [TabGroupsPickerViewModel.Destination] = [
            .init(id: "mobile", title: tabGroupsCountTitle(count), kind: .device)
        ] + (controller?.state.groups.map {
            .init(id: $0.id.uuidString,
                  title: $0.title,
                  kind: .group,
                  icon: $0.icon,
                  color: Color($0.color.uiColor))
        } ?? [])
        return TabGroupsPickerViewModel(
            accentColor: Color(theme.colors.actionPrimary),
            destinations: destinations,
            selectedDestinationID: controller?.state.selectedGroupID?.uuidString ?? "mobile")
    }

    private func handleTabGroupsPickerAction(_ action: TabGroupsPickerAction) {
        guard TabGroupsFeatureFlag.isEnabled, let controller = tabGroupsController else { return }
        switch action {
        case .selectDestination(let id):
            let groupID = id == "mobile" ? nil : UUID(uuidString: id)
            Task { [weak self] in
                guard let self, TabGroupsFeatureFlag.isEnabled, let tabManager = self.tabManager else { return }
                do {
                    let actions = TabGroupsTabActions(controller: controller, tabManager: tabManager)
                    let host = try await actions.openGroup(groupID)
                    guard TabGroupsFeatureFlag.isEnabled else { return }
                    guard host == self.windowUUID else {
                        try await activateTabGroupWindow(host, groupID: groupID)
                        return
                    }
                    self.refreshTabGroupsUI()
                } catch {
                    DefaultLogger.shared.log("Could not open tab group: \(error)", level: .warning, category: .tabs)
                }
            }
        case .createEmptyGroup:
            showGroupEditor()
        }
    }

    private func showGroupEditor(group: TabGroup? = nil, tabIDs: [TabUUID] = []) {
        guard TabGroupsFeatureFlag.isEnabled, let controller = tabGroupsController, let tabManager else { return }
        let icon = group?.icon ?? .sfSymbol("rectangle.portrait.on.rectangle.portrait.angled.fill")
        let editor = TabGroupEditorView(windowUUID: windowUUID,
                                        themeManager: themeManager,
                                        name: group?.title ?? "",
                                        icon: icon,
                                        color: group?.color ?? TabGroupEditorView.defaultColor,
                                        isEditing: group != nil,
                                        onCancel: { [weak self] in self?.dismiss(animated: true) }
        ) { [weak self] name, icon, color in
            guard let self, TabGroupsFeatureFlag.isEnabled else { return }
            if let group {
                controller.updateGroup(id: group.id, name: name, icon: icon, color: color)
            } else {
                let ids = tabIDs.isEmpty ? [tabManager.addTab(nil, isPrivate: false).tabUUID] : tabIDs
                let normalIDs = tabManager.normalTabs.map(\.tabUUID)
                controller.createGroup(name: name,
                                       icon: icon,
                                       color: color,
                                       tabIDs: ids,
                                       normalTabIDs: normalIDs)
                if let id = controller.preferredTabID(normalTabIDs: normalIDs),
                   let tab = tabManager.getTabForUUID(uuid: id) { tabManager.selectTab(tab) }
                self.normalTabPanel?.tabDisplayView.isSelectingTabs = false
            }
            self.dismiss(animated: true)
            self.refreshTabGroupsUI()
        }
        let host = UIHostingController(rootView: editor)
        host.modalPresentationStyle = .pageSheet
        host.sheetPresentationController?.detents = [.large()]
        present(host, animated: true)
    }

    private func handleTabGroupsMenuAction(_ action: TabGroupsContextMenuAction) {
        guard TabGroupsFeatureFlag.isEnabled, let controller = tabGroupsController, let tabManager else { return }
        let group = controller.state.groups.first { $0.id == controller.state.selectedGroupID }
        switch action {
        case .selectTabs:
            normalTabPanel?.tabDisplayView.isSelectingTabs = true
        case .customizeGroup:
            if let group { showGroupEditor(group: group) }
        case .closeTabs:
            TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs(visibleGroupTabs)
        case .closeTabsOlderThan(let age):
            let cutoff = age.dateCutoff(relativeTo: Date()).toTimestamp()
            TabGroupsTabActions(controller: controller, tabManager: tabManager)
                .closeTabs(visibleGroupTabs.filter { $0.lastExecutedTime < cutoff })
        case .ungroup:
            if let group { confirmGroupOperation(group, kind: .ungroup) }
        case .deleteGroup:
            if let group { confirmGroupOperation(group, kind: .delete) }
        case .shareGroup:
            let urls = visibleGroupTabs.compactMap(\.url)
            guard !urls.isEmpty else { return }
            let activity = UIActivityViewController(activityItems: urls, applicationActivities: nil)
            activity.popoverPresentationController?.sourceView = tabGroupsTopHost?.view ?? view
            activity.popoverPresentationController?.sourceRect = tabGroupsTopHost?.view.bounds ?? view.bounds
            present(activity, animated: true)
        }
        refreshTabGroupsUI()
    }

    private func confirmGroupOperation(_ group: TabGroup, kind: TabGroupsConfirmationViewModel.Kind) {
        let model = TabGroupsConfirmationViewModel(groupName: group.title, tabCount: group.tabIDs.count, kind: kind)
        let alert = UIAlertController(title: model.title, message: model.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: model.cancelTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: model.actionTitle, style: .destructive) { [weak self] _ in
            guard let self, TabGroupsFeatureFlag.isEnabled, let controller = self.tabGroupsController else { return }
            if kind == .ungroup { controller.ungroup(id: group.id) } else { controller.deleteGroup(id: group.id) }
            self.refreshTabGroupsUI()
        })
        present(alert, animated: true)
    }
}

private struct TabGroupsSelectedTabsContent: UIViewRepresentable {
    let displayView: TabDisplayView
    func makeUIView(context: Context) -> TabDisplayView { displayView }
    func updateUIView(_ uiView: TabDisplayView, context: Context) {}
}

@MainActor
func activateTabGroupWindow(_ windowUUID: WindowUUID, groupID: TabGroupID?) async throws {
    guard TabGroupsFeatureFlag.isEnabled else { return }
    let windows: WindowManager = AppContainer.shared.resolve()
    guard let manager = windows.windows[windowUUID]?.tabManager else { return }
    let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: manager)
    let host = try await TabGroupsTabActions(controller: controller, tabManager: manager).openGroup(groupID)
    guard TabGroupsFeatureFlag.isEnabled, host == windowUUID else { return }
    guard let scene = UIApplication.shared.connectedScenes.first(where: {
        ($0.delegate as? SceneDelegate)?.sceneCoordinator?.windowUUID == windowUUID
    }) else { return }
    UIApplication.shared.requestSceneSessionActivation(scene.session, userActivity: nil, options: nil) { error in
        DefaultLogger.shared.log("Could not activate tab group window: \(error)", level: .warning, category: .tabs)
    }
}
