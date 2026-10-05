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

    func setupTabGroupsUI() {
        guard TabGroupsFeatureFlag.isEnabled, let controller = tabGroupsController else { return }
        guard tabGroupsTopHost == nil else { return }
        controller.onChange = { [weak self] _ in
            guard let self else { return }
            self.normalTabPanel?.tabDisplayView.refreshGroupFilter()
            self.refreshTabGroupsUI()
            if let tabManager = self.tabManager {
                store.dispatch(ToolbarAction(numberOfTabs: tabManager.normalTabs.count,
                                             windowUUID: self.windowUUID,
                                             actionType: ToolbarActionType.numberOfTabsChanged))
            }
        }
        normalTabPanel?.tabDisplayView.onSelectionChange = { [weak self] in
            self?.refreshTabGroupsUI()
        }
        normalTabPanel?.tabDisplayView.onCreateGroupForTab = { [weak self] tabID in
            self?.promptForNewGroup(with: [tabID])
        }
        normalTabPanel?.tabDisplayView.onMoveTabToGroup = { [weak self] tabID, groupID in
            guard let self, let controller = self.tabGroupsController, let tabManager = self.tabManager else { return }
            TabGroupsTabActions(controller: controller, tabManager: tabManager).moveTab(tabID, to: groupID)
            self.refreshTabGroupsUI()
        }

        let topHost = UIHostingController(rootView: AnyView(EmptyView()))
        let bottomHost = UIHostingController(rootView: AnyView(EmptyView()))
        tabGroupsTopHost = topHost
        tabGroupsBottomHost = bottomHost
        for (host, height, isTop) in [(topHost, TabGroupsTrayBarMetrics.topHeight, true),
                                      (bottomHost, TabGroupsTrayBarMetrics.bottomHeight, false)] {
            addChild(host)
            host.view.backgroundColor = .clear
            host.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(host.view)
            NSLayoutConstraint.activate([
                host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                host.view.heightAnchor.constraint(equalToConstant: height),
                isTop
                    ? host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
                    : host.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
            host.didMove(toParent: self)
        }
        let backdrop = TabGroupsSelectionBackdropView()
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        backdrop.isHidden = true
        view.insertSubview(backdrop, belowSubview: bottomHost.view)
        NSLayoutConstraint.activate([
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.topAnchor.constraint(equalTo: bottomHost.view.topAnchor,
                                          constant: -TabGroupsTrayBarMetrics.bottomHeight),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tabGroupsSelectionBackdrop = backdrop
        refreshTabGroupsUI()
    }

    func refreshTabGroupsUI() {
        guard TabGroupsFeatureFlag.isEnabled,
              let controller = tabGroupsController,
              let tabManager,
              let topHost = tabGroupsTopHost,
              let bottomHost = tabGroupsBottomHost else { return }
        controller.reconcile(normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
        let normalIDs = tabManager.normalTabs.map(\.tabUUID)
        let selectedGroup = controller.state.groups.first { $0.id == controller.state.selectedGroupID }
        let displayView = normalTabPanel?.tabDisplayView
        let isSelectingTabs = tabTrayState.selectedPanel == .tabs && displayView?.isSelectingTabs == true
        let selectedPanel: TabGroupsTrayBarViewModel.Panel = switch tabTrayState.selectedPanel {
        case .tabs: .tabs
        case .privateTabs: .privateTabs
        case .syncedTabs: .syncedTabs
        }
        let colors = retrieveTheme().colors
        let selectedCount = isSelectingTabs ? displayView?.selectedTabIDs.count : nil
        let selectionTitle = selectedCount.map { count in
            count == 0 ? String.TabGroups.SelectTabs
                : tabGroupsCountText(count,
                                     one: String.TabGroups.SelectedTabCountOne,
                                     other: String.TabGroups.SelectedTabCountOther)
        } ?? String.TabGroups.SelectTabs
        let barColors = TabGroupsTrayBarViewModel.Colors(
            primaryText: Color(colors.textPrimary),
            selectedPanelBackground: Color(colors.layer2),
            emphasis: Color(colors.textPrimary),
            onEmphasis: Color(colors.textInverted),
            destructive: Color(colors.textCritical))
        let viewModel = TabGroupsTrayBarViewModel(
            destinationTitle: selectedGroup?.title ?? String.TabGroups.Mobile,
            isGroupSelected: selectedGroup != nil,
            selectedPanel: selectedPanel,
            privateTitle: String.TabsTray.TabsSelectorPrivateTabsTitle,
            syncedTitle: String.TabsTray.TabsSelectorSyncedTabsTitle,
            doneAccessibilityLabel: String.TabGroups.Done,
            moreAccessibilityLabel: String.TabGroups.MoreOptions,
            addTabAccessibilityLabel: String.TabsTray.TabTrayAddTabAccessibilityLabel,
            tabCountTitle: tabGroupsCountText(
                controller.visibleTabIDs(normalTabIDs: normalIDs).count,
                one: String.TabGroups.TabCountOne,
                other: String.TabGroups.TabCountOther),
            selectionTitle: selectionTitle,
            finishSelectionAccessibilityLabel: String.TabGroups.FinishSelection,
            newGroupTitle: String.TabGroups.NewGroup,
            moveToGroupTitle: String.TabGroups.MoveToGroup,
            closeSelectedTabsTitle: String.TabGroups.CloseSelectedTabs,
            colors: barColors,
            groupEmoji: selectedGroup?.emoji,
            groupColor: selectedGroup?.color.swiftUIColor,
            selectedTabCount: selectedCount)
        let menuModel = TabGroupsContextMenuViewModel(
            showsGroupActions: selectedGroup != nil,
            selectTabsTitle: String.TabGroups.SelectTabs,
            arrangeTabsTitle: String.TabGroups.ArrangeTabsBy,
            customizeGroupTitle: String.TabGroups.CustomizeGroup,
            closeTabsTitle: String.TabGroups.CloseSelectedTabs,
            ungroupTitle: String.TabGroups.Ungroup,
            tabSettingsTitle: String.TabGroups.TabSettings,
            originalOrderTitle: String.TabGroups.OriginalOrder,
            titleOrderTitle: String.TabGroups.TitleOrder,
            moreAccessibilityLabel: String.TabGroups.MoreOptions,
            colors: barColors,
            sortsByTitle: normalTabPanel?.tabDisplayView.sortTabsByTitle == true)
        topHost.rootView = AnyView(TabGroupsTrayTopBar(viewModel: viewModel, onAction: { [weak self] action in
            self?.handleTabGroupsBarAction(action)
        }) {
            TabGroupsContextMenuView(viewModel: menuModel) { [weak self] action in
                self?.handleTabGroupsMenuAction(action)
            }
        })
        bottomHost.rootView = AnyView(TabGroupsTrayBottomBar(viewModel: viewModel) { [weak self] action in
            self?.handleTabGroupsBarAction(action)
        })
        topHost.view.isHidden = tabTrayState.selectedPanel != .tabs
        tabGroupsSelectionBackdrop?.isHidden = !isSelectingTabs
    }

    private func tabGroupsCountText(_ count: Int, one: String, other: String) -> String {
        String(format: count == 1 ? one : other, count)
    }

    private func handleTabGroupsBarAction(_ action: TabGroupsTrayBarAction) {
        switch action {
        case .openDestinationPicker:
            showTabGroupsPicker()
        case .openMoreMenu:
            break
        case .addTab:
            if tabTrayState.selectedPanel == .syncedTabs {
                didSelectSection(panelType: .tabs)
            }
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
        case .createGroupFromSelection:
            guard let selectedIDs = normalTabPanel?.tabDisplayView.selectedTabIDs,
                  !selectedIDs.isEmpty else { return }
            showGroupEditor(tabIDs: Array(selectedIDs))
        case .moveSelectionToGroup:
            showMoveSelectedTabsMenu()
        case .closeSelectedTabs:
            guard let selectedIDs = normalTabPanel?.tabDisplayView.selectedTabIDs,
                  !selectedIDs.isEmpty,
                  let tabManager else { return }
            let tabs = tabManager.normalTabs.filter { selectedIDs.contains($0.tabUUID) }
            let title = tabGroupsCountText(
                tabs.count, one: String.TabGroups.CloseTabsPromptOne, other: String.TabGroups.CloseTabsPromptOther)
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String.TabGroups.Cancel, style: .cancel))
            alert.addAction(UIAlertAction(title: String.TabGroups.CloseSelectedTabs, style: .destructive) { [weak self] _ in
                self?.normalTabPanel?.tabDisplayView.isSelectingTabs = false
                guard let self, let controller = self.tabGroupsController else { return }
                TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs(tabs)
                self.refreshTabGroupsUI()
            })
            present(alert, animated: true)
        }
    }

    private func showMoveSelectedTabsMenu() {
        guard let selectedIDs = normalTabPanel?.tabDisplayView.selectedTabIDs,
              !selectedIDs.isEmpty,
              let controller = tabGroupsController else { return }

        let title = tabGroupsCountText(
            selectedIDs.count, one: String.TabGroups.MoveTabsPromptOne, other: String.TabGroups.MoveTabsPromptOther)
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        if controller.state.selectedGroupID != nil {
            alert.addAction(UIAlertAction(title: String.TabGroups.Mobile, style: .default) { [weak self] _ in
                self?.moveSelectedTabs(selectedIDs, to: nil)
            })
        }
        for group in controller.state.groups where group.id != controller.state.selectedGroupID {
            alert.addAction(UIAlertAction(title: "\(group.emoji ?? "🗂️") \(group.title)", style: .default) { [weak self] _ in
                self?.moveSelectedTabs(selectedIDs, to: group.id)
            })
        }
        if alert.actions.isEmpty {
            alert.message = String.TabGroups.CreateAnotherGroup
        }
        alert.addAction(UIAlertAction(title: String.TabGroups.Cancel, style: .cancel))
        alert.popoverPresentationController?.sourceView = tabGroupsBottomHost?.view ?? view
        alert.popoverPresentationController?.sourceRect = tabGroupsBottomHost?.view.bounds ?? view.bounds
        present(alert, animated: true)
    }

    private func moveSelectedTabs(_ selectedIDs: Set<TabUUID>, to groupID: UUID?) {
        guard let controller = tabGroupsController, let tabManager else { return }
        let normalIDs = tabManager.normalTabs.map(\.tabUUID)
        let movingIDs = normalIDs.filter { selectedIDs.contains($0) }
        normalTabPanel?.tabDisplayView.isSelectingTabs = false
        controller.moveTabs(movingIDs, to: groupID, normalTabIDs: normalIDs)
        if let tabID = controller.preferredTabID(normalTabIDs: normalIDs),
           let tab = tabManager.getTabForUUID(uuid: tabID) {
            tabManager.selectTab(tab)
        }
        refreshTabGroupsUI()
    }

    private func showTabGroupsPicker() {
        guard tabTrayState.selectedPanel == .tabs else { return }
        let host = UIHostingController(rootView: makeTabGroupsPicker())
        tabGroupsPickerHost = host
        host.view.backgroundColor = .clear
        host.modalPresentationStyle = .pageSheet
        host.sheetPresentationController?.detents = [.medium(), .large()]
        present(host, animated: true)
    }

    private func makeTabGroupsPicker() -> AnyView {
        guard let controller = tabGroupsController else { return AnyView(EmptyView()) }
        let colors = retrieveTheme().colors
        let pickerColors = TabGroupsPickerViewModel.Colors(
            background: Color(colors.layer1),
            cardBackground: Color(colors.layer2),
            primaryText: Color(colors.textPrimary),
            accent: Color(colors.actionPrimary),
            onEmphasis: Color(colors.textInverted))
        let destinations: [TabGroupsPickerViewModel.Destination] = [
            .init(id: "mobile", title: String.TabGroups.Mobile, kind: .device)
        ] + controller.state.groups.map {
            .init(id: $0.id.uuidString,
                  title: $0.title,
                  kind: .group,
                  emoji: $0.emoji,
                  color: $0.color.swiftUIColor)
        }
        let selectedIDs = normalTabPanel?.tabDisplayView.selectedTabIDs ?? []
        let model = TabGroupsPickerViewModel(
            title: String.TabGroups.PickerTitle,
            colors: pickerColors,
            doneAccessibilityLabel: String.TabGroups.Done,
            destinations: destinations,
            privateDestination: .init(id: "private",
                                      title: String.TabsTray.TabsSelectorPrivateTabsTitle,
                                      kind: .privateTabs),
            selectedDestinationID: controller.state.selectedGroupID?.uuidString ?? "mobile",
            createEmptyGroupTitle: String.TabGroups.NewEmptyGroup,
            createWithSelectedTabsTitle: selectedIDs.isEmpty ? nil
                : tabGroupsCountText(selectedIDs.count,
                                     one: String.TabGroups.NewGroupWithOneTab,
                                     other: String.TabGroups.NewGroupWithMultipleTabs))
        return AnyView(TabGroupsPickerView(viewModel: model) { [weak self] action in
            self?.handleTabGroupsPickerAction(action)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(pickerColors.background))
    }

    private func handleTabGroupsPickerAction(_ action: TabGroupsPickerAction) {
        guard let controller = tabGroupsController else { return }
        switch action {
        case .done:
            tabGroupsPickerHost?.dismiss(animated: true)
        case .selectDestination(let id):
            if id == "private" {
                tabGroupsPickerHost?.dismiss(animated: true) { [weak self] in
                    self?.didSelectSection(panelType: .privateTabs)
                }
                return
            }
            let groupID = id == "mobile" ? nil : UUID(uuidString: id)
            Task { [weak self] in
                guard let self, let tabManager = self.tabManager else { return }
                do {
                    let host = try await TabGroupsTabActions(controller: controller, tabManager: tabManager)
                        .openGroup(groupID)
                    self.tabGroupsPickerHost?.dismiss(animated: true)
                    guard host == self.windowUUID else {
                        try await activateTabGroupWindow(host, groupID: groupID)
                        return
                    }
                    let ids = tabManager.normalTabs.map(\.tabUUID)
                    if let preferred = controller.preferredTabID(normalTabIDs: ids),
                       let tab = tabManager.getTabForUUID(uuid: preferred) {
                        tabManager.selectTab(tab)
                    }
                    self.refreshTabGroupsUI()
                } catch {
                    DefaultLogger.shared.log("Could not open tab group: \(error)", level: .warning, category: .tabs)
                }
            }
        case .deleteGroup(let id):
            if let groupID = UUID(uuidString: id) { controller.deleteGroup(id: groupID) }
            tabGroupsPickerHost?.rootView = makeTabGroupsPicker()
        case .moveGroup(let offsets, let destination):
            controller.moveGroups(fromOffsets: offsets, toOffset: destination)
            tabGroupsPickerHost?.rootView = makeTabGroupsPicker()
        case .createEmptyGroup, .createWithSelectedTabs:
            let selectedIDs = action == .createWithSelectedTabs
                ? Array(normalTabPanel?.tabDisplayView.selectedTabIDs ?? []) : []
            tabGroupsPickerHost?.dismiss(animated: true) { [weak self] in
                self?.showGroupEditor(tabIDs: selectedIDs)
            }
        }
    }

    private func promptForNewGroup(with tabIDs: [TabUUID]) {
        showGroupEditor(tabIDs: tabIDs)
    }

    private func showGroupEditor(group: TabGroup? = nil, tabIDs: [TabUUID] = []) {
        guard let controller = tabGroupsController, let tabManager else { return }
        let editor = TabGroupEditorView(name: group?.title ?? "",
                                        emoji: group?.emoji ?? "🗂️",
                                        color: group?.color ?? .orange,
                                        isEditing: group != nil,
                                        onCancel: { [weak self] in self?.dismiss(animated: true) },
                                        onSave: { [weak self] name, emoji, color in
            guard let self else { return }
            if let group {
                controller.updateGroup(id: group.id, name: name, emoji: emoji, color: color)
            } else {
                let initialTabIDs: [TabUUID]
                if tabIDs.isEmpty {
                    initialTabIDs = [tabManager.addTab(nil, isPrivate: false).tabUUID]
                } else {
                    initialTabIDs = tabIDs
                }
                controller.createGroup(name: name,
                                       emoji: emoji,
                                       color: color,
                                       tabIDs: initialTabIDs,
                                       normalTabIDs: tabManager.normalTabs.map(\.tabUUID))
                if let preferredID = controller.preferredTabID(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)),
                   let tab = tabManager.getTabForUUID(uuid: preferredID) {
                    tabManager.selectTab(tab)
                }
                self.normalTabPanel?.tabDisplayView.isSelectingTabs = false
            }
            self.dismiss(animated: true)
            self.refreshTabGroupsUI()
        })
        let host = UIHostingController(rootView: editor)
        host.modalPresentationStyle = .pageSheet
        host.sheetPresentationController?.detents = [.large()]
        present(host, animated: true)
    }

    private func handleTabGroupsMenuAction(_ action: TabGroupsContextMenuAction) {
        guard let controller = tabGroupsController, let tabManager else { return }
        switch action {
        case .selectTabs:
            if let displayView = normalTabPanel?.tabDisplayView {
                displayView.isSelectingTabs = true
                refreshTabGroupsUI()
            }
        case .arrangeTabsByOriginalOrder:
            normalTabPanel?.tabDisplayView.sortTabsByTitle = false
            refreshTabGroupsUI()
        case .arrangeTabsByTitle:
            normalTabPanel?.tabDisplayView.sortTabsByTitle = true
            refreshTabGroupsUI()
        case .customizeGroup:
            guard let group = controller.state.groups.first(where: { $0.id == controller.state.selectedGroupID }) else {
                return
            }
            showGroupEditor(group: group)
        case .closeTabs:
            let visibleIDs = Set(controller.visibleTabIDs(normalTabIDs: tabManager.normalTabs.map(\.tabUUID)))
            let tabs = tabManager.normalTabs.filter { visibleIDs.contains($0.tabUUID) }
            let title = tabGroupsCountText(
                tabs.count, one: String.TabGroups.CloseTabsPromptOne, other: String.TabGroups.CloseTabsPromptOther)
            let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: String.TabGroups.Cancel, style: .cancel))
            alert.addAction(UIAlertAction(title: String.TabGroups.CloseSelectedTabs, style: .destructive) { [weak self] _ in
                guard let self else { return }
                TabGroupsTabActions(controller: controller, tabManager: tabManager).closeTabs(tabs)
                self.refreshTabGroupsUI()
            })
            present(alert, animated: true)
        case .ungroup:
            if let groupID = controller.state.selectedGroupID { controller.ungroup(id: groupID) }
        case .tabSettings:
            navigationHandler?.showTabSettings()
        }
    }
}

private final class TabGroupsSelectionBackdropView: UIVisualEffectView {
    private static let fadeMidpoint: NSNumber = 0.45
    private let fadeMask = CAGradientLayer()

    init() {
        super.init(effect: UIBlurEffect(style: .systemMaterial))
        isUserInteractionEnabled = false
        fadeMask.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor]
        fadeMask.locations = [0, Self.fadeMidpoint, 1]
        layer.mask = fadeMask
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fadeMask.frame = bounds
    }
}

@MainActor
func activateTabGroupWindow(_ windowUUID: WindowUUID, groupID: TabGroupID?) async throws {
    let windows: WindowManager = AppContainer.shared.resolve()
    guard let manager = windows.windows[windowUUID]?.tabManager else { return }
    let controller = TabGroupsSessionStore.controller(for: windowUUID, tabManager: manager)
    let host = try await TabGroupsTabActions(controller: controller, tabManager: manager).openGroup(groupID)
    guard host == windowUUID else { return }
    if let id = controller.preferredTabID(normalTabIDs: manager.normalTabs.map(\.tabUUID)),
       let tab = manager.getTabForUUID(uuid: id) {
        manager.selectTab(tab)
    }
    guard let scene = UIApplication.shared.connectedScenes.first(where: {
        ($0.delegate as? SceneDelegate)?.sceneCoordinator?.windowUUID == windowUUID
    }) else { return }
    UIApplication.shared.requestSceneSessionActivation(scene.session, userActivity: nil, options: nil) { error in
        DefaultLogger.shared.log("Could not activate tab group window: \(error)", level: .warning, category: .tabs)
    }
}
