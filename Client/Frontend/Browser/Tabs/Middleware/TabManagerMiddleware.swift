// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import TabDataStore

class TabManagerMiddleware {
    var selectedPanel: TabTrayPanelType = .tabs
    private let windowManager: WindowManager

    init(windowManager: WindowManager = AppContainer.shared.resolve()) {
        self.windowManager = windowManager
    }

    var normalTabsCount: String {
        (defaultTabManager.normalTabs.count < 100) ? defaultTabManager.normalTabs.count.description : "\u{221E}"
    }

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
            if panelType != .syncedTabs {
                store.dispatch(TabPanelAction.didLoadTabPanel(tabState))
            }

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
            Task {
                await self.closeAllInactiveTabs()
                let inactiveTabs = self.refreshInactiveTabs()
                store.dispatch(TabPanelAction.refreshInactiveTabs(inactiveTabs))
            }

        case TabPanelAction.closeInactiveTabs(let tabUUID):
            Task {
                await self.closeInactiveTab(for: tabUUID)
                let inactiveTabs = self.refreshInactiveTabs()
                store.dispatch(TabPanelAction.refreshInactiveTabs(inactiveTabs))
            }

        case TabPanelAction.learnMorePrivateMode(let urlRequest):
            self.didTapLearnMoreAboutPrivate(with: urlRequest)
            let tabs = self.refreshTabs(for: true)
            store.dispatch(TabPanelAction.refreshTab(tabs))
            store.dispatch(TabTrayAction.dismissTabTray)

        case RemoteTabsPanelAction.openSelectedURL(let url):
            let urlRequest = URLRequest(url: url)
            self.addNewTab(with: urlRequest, isPrivate: false)
            store.dispatch(TabTrayAction.dismissTabTray)

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
                            normalTabsCount: normalTabsCount)
    }

    func getTabsDisplayModel(for isPrivateMode: Bool) -> TabDisplayModel {
        let tabs = refreshTabs(for: isPrivateMode)
        let inactiveTabs = refreshInactiveTabs(for: isPrivateMode)
        let tabDisplayModel = TabDisplayModel(isPrivateMode: isPrivateMode,
                                              tabs: tabs,
                                              normalTabsCount: normalTabsCount,
                                              inactiveTabs: inactiveTabs,
                                              isInactiveTabsExpanded: false)
        return tabDisplayModel
    }

    private func refreshTabs(for isPrivateMode: Bool) -> [TabModel] {
        var tabs = [TabModel]()
        let tabManagerTabs = isPrivateMode ? defaultTabManager.privateTabs : defaultTabManager.normalActiveTabs
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

    private func refreshInactiveTabs(for isPrivateMode: Bool = false) -> [InactiveTabsModel] {
        guard !isPrivateMode else { return [InactiveTabsModel]() }

        var inactiveTabs = [InactiveTabsModel]()
        for tab in defaultTabManager.getInactiveTabs() {
            let inactiveTab = InactiveTabsModel(tabUUID: tab.tabUUID,
                                                title: tab.displayTitle,
                                                url: tab.url)
            inactiveTabs.append(inactiveTab)
        }
        return inactiveTabs
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
        let isLastTab = defaultTabManager.normalTabs.count == 1
        await defaultTabManager.removeTab(tabUUID)
        return isLastTab
    }

    private func closeAllTabs(isPrivateMode: Bool) async {
        await defaultTabManager.removeAllTabs(isPrivateMode: isPrivateMode)
    }

    private func closeAllInactiveTabs() async {
        await defaultTabManager.removeAllInactiveTabs()
    }

    private func closeInactiveTab(for tabUUID: String) async {
        await defaultTabManager.removeTab(tabUUID)
    }

    private func didTapLearnMoreAboutPrivate(with urlRequest: URLRequest) {
        addNewTab(with: urlRequest, isPrivate: true)
    }

    private func selectTab(for tabUUID: String) {
        guard let tab = defaultTabManager.getTabForUUID(uuid: tabUUID) else { return }

        defaultTabManager.selectTab(tab)
    }

    private var defaultTabManager: TabManager {
        // TODO: [FXIOS-7863] Temporary. WIP for Redux + iPad Multi-window.
        return windowManager.tabManager(for: windowManager.activeWindow)
    }
}
