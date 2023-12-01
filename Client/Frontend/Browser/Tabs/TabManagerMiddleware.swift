// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import TabDataStore

class TabManagerMiddleware {
    // TODO: [7863] Part of ongoing WIP for Redux + iPad Multi-window.
    var tabManagers: [SceneUUID: TabManager] = [:]
    var inactiveTabs = [InactiveTabsModel]()
    var selectedPanel: TabTrayPanelType = .tabs

    lazy var tabsPanelProvider: Middleware<AppState> = { state, action in
        switch action {
        case TabTrayAction.tabTrayDidLoad(let panelType):
            let tabTrayModel = self.getTabTrayModel(for: panelType)
            store.dispatch(TabTrayAction.didLoadTabTray(tabTrayModel))

        case TabPanelAction.tabPanelDidLoad(let isPrivate):
            let tabState = self.getTabsDisplayModel(for: isPrivate)
            store.dispatch(TabPanelAction.didLoadTabPanel(tabState))

        case TabTrayAction.changePanel(let panelType):
            let isPrivate = panelType == TabTrayPanelType.privateTabs
            let tabState = self.getTabsDisplayModel(for: isPrivate)
            store.dispatch(TabPanelAction.didLoadTabPanel(tabState))

        case TabPanelAction.addNewTab(let urlRequest, let isPrivateMode):
            self.addNewTab(with: urlRequest, isPrivate: isPrivateMode)
            let tabs = self.refreshTabs(for: isPrivateMode)
            store.dispatch(TabPanelAction.refreshTab(tabs))
            store.dispatch(TabTrayAction.dismissTabTray)

        case TabPanelAction.moveTab(let originIndex, let destinationIndex):
            guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel) else { return }
            self.moveTab(from: originIndex, to: destinationIndex)
            let tabs = self.refreshTabs(for: tabsState.isPrivateMode)
            store.dispatch(TabPanelAction.refreshTab(tabs))

        case TabPanelAction.closeTab(let tabUUID):
            guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel) else { return }
            Task {
                let shouldDismiss = await self.closeTab(with: tabUUID)
                ensureMainThread { [self] in
                    let tabs = self.refreshTabs(for: tabsState.isPrivateMode)
                    store.dispatch(TabPanelAction.refreshTab(tabs))
                    if shouldDismiss {
                        store.dispatch(TabTrayAction.dismissTabTray)
                    }
                }
            }

        case TabPanelAction.closeAllTabs:
            guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel) else { return }
            Task {
                await self.closeAllTabs(isPrivateMode: tabsState.isPrivateMode)
                ensureMainThread { [self] in
                    let tabs = self.refreshTabs(for: tabsState.isPrivateMode)
                    store.dispatch(TabPanelAction.refreshTab(tabs))
                    store.dispatch(TabTrayAction.dismissTabTray)
                }
            }

        case TabPanelAction.selectTab(let tabUUID):
            self.selectTab(for: tabUUID)
            store.dispatch(TabTrayAction.dismissTabTray)

        case TabPanelAction.closeAllInactiveTabs:
            self.closeAllInactiveTabs()
            store.dispatch(TabPanelAction.refreshInactiveTabs(self.inactiveTabs))

        case TabPanelAction.closeInactiveTabs(let index):
            self.closeInactiveTab(for: index)
            store.dispatch(TabPanelAction.refreshInactiveTabs(self.inactiveTabs))

        case TabPanelAction.learnMorePrivateMode(let urlRequest):
            self.didTapLearnMoreAboutPrivate(with: urlRequest)
            let tabs = self.refreshTabs(for: true)
            store.dispatch(TabPanelAction.refreshTab(tabs))
            store.dispatch(TabTrayAction.dismissTabTray)

        case TabManagerAction.tabManagerDidConnectToScene(let manager, let sceneUUID):
            self.setTabManager(manager, for: sceneUUID)
        default:
            break
        }
    }

    func getTabTrayModel(for panelType: TabTrayPanelType) -> TabTrayModel {
        selectedPanel = panelType

        let isPrivate = panelType == .privateTabs
        let tabsCount = refreshTabs(for: isPrivate).count
        return TabTrayModel(isPrivateMode: isPrivate,
                            selectedPanel: panelType,
                            normalTabsCount: "\(tabsCount)")
    }

    func getTabsDisplayModel(for isPrivate: Bool) -> TabDisplayModel {
        let tabs = refreshTabs(for: isPrivate)
        let isInactiveTabsExpanded = !isPrivate && !inactiveTabs.isEmpty
        let tabDisplayModel = TabDisplayModel(isPrivateMode: isPrivate,
                                              tabs: tabs,
                                              inactiveTabs: inactiveTabs,
                                              isInactiveTabsExpanded: isInactiveTabsExpanded)
        return tabDisplayModel
    }

    private func refreshTabs(for isPrivate: Bool) -> [TabModel] {
        var tabs = [TabModel]()
        let tabManagerTabs = defaultTabManager.tabs.filter { $0.isPrivate == isPrivate }
        tabManagerTabs.forEach { tab in
            let tabModel = TabModel(tabUUID: tab.tabUUID,
                                    isSelected: false,
                                    isPrivate: tab.isPrivate,
                                    isFxHomeTab: tab.isFxHomeTab,
                                    tabTitle: tab.displayTitle,
                                    url: tab.url,
                                    screenshot: tab.screenshot,
                                    hasHomeScreenshot: tab.hasHomeScreenshot,
                                    margin: 0)
            tabs.append(tabModel)
        }

        return tabs
    }

    private func addNewTab(with urlRequest: URLRequest?, isPrivate: Bool) {
        // TODO: Add a guard to check if is dragging as per Legacy code
        let tab = defaultTabManager.addTab(urlRequest, isPrivate: isPrivate)
        defaultTabManager.selectTab(tab)
    }

    private func moveTab(from originIndex: Int, to destinationIndex: Int) {
        defaultTabManager.moveTab(isPrivate: false, fromIndex: originIndex, toIndex: destinationIndex)
    }

    private func closeTab(with tabUUID: String) async -> Bool {
        let isLastTab = defaultTabManager.tabs.count == 1
        await defaultTabManager.removeTab(tabUUID)
        return isLastTab
    }

    private func closeAllTabs(isPrivateMode: Bool) async {
        await defaultTabManager.removeAllTabs(isPrivateMode: isPrivateMode)
        inactiveTabs.removeAll()
    }

    private func closeAllInactiveTabs() {
        inactiveTabs.removeAll()
    }

    private func closeInactiveTab(for index: Int) {
        inactiveTabs.remove(at: index)
    }

    private func didTapLearnMoreAboutPrivate(with urlRequest: URLRequest) {
        addNewTab(with: urlRequest, isPrivate: true)
    }

    private func selectTab(for tabUUID: String) {
        guard let tab = defaultTabManager.getTabForUUID(uuid: tabUUID) else { return }

        defaultTabManager.selectTab(tab)
    }

    private func setTabManager(_ tabManager: TabManager, for sceneUUID: SceneUUID) {
        tabManagers[sceneUUID] = tabManager
    }

    private func removeTabManager(_ tabManager: TabManager, for sceneUUID: SceneUUID) {
        tabManagers.removeValue(forKey: sceneUUID)
    }

    private var defaultTabManager: TabManager {
        // TODO: [7863] Temporary. WIP for Redux + iPad Multi-window.
        return tabManagers[WindowData.DefaultSingleWindowUUID]!
    }
}
