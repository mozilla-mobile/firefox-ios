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
    private let profile: Profile
    private let logger: Logger

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.logger = logger
    }

    lazy var tabsPanelProvider: Middleware<AppState> = { state, action in
        let uuid = action.windowUUID
        switch action {
        case TabTrayAction.tabTrayDidLoad(let context):
            let panelType = context.panelType
            let tabTrayModel = self.getTabTrayModel(for: panelType, window: uuid)
            let context = TabTrayModelContext(tabTrayModel: tabTrayModel, windowUUID: uuid)
            store.dispatch(TabTrayAction.didLoadTabTray(context))

        case TabPanelAction.tabPanelDidLoad(let context):
            let isPrivate = context.boolValue
            let tabState = self.getTabsDisplayModel(for: isPrivate, shouldScrollToTab: true, uuid: uuid)
            let context = TabDisplayModelContext(tabDisplayModel: tabState, windowUUID: uuid)
            store.dispatch(TabPanelAction.didLoadTabPanel(context))

        case TabTrayAction.changePanel(let context):
            self.changePanel(context.panelType, uuid: uuid)

        case TabPanelAction.addNewTab(let context):
            let urlRequest = context.urlRequest
            let isPrivateMode = context.isPrivate
            self.addNewTab(with: urlRequest, isPrivate: isPrivateMode, for: uuid)

        case TabPanelAction.moveTab(let context):
            let originIndex = context.originIndex
            let destinationIndex = context.destinationIndex
            self.moveTab(state: state, from: originIndex, to: destinationIndex, uuid: uuid)

        case TabPanelAction.closeTab(let context):
            let tabUUID = context.tabUUID
            self.closeTabFromTabPanel(with: tabUUID, uuid: uuid)

        case TabPanelAction.undoClose:
            self.undoCloseTab(state: state, uuid: uuid)

        case TabPanelAction.confirmCloseAllTabs:
            self.closeAllTabs(state: state, uuid: uuid)

        case TabPanelAction.undoCloseAllTabs:
            self.tabManager(for: uuid).undoCloseAllTabs()

        case TabPanelAction.selectTab(let context):
            let tabUUID = context.tabUUID
            self.selectTab(for: tabUUID, uuid: uuid)
            store.dispatch(TabTrayAction.dismissTabTray(uuid.context))

        case TabPanelAction.closeAllInactiveTabs:
            self.closeAllInactiveTabs(state: state, uuid: uuid)

        case TabPanelAction.undoCloseAllInactiveTabs:
            self.undoCloseAllInactiveTabs(uuid: uuid)

        case TabPanelAction.closeInactiveTabs(let context):
            let tabUUID = context.tabUUID
            self.closeInactiveTab(for: tabUUID, state: state, uuid: uuid)

        case TabPanelAction.undoCloseInactiveTab:
            self.undoCloseInactiveTab(uuid: uuid)

        case TabPanelAction.learnMorePrivateMode(let context):
            let urlRequest = context.urlRequest
            self.didTapLearnMoreAboutPrivate(with: urlRequest, uuid: uuid)

        case RemoteTabsPanelAction.openSelectedURL(let context):
            let url = context.url
            let uuid = context.windowUUID
            self.openSelectedURL(url: url, windowUUID: uuid)

        case TabPeekAction.didLoadTabPeek(let context):
            let tabID = context.tabUUID
            self.didLoadTabPeek(tabID: tabID, uuid: uuid)

        case TabPeekAction.addToBookmarks(let context):
            let tabID = context.tabUUID
            self.addToBookmarks(with: tabID, uuid: uuid)

        case TabPeekAction.sendToDevice(let context):
            let tabID = context.tabUUID
            self.sendToDevice(tabID: tabID, uuid: uuid)

        case TabPeekAction.copyURL(let context):
            let tabID = context.tabUUID
            self.copyURL(tabID: tabID, uuid: uuid)

        case TabPeekAction.closeTab(let context):
            let tabID = context.tabUUID
            self.tabPeekCloseTab(with: tabID, uuid: uuid)
            let context = ToastTypeContext(toastType: .singleTab, windowUUID: uuid)
            store.dispatch(TabPanelAction.showToast(context))
        default:
            break
        }
    }

    private func normalTabsCountText(for windowUUID: WindowUUID) -> String {
        let tabManager = tabManager(for: windowUUID)
        return (tabManager.normalTabs.count < 100) ? tabManager.normalTabs.count.description : "\u{221E}"
    }

    private func openSelectedURL(url: URL, windowUUID: WindowUUID) {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .open,
                                     object: .syncTab)
        let urlRequest = URLRequest(url: url)
        self.addNewTab(with: urlRequest, isPrivate: false, for: windowUUID)
        store.dispatch(TabTrayAction.dismissTabTray(windowUUID.context))
    }

    /// Gets initial state for TabTrayModel includes panelType, if is on Private mode,
    /// normalTabsCountText and if syncAccount is enabled
    /// 
    /// - Parameter panelType: The selected panelType
    /// - Returns: Initial state of TabTrayModel
    private func getTabTrayModel(for panelType: TabTrayPanelType, window: WindowUUID) -> TabTrayModel {
        selectedPanel = panelType

        let isPrivate = panelType == .privateTabs
        return TabTrayModel(isPrivateMode: isPrivate,
                            selectedPanel: panelType,
                            normalTabsCount: normalTabsCountText(for: window),
                            hasSyncableAccount: false)
    }

    /// Gets initial model for TabDisplay from `TabManager`, including list of tabs and inactive tabs.
    /// - Parameter isPrivateMode: if Private mode is enabled or not
    /// - Returns:  initial model for `TabDisplayPanel`
    private func getTabsDisplayModel(for isPrivateMode: Bool,
                                     shouldScrollToTab: Bool,
                                     uuid: WindowUUID) -> TabDisplayModel {
        let tabs = refreshTabs(for: isPrivateMode, uuid: uuid)
        let inactiveTabs = refreshInactiveTabs(for: isPrivateMode, uuid: uuid)
        let tabDisplayModel = TabDisplayModel(isPrivateMode: isPrivateMode,
                                              tabs: tabs,
                                              normalTabsCount: normalTabsCountText(for: uuid),
                                              inactiveTabs: inactiveTabs,
                                              isInactiveTabsExpanded: false,
                                              shouldScrollToTab: shouldScrollToTab)
        return tabDisplayModel
    }

    /// Gets the list of tabs from `TabManager` and builds the array of TabModel to use in TabDisplayView
    /// - Parameter isPrivateMode: is on Private mode or not
    /// - Returns: Array of TabModel used to configure collection view
    private func refreshTabs(for isPrivateMode: Bool, uuid: WindowUUID) -> [TabModel] {
        var tabs = [TabModel]()
        let tabManager = tabManager(for: uuid)
        let selectedTab = tabManager.selectedTab
        let tabManagerTabs = isPrivateMode ? tabManager.privateTabs : tabManager.normalActiveTabs
        tabManagerTabs.forEach { tab in
            let tabModel = TabModel(tabUUID: tab.tabUUID,
                                    isSelected: tab == selectedTab,
                                    isPrivate: tab.isPrivate,
                                    isFxHomeTab: tab.isFxHomeTab,
                                    tabTitle: tab.displayTitle,
                                    url: tab.url,
                                    screenshot: tab.screenshot,
                                    hasHomeScreenshot: tab.hasHomeScreenshot)
            tabs.append(tabModel)
        }

        return tabs
    }

    /// Gets the list of inactive tabs from `TabManager` and builds the array of InactiveTabsModel
    /// to use in TabDisplayView
    ///
    /// - Parameter isPrivateMode: is on Private mode or not
    /// - Returns: Array of InactiveTabsModel used to configure collection view
    private func refreshInactiveTabs(for isPrivateMode: Bool = false, uuid: WindowUUID) -> [InactiveTabsModel] {
        guard !isPrivateMode else { return [InactiveTabsModel]() }

        let tabManager = tabManager(for: uuid)
        var inactiveTabs = [InactiveTabsModel]()
        for tab in tabManager.getInactiveTabs() {
            let inactiveTab = InactiveTabsModel(tabUUID: tab.tabUUID,
                                                title: tab.displayTitle,
                                                url: tab.url,
                                                favIconURL: tab.faviconURL)
            inactiveTabs.append(inactiveTab)
        }
        return inactiveTabs
    }

    /// Creates a new tab in `TabManager` using optional `URLRequest`
    ///
    /// - Parameters:
    ///   - urlRequest: URL request to load
    ///   - isPrivate: if the tab should be created in private mode or not
    private func addNewTab(with urlRequest: URLRequest?, isPrivate: Bool, for uuid: WindowUUID) {
        // TODO: Legacy class has a guard to cancel adding new tab if dragging was enabled,
        // check if change is still needed
        let tabManager = tabManager(for: uuid)
        let tab = tabManager.addTab(urlRequest, isPrivate: isPrivate)
        tabManager.selectTab(tab)

        let model = getTabsDisplayModel(for: isPrivate, shouldScrollToTab: true, uuid: uuid)
        store.dispatch(TabPanelAction.refreshTab(RefreshTabContext(tabDisplayModel: model, windowUUID: uuid)))
        store.dispatch(TabTrayAction.dismissTabTray(uuid.context))
    }

    /// Move tab on `TabManager` array to support drag and drop
    ///
    /// - Parameters:
    ///   - originIndex: from original position
    ///   - destinationIndex: to destination position
    private func moveTab(state: AppState,
                         from originIndex: Int,
                         to destinationIndex: Int,
                         uuid: WindowUUID) {
        guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel, window: nil) else { return }

        let tabManager = tabManager(for: uuid)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .drop,
                                     object: .tab,
                                     value: .tabTray)
        tabManager.moveTab(isPrivate: false, fromIndex: originIndex, toIndex: destinationIndex)

        let model = getTabsDisplayModel(for: tabsState.isPrivateMode, shouldScrollToTab: false, uuid: uuid)
        let context = RefreshTabContext(tabDisplayModel: model, windowUUID: uuid)
        store.dispatch(TabPanelAction.refreshTab(context))
    }

    /// Async close single tab. If is the last tab the Tab Tray is dismissed and undo
    /// option is presented in Homepage
    ///
    /// - Parameters:
    ///   - tabUUID: UUID of the tab to be closed/removed
    /// - Returns: If is the last tab to be closed used to trigger dismissTabTray action
    private func closeTab(with tabUUID: String, uuid: WindowUUID) async -> Bool {
        let tabManager = tabManager(for: uuid)
        let isLastTab = tabManager.normalTabs.count == 1
        await tabManager.removeTab(tabUUID)
        return isLastTab
    }

    /// Close tab and trigger refresh
    /// - Parameter tabUUID: UUID of the tab to be closed/removed
    private func closeTabFromTabPanel(with tabUUID: String, uuid: WindowUUID) {
        Task {
            let shouldDismiss = await self.closeTab(with: tabUUID, uuid: uuid)
            await self.triggerRefresh(shouldScrollToTab: false, uuid: uuid)
            if shouldDismiss {
                store.dispatch(TabTrayAction.dismissTabTray(uuid.context))
                store.dispatch(GeneralBrowserAction.showToast(ToastTypeContext(toastType: .singleTab, windowUUID: uuid)))
            } else {
                store.dispatch(TabPanelAction.showToast(ToastTypeContext(toastType: .singleTab, windowUUID: uuid)))
            }
        }
    }

    /// Trigger refreshTabs action after a change in `TabManager`
    @MainActor
    private func triggerRefresh(shouldScrollToTab: Bool, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        let isPrivate = tabManager.selectedTab?.isPrivate ?? false
        let model = getTabsDisplayModel(for: isPrivate, shouldScrollToTab: shouldScrollToTab, uuid: uuid)
        let context = RefreshTabContext(tabDisplayModel: model, windowUUID: uuid)
        store.dispatch(TabPanelAction.refreshTab(context))
    }

    /// Handles undoing the close tab action, gets the backup tab from `TabManager`
    private func undoCloseTab(state: AppState, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel, window: nil),
              let backupTab = tabManager.backupCloseTab
        else { return }

        tabManager.undoCloseTab(tab: backupTab.tab, position: backupTab.restorePosition)

        let model = getTabsDisplayModel(for: tabsState.isPrivateMode, shouldScrollToTab: false, uuid: uuid)
        let context = RefreshTabContext(tabDisplayModel: model, windowUUID: uuid)
        store.dispatch(TabPanelAction.refreshTab(context))
    }

    private func closeAllTabs(state: AppState, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel, window: nil) else { return }
        Task {
            let count = tabManager.tabs.count
            await tabManager.removeAllTabs(isPrivateMode: tabsState.isPrivateMode)

            ensureMainThread { [self] in
                let model = getTabsDisplayModel(for: tabsState.isPrivateMode, shouldScrollToTab: false, uuid: uuid)
                let context = RefreshTabContext(tabDisplayModel: model, windowUUID: uuid)
                store.dispatch(TabPanelAction.refreshTab(context))
                store.dispatch(TabTrayAction.dismissTabTray(uuid.context))
                store.dispatch(GeneralBrowserAction.showToast(ToastTypeContext(toastType: .allTabs(count: count),
                                                                               windowUUID: uuid)))
            }
        }
    }

    /// Handles undo close all tabs. Adds back all tabs depending on mode
    ///
    /// - Parameter isPrivateMode: if private mode is active or not
    private func undoCloseAllTabs(isPrivateMode: Bool, uuid: WindowUUID) {
        // TODO: FXIOS-7978 Handle Undo close all tabs
        let tabManager = tabManager(for: uuid)
        tabManager.undoCloseAllTabs()
    }

    // MARK: - Inactive tabs helper

    /// Close all inactive tabs removing them from the tabs array on `TabManager`.
    /// Makes a backup of tabs to be deleted in case undo option is selected
    private func closeAllInactiveTabs(state: AppState, uuid: WindowUUID) {
        guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel, window: nil) else { return }
        let tabManager = tabManager(for: uuid)
        Task {
            await tabManager.removeAllInactiveTabs()
            let context = RefreshInactiveTabsContext(tabModels: [InactiveTabsModel](), windowUUID: uuid)
            store.dispatch(TabPanelAction.refreshInactiveTabs(context))
            let toastContext = ToastTypeContext(toastType: .allInactiveTabs(count: tabsState.inactiveTabs.count),
                                                windowUUID: uuid)
            store.dispatch(TabPanelAction.showToast(toastContext))
        }
    }

    /// Handles undo close all inactive tabs. Adding back the backup tabs saved previously
    private func undoCloseAllInactiveTabs(uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        ensureMainThread {
            tabManager.undoCloseInactiveTabs()
            let inactiveTabs = self.refreshInactiveTabs(uuid: uuid)
            let context = RefreshInactiveTabsContext(tabModels: inactiveTabs, windowUUID: uuid)
            store.dispatch(TabPanelAction.refreshInactiveTabs(context))
        }
    }

    private func closeInactiveTab(for tabUUID: String, state: AppState, uuid: WindowUUID) {
        guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel, window: nil) else { return }
        let tabManager = tabManager(for: uuid)
        Task {
            if let tabToClose = tabManager.getTabForUUID(uuid: tabUUID) {
                let index = tabsState.inactiveTabs.firstIndex { $0.tabUUID == tabUUID }
                tabManager.backupCloseTab = BackupCloseTab(tab: tabToClose, restorePosition: index)
            }
            await tabManager.removeTab(tabUUID)

            let inactiveTabs = self.refreshInactiveTabs(uuid: uuid)
            let context = RefreshInactiveTabsContext(tabModels: inactiveTabs, windowUUID: uuid)
            store.dispatch(TabPanelAction.refreshInactiveTabs(context))
            let toastContext = ToastTypeContext(toastType: .singleInactiveTabs, windowUUID: uuid)
            store.dispatch(TabPanelAction.showToast(toastContext))
        }
    }

    private func undoCloseInactiveTab(uuid: WindowUUID) {
        let windowTabManager = self.tabManager(for: uuid)
        guard let backupTab = windowTabManager.backupCloseTab else { return }

        windowTabManager.undoCloseTab(tab: backupTab.tab, position: backupTab.restorePosition)
        let inactiveTabs = self.refreshInactiveTabs(uuid: uuid)
        let context = RefreshInactiveTabsContext(tabModels: inactiveTabs, windowUUID: uuid)
        store.dispatch(TabPanelAction.refreshInactiveTabs(context))
    }

    private func didTapLearnMoreAboutPrivate(with urlRequest: URLRequest, uuid: WindowUUID) {
        addNewTab(with: urlRequest, isPrivate: true, for: uuid)
        let model = getTabsDisplayModel(for: true, shouldScrollToTab: false, uuid: uuid)
        let context = RefreshTabContext(tabDisplayModel: model, windowUUID: uuid)
        store.dispatch(TabPanelAction.refreshTab(context))
        store.dispatch(TabTrayAction.dismissTabTray(uuid.context))
    }

    private func selectTab(for tabUUID: String, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tab = tabManager.getTabForUUID(uuid: tabUUID) else { return }

        tabManager.selectTab(tab)
    }

    private func tabManager(for uuid: WindowUUID) -> TabManager {
        let windowManager: WindowManager = AppContainer.shared.resolve()
        guard uuid != .unavailable else {
            assertionFailure()
            logger.log("Unexpected or unavailable UUID for TabManager. Returning active window tab manager by default.",
                       level: .warning,
                       category: .tabs)
            return windowManager.tabManager(for: windowManager.activeWindow)
        }

        return windowManager.tabManager(for: uuid)
    }

    // MARK: - Tab Peek

    private func didLoadTabPeek(tabID: String, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        let tab = tabManager.getTabForUUID(uuid: tabID)
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
                let context = TabPeekModelContext(tabPeekModel: model, windowUUID: uuid)
                store.dispatch(TabPeekAction.loadTabPeek(context))
            }
        }
    }

    private func addToBookmarks(with tabID: String, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tab = tabManager.getTabForUUID(uuid: tabID),
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

        let toastContext = ToastTypeContext(toastType: .addBookmark, windowUUID: uuid)
        store.dispatch(TabPanelAction.showToast(toastContext))

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .add,
                                     object: .bookmark,
                                     value: .tabTray)
    }

    private func sendToDevice(tabID: String, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tabToShare = tabManager.getTabForUUID(uuid: tabID),
              let url = tabToShare.url
        else { return }

        store.dispatch(TabPanelAction.showShareSheet(URLContext(url: url, windowUUID: uuid)))
    }

    private func copyURL(tabID: String, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        UIPasteboard.general.url = tabManager.selectedTab?.canonicalURL
        let context = ToastTypeContext(toastType: .copyURL, windowUUID: uuid)
        store.dispatch(TabPanelAction.showToast(context))
    }

    private func tabPeekCloseTab(with tabID: String, uuid: WindowUUID) {
        closeTabFromTabPanel(with: tabID, uuid: uuid)
    }

    private func changePanel(_ panel: TabTrayPanelType, uuid: WindowUUID) {
        self.trackPanelChange(panel)
        let isPrivate = panel == TabTrayPanelType.privateTabs
        let tabState = self.getTabsDisplayModel(for: isPrivate, shouldScrollToTab: false, uuid: uuid)
        if panel != .syncedTabs {
            let context = TabDisplayModelContext(tabDisplayModel: tabState, windowUUID: uuid)
            store.dispatch(TabPanelAction.didLoadTabPanel(context))
        }
    }

    private func trackPanelChange(_ panel: TabTrayPanelType) {
        switch panel {
        case .tabs:
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .tap,
                object: .privateBrowsingButton,
                extras: ["is-private": false.description])
        case .privateTabs:
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .tap,
                object: .privateBrowsingButton,
                extras: ["is-private": true.description])
        case .syncedTabs:
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .tap,
                                         object: .libraryPanel,
                                         value: .syncPanel,
                                         extras: nil)
        }
    }
}
