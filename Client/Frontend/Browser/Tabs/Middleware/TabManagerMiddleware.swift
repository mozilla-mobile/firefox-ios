// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import TabDataStore
import Shared
import Storage

class TabManagerMiddleware {
    var selectedPanel: TabTrayPanelType = .tabs
    private let windowManager: WindowManager
    private let profile: Profile

    var normalTabsCountText: String {
        (defaultTabManager.normalTabs.count < 100) ? defaultTabManager.normalTabs.count.description : "\u{221E}"
    }

    init(windowManager: WindowManager = AppContainer.shared.resolve(),
         profile: Profile = AppContainer.shared.resolve()) {
        self.windowManager = windowManager
        self.profile = profile
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
            self.closeTabFromTabPanel(with: tabUUID)

        case TabPanelAction.undoClose:
            guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel) else { return }
            self.undoCloseTab()
            let tabs = self.refreshTabs(for: tabsState.isPrivateMode)
            store.dispatch(TabPanelAction.refreshTab(tabs))

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

        case TabPanelAction.undoCloseAllTabs:
            // TODO: FXIOS-7978 Handle Undo close all tabs
            break

        case TabPanelAction.selectTab(let tabUUID):
            self.selectTab(for: tabUUID)
            store.dispatch(TabTrayAction.dismissTabTray)

        case TabPanelAction.closeAllInactiveTabs:
            guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel) else { return }
            Task {
                await self.closeAllInactiveTabs()
                store.dispatch(TabPanelAction.refreshInactiveTabs([InactiveTabsModel]()))
                store.dispatch(TabPanelAction.showToast(.allInactiveTabs(count: tabsState.inactiveTabs.count)))
            }

        case TabPanelAction.undoCloseAllInactiveTabs:
            self.undoCloseAllInactiveTabs()
            let inactiveTabs = self.refreshInactiveTabs()
            store.dispatch(TabPanelAction.refreshInactiveTabs(inactiveTabs))

        case TabPanelAction.closeInactiveTabs(let tabUUID):
            guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel) else { return }
            Task {
                await self.closeInactiveTab(for: tabUUID, inactiveTabs: tabsState.inactiveTabs)
                let inactiveTabs = self.refreshInactiveTabs()
                store.dispatch(TabPanelAction.refreshInactiveTabs(inactiveTabs))
                store.dispatch(TabPanelAction.showToast(.singleInactiveTabs))
            }

        case TabPanelAction.undoCloseInactiveTab:
            self.undoCloseInactiveTab()
            let inactiveTabs = self.refreshInactiveTabs()
            store.dispatch(TabPanelAction.refreshInactiveTabs(inactiveTabs))

        case TabPanelAction.learnMorePrivateMode(let urlRequest):
            self.didTapLearnMoreAboutPrivate(with: urlRequest)
            let tabs = self.refreshTabs(for: true)
            store.dispatch(TabPanelAction.refreshTab(tabs))
            store.dispatch(TabTrayAction.dismissTabTray)

        case RemoteTabsPanelAction.openSelectedURL(let url):
            let urlRequest = URLRequest(url: url)
            self.addNewTab(with: urlRequest, isPrivate: false)
            store.dispatch(TabTrayAction.dismissTabTray)

        case TabPeekAction.didLoadTabPeek(let tabID):
            self.didLoadTabPeek(tabID: tabID)

        case TabPeekAction.addToBookmarks(let tabID):
            self.addToBookmarks(with: tabID)

        case TabPeekAction.sendToDevice(let tabID):
            self.sendToDevice(tabID: tabID)

        case TabPeekAction.copyURL(let tabID):
            self.copyURL(tabID: tabID)

        case TabPeekAction.closeTab(let tabID):
            self.tabPeekCloseTab(with: tabID)
        default:
            break
        }
    }

    func getTabTrayModel(for panelType: TabTrayPanelType) -> TabTrayModel {
        selectedPanel = panelType

        let isPrivate = panelType == .privateTabs
        return TabTrayModel(isPrivateMode: isPrivate,
                            selectedPanel: panelType,
                            normalTabsCount: normalTabsCountText,
                            hasSyncableAccount: false)
    }

    func getTabsDisplayModel(for isPrivateMode: Bool) -> TabDisplayModel {
        let tabs = refreshTabs(for: isPrivateMode)
        let inactiveTabs = refreshInactiveTabs(for: isPrivateMode)
        let tabDisplayModel = TabDisplayModel(isPrivateMode: isPrivateMode,
                                              tabs: tabs,
                                              normalTabsCount: normalTabsCountText,
                                              inactiveTabs: inactiveTabs,
                                              isInactiveTabsExpanded: false)
        return tabDisplayModel
    }

    private func refreshTabs(for isPrivateMode: Bool) -> [TabModel] {
        var tabs = [TabModel]()
        let selectedTab = defaultTabManager.selectedTab
        let tabManagerTabs = isPrivateMode ? defaultTabManager.privateTabs : defaultTabManager.normalActiveTabs
        tabManagerTabs.forEach { tab in
            let tabModel = TabModel(tabUUID: tab.tabUUID,
                                    isSelected: tab == selectedTab,
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

    private func undoCloseTab() {
        guard let backupTab = defaultTabManager.backupCloseTab else { return }
        defaultTabManager.undoCloseTab(tab: backupTab.tab, position: backupTab.restorePosition)
    }

    private func closeAllTabs(isPrivateMode: Bool) async {
        await defaultTabManager.removeAllTabs(isPrivateMode: isPrivateMode)
    }

    private func closeTabFromTabPanel(with tabUUID: String) {
        Task {
            let shouldDismiss = await self.closeTab(with: tabUUID)
            self.triggerRefresh(with: shouldDismiss)
        }
    }

    private func triggerRefresh(with shouldDismiss: Bool) {
        let isPrivate = defaultTabManager.selectedTab?.isPrivate ?? false
        let tabs = self.refreshTabs(for: isPrivate)

        ensureMainThread {
            store.dispatch(TabPanelAction.refreshTab(tabs))
            if shouldDismiss {
                // TODO: FXIOS-7978 Handle Undo close last regular tab
                store.dispatch(TabTrayAction.dismissTabTray)
            } else {
                store.dispatch(TabPanelAction.showToast(.singleTab))
            }
        }
    }

    // MARK: - Inactive tabs helper
    private func closeAllInactiveTabs() async {
        await defaultTabManager.removeAllInactiveTabs()
    }

    private func undoCloseAllInactiveTabs() {
        ensureMainThread {
            self.defaultTabManager.undoCloseInactiveTabs()
        }
    }

    private func closeInactiveTab(for tabUUID: String, inactiveTabs: [InactiveTabsModel]) async {
        if let tabToClose = defaultTabManager.getTabForUUID(uuid: tabUUID) {
            let index = inactiveTabs.firstIndex { $0.tabUUID == tabUUID }
            defaultTabManager.backupCloseTab = BackupCloseTab(tab: tabToClose, restorePosition: index)
        }
        await defaultTabManager.removeTab(tabUUID)
    }

    private func undoCloseInactiveTab() {
        guard let backupTab = defaultTabManager.backupCloseTab else { return }

        defaultTabManager.undoCloseTab(tab: backupTab.tab, position: backupTab.restorePosition)
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

    // MARK: - Tab Peek

    private func didLoadTabPeek(tabID: String) {
        let tab = defaultTabManager.getTabForUUID(uuid: tabID)
        profile.places.isBookmarked(url: tab?.url?.absoluteString ?? "") >>== { isBookmarked in
            var canBeSaved = true
            if isBookmarked || (tab?.urlIsTooLong ?? false) || (tab?.isFxHomeTab ?? false) {
                canBeSaved = false
            }
            let browserProfile = self.profile as? BrowserProfile
            browserProfile?.tabs.getClientGUIDs { (result, error) in
                let model = TabPeekModel(canTabBeSaved: canBeSaved,
                                         isSyncEnabled: !(result?.isEmpty ?? true),
                                         screenshot: tab?.screenshot ?? UIImage(),
                                         accessiblityLabel: tab?.webView?.accessibilityLabel ?? "")
                store.dispatch(TabPeekAction.loadTabPeek(tabPeekModel: model))
            }
        }
    }

    private func addToBookmarks(with tabID: String) {
        guard let tab = defaultTabManager.getTabForUUID(uuid: tabID),
              let url = tab.url?.absoluteString, !url.isEmpty
        else { return }

        var title = (tab.tabState.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            title = url
        }
        let shareItem = ShareItem(url: url, title: title)
        // Add new mobile bookmark at the top of the list
        profile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID,
                                      url: shareItem.url,
                                      title: shareItem.title,
                                      position: 0)

        var userData = [QuickActionInfos.tabURLKey: shareItem.url]
        if let title = shareItem.title {
            userData[QuickActionInfos.tabTitleKey] = title
        }
        QuickActionsImplementation().addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                             withUserData: userData,
                                                                             toApplication: .shared)

        store.dispatch(TabPanelAction.showToast(.addBookmark))

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .add,
                                     object: .bookmark,
                                     value: .tabTray)
    }

    private func sendToDevice(tabID: String) {}

    private func copyURL(tabID: String) {
        UIPasteboard.general.url = defaultTabManager.selectedTab?.canonicalURL
        store.dispatch(TabPanelAction.showToast(.copyURL))
    }

    private func tabPeekCloseTab(with tabID: String) {
        Task {
            let shouldDismiss = await self.closeTab(with: tabID)
            self.triggerRefresh(with: shouldDismiss)
        }
    }
}
