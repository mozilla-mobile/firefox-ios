// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import TabDataStore
import Shared
import Storage

import enum MozillaAppServices.BookmarkRoots

class TabManagerMiddleware {
    private let profile: Profile
    private let logger: Logger

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.logger = logger
    }

    lazy var tabsPanelProvider: Middleware<AppState> = { state, action in
        if let action = action as? TabPeekAction {
            self.resolveTabPeekActions(action: action, state: state)
        } else if let action = action as? RemoteTabsPanelAction {
            self.resolveRemoteTabsPanelActions(action: action, state: state)
        } else if let action = action as? TabTrayAction {
            self.resolveTabTrayActions(action: action, state: state)
        } else if let action = action as? TabPanelViewAction {
            self.resovleTabPanelViewActions(action: action, state: state)
        } else if let action = action as? MainMenuAction {
            self.resolveMainMenuActions(with: action, appState: state)
        } else if let action = action as? HeaderAction {
            self.resolveHomepageHeaderActions(with: action)
        }
    }

    private func resolveTabPeekActions(action: TabPeekAction, state: AppState) {
        guard let tabUUID = action.tabUUID else { return }
        switch action.actionType {
        case TabPeekActionType.didLoadTabPeek:
            didLoadTabPeek(tabID: tabUUID, uuid: action.windowUUID)

        case TabPeekActionType.addToBookmarks:
            addToBookmarks(with: tabUUID, uuid: action.windowUUID)

        case TabPeekActionType.copyURL:
            copyURL(tabID: tabUUID, uuid: action.windowUUID)

        case TabPeekActionType.closeTab:
            // TODO: verify if this works for closing a tab from an unselected tab panel
            guard let tabsState = state.screenState(TabsPanelState.self,
                                                    for: .tabsPanel,
                                                    window: action.windowUUID) else { return }
            tabPeekCloseTab(with: tabUUID,
                            uuid: action.windowUUID,
                            isPrivate: tabsState.isPrivateMode)
        default:
            break
        }
    }

    private func resolveRemoteTabsPanelActions(action: RemoteTabsPanelAction, state: AppState) {
        switch action.actionType {
        case RemoteTabsPanelActionType.openSelectedURL:
            guard let url = action.url else { return }
            openSelectedURL(url: url, windowUUID: action.windowUUID)

        default:
            break
        }
    }

    private func resolveTabTrayActions(action: TabTrayAction, state: AppState) {
        switch action.actionType {
        case TabTrayActionType.tabTrayDidLoad:
            tabTrayDidLoad(for: action.windowUUID, panelType: action.panelType)

        case TabTrayActionType.changePanel:
            guard let panelType = action.panelType else { return }
            changePanel(panelType, uuid: action.windowUUID)

        default:
            break
        }
    }

    private func resovleTabPanelViewActions(action: TabPanelViewAction, state: AppState) {
        switch action.actionType {
        case TabPanelViewActionType.tabPanelDidLoad:
            let isPrivate = action.panelType == .privateTabs
            let tabState = self.getTabsDisplayModel(
                for: isPrivate,
                uuid: action.windowUUID
            )
            let action = TabPanelMiddlewareAction(tabDisplayModel: tabState,
                                                  scrollBehavior: .scrollToSelectedTab(shouldAnimate: false),
                                                  windowUUID: action.windowUUID,
                                                  actionType: TabPanelMiddlewareActionType.didLoadTabPanel)
            store.dispatch(action)

        case TabPanelViewActionType.tabPanelWillAppear:
            let isPrivate = action.panelType == .privateTabs
            let tabState = self.getTabsDisplayModel(
                for: isPrivate,
                uuid: action.windowUUID
            )
            let action = TabPanelMiddlewareAction(tabDisplayModel: tabState,
                                                  windowUUID: action.windowUUID,
                                                  actionType: TabPanelMiddlewareActionType.willAppearTabPanel)
            store.dispatch(action)

        case TabPanelViewActionType.addNewTab:
            let isPrivateMode = action.panelType == .privateTabs
            addNewTab(with: action.urlRequest, isPrivate: isPrivateMode, for: action.windowUUID)

        case TabPanelViewActionType.moveTab:
            guard let moveTabData = action.moveTabData else { return }
            moveTab(state: state, moveTabData: moveTabData, uuid: action.windowUUID)

        case TabPanelViewActionType.closeTab:
            guard let tabUUID = action.tabUUID else { return }
            closeTabFromTabPanel(with: tabUUID,
                                 uuid: action.windowUUID,
                                 isPrivate: action.panelType == .privateTabs)

        case TabPanelViewActionType.undoClose:
            undoCloseTab(state: state, uuid: action.windowUUID)

        case TabPanelViewActionType.confirmCloseAllTabs:
            closeAllTabs(state: state, uuid: action.windowUUID)

        case TabPanelViewActionType.undoCloseAllTabs:
            undoCloseAllTabs(uuid: action.windowUUID)

        case TabPanelViewActionType.selectTab:
            guard let tabUUID = action.tabUUID else { return }
            selectTab(for: tabUUID, uuid: action.windowUUID)

        case TabPanelViewActionType.closeAllInactiveTabs:
            closeAllInactiveTabs(state: state, uuid: action.windowUUID)

        case TabPanelViewActionType.undoCloseAllInactiveTabs:
            undoCloseAllInactiveTabs(uuid: action.windowUUID)

        case TabPanelViewActionType.closeInactiveTabs:
            guard let tabUUID = action.tabUUID else { return }
            closeInactiveTab(for: tabUUID, state: state, uuid: action.windowUUID)

        case TabPanelViewActionType.undoCloseInactiveTab:
            undoCloseInactiveTab(uuid: action.windowUUID)

        case TabPanelViewActionType.learnMorePrivateMode:
            guard let urlRequest = action.urlRequest else { return }
            didTapLearnMoreAboutPrivate(with: urlRequest, uuid: action.windowUUID)

        default:
            break
        }
    }

    private func tabTrayDidLoad(for windowUUID: WindowUUID, panelType: TabTrayPanelType?) {
        let tabManager = tabManager(for: windowUUID)
        let isPrivateModeActive = tabManager.selectedTab?.isPrivate ?? false

        // If no panelType is provided then fallback to whichever tab is currently selected
        let panelType = panelType ?? (isPrivateModeActive ? .privateTabs : .tabs)
        let tabTrayModel = self.getTabTrayModel(for: panelType, window: windowUUID)
        let action = TabTrayAction(tabTrayModel: tabTrayModel,
                                   windowUUID: windowUUID,
                                   actionType: TabTrayActionType.didLoadTabTray)
        store.dispatch(action)
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
    }

    /// Gets initial state for TabTrayModel includes panelType, if is on Private mode,
    /// normalTabsCountText and if syncAccount is enabled
    /// 
    /// - Parameter panelType: The selected panelType
    /// - Returns: Initial state of TabTrayModel
    private func getTabTrayModel(for panelType: TabTrayPanelType, window: WindowUUID) -> TabTrayModel {
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
                                     uuid: WindowUUID) -> TabDisplayModel {
        let tabs = refreshTabs(for: isPrivateMode, uuid: uuid)
        let inactiveTabs = refreshInactiveTabs(for: isPrivateMode, uuid: uuid)
        let tabDisplayModel = TabDisplayModel(isPrivateMode: isPrivateMode,
                                              tabs: tabs,
                                              normalTabsCount: normalTabsCountText(for: uuid),
                                              inactiveTabs: inactiveTabs,
                                              isInactiveTabsExpanded: false)
        return tabDisplayModel
    }

    /// Gets the list of tabs from `TabManager` and builds the array of TabModel to use in TabDisplayView
    /// - Parameter isPrivateMode: is on Private mode or not
    /// - Returns: Array of TabModel used to configure collection view
    private func refreshTabs(for isPrivateMode: Bool, uuid: WindowUUID) -> [TabModel] {
        var tabs = [TabModel]()
        let tabManager = tabManager(for: uuid)
        let selectedTab = tabManager.selectedTab
        // Be careful to use active tabs and not inactive tabs
        let tabManagerTabs = isPrivateMode ? tabManager.privateTabs : tabManager.normalActiveTabs
        tabManagerTabs.forEach { tab in
            let tabModel = TabModel(tabUUID: tab.tabUUID,
                                    isSelected: tab.tabUUID == selectedTab?.tabUUID,
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

        let model = getTabsDisplayModel(for: isPrivate, uuid: uuid)
        let refreshAction = TabPanelMiddlewareAction(tabDisplayModel: model,
                                                     windowUUID: uuid,
                                                     actionType: TabPanelMiddlewareActionType.refreshTabs)
        store.dispatch(refreshAction)

        let dismissAction = TabTrayAction(windowUUID: uuid,
                                          actionType: TabTrayActionType.dismissTabTray)
        store.dispatch(dismissAction)

        let overlayAction = GeneralBrowserAction(showOverlay: true,
                                                 windowUUID: uuid,
                                                 actionType: GeneralBrowserActionType.showOverlay)
        store.dispatch(overlayAction)
    }

    /// Move tab on `TabManager` array to support drag and drop
    ///
    /// - Parameters:
    ///   - originIndex: from original position
    ///   - destinationIndex: to destination position
    private func moveTab(state: AppState,
                         moveTabData: MoveTabData,
                         uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .drop,
                                     object: .tab,
                                     value: .tabTray)
        tabManager.reorderTabs(isPrivate: moveTabData.isPrivate,
                               fromIndex: moveTabData.originIndex,
                               toIndex: moveTabData.destinationIndex)

        let model = getTabsDisplayModel(for: moveTabData.isPrivate, uuid: uuid)
        let action = TabPanelMiddlewareAction(tabDisplayModel: model,
                                              windowUUID: uuid,
                                              actionType: TabPanelMiddlewareActionType.refreshTabs)
        store.dispatch(action)
    }

    /// Async close single tab. If is the last tab the Tab Tray is dismissed and undo
    /// option is presented in Homepage
    ///
    /// - Parameters:
    ///   - tabUUID: UUID of the tab to be closed/removed
    /// - Returns: If is the last tab to be closed used to trigger dismissTabTray action
    private func closeTab(with tabUUID: TabUUID, uuid: WindowUUID, isPrivate: Bool) async -> Bool {
        let tabManager = tabManager(for: uuid)
        // In non-private mode, if:
        //      A) the last normal active tab is closed, or
        //      B) the last of ALL normal tabs are closed (i.e. all tabs are inactive and closed at once),
        // then we want to close the tray.
        let isLastActiveTab = isPrivate
                            ? tabManager.privateTabs.count == 1
                            : (tabManager.normalActiveTabs.count <= 1 || tabManager.normalTabs.count == 1)
        await tabManager.removeTab(tabUUID)
        return isLastActiveTab
    }

    /// Close tab and trigger refresh
    /// - Parameter tabUUID: UUID of the tab to be closed/removed
    private func closeTabFromTabPanel(with tabUUID: TabUUID, uuid: WindowUUID, isPrivate: Bool) {
        Task {
            let shouldDismiss = await self.closeTab(with: tabUUID, uuid: uuid, isPrivate: isPrivate)
            await self.triggerRefresh(uuid: uuid, isPrivate: isPrivate)

            if isPrivate && tabManager(for: uuid).privateTabs.isEmpty {
                let didLoadAction = TabPanelViewAction(panelType: isPrivate ? .privateTabs : .tabs,
                                                       windowUUID: uuid,
                                                       actionType: TabPanelViewActionType.tabPanelDidLoad)
                store.dispatch(didLoadAction)

                let toastAction = TabPanelMiddlewareAction(toastType: .closedSingleTab,
                                                           windowUUID: uuid,
                                                           actionType: TabPanelMiddlewareActionType.showToast)
                store.dispatch(toastAction)
            } else if shouldDismiss {
                let dismissAction = TabTrayAction(windowUUID: uuid,
                                                  actionType: TabTrayActionType.dismissTabTray)
                store.dispatch(dismissAction)

                let toastAction = GeneralBrowserAction(toastType: .closedSingleTab,
                                                       windowUUID: uuid,
                                                       actionType: GeneralBrowserActionType.showToast)
                store.dispatch(toastAction)
            } else {
                let toastAction = TabPanelMiddlewareAction(toastType: .closedSingleTab,
                                                           windowUUID: uuid,
                                                           actionType: TabPanelMiddlewareActionType.showToast)
                store.dispatch(toastAction)
            }
        }
    }

    /// Trigger refreshTabs action after a change in `TabManager`
    @MainActor
    private func triggerRefresh(uuid: WindowUUID, isPrivate: Bool) {
        let model = getTabsDisplayModel(for: isPrivate, uuid: uuid)
        let action = TabPanelMiddlewareAction(tabDisplayModel: model,
                                              windowUUID: uuid,
                                              actionType: TabPanelMiddlewareActionType.refreshTabs)
        store.dispatch(action)
    }

    /// Handles undoing the close tab action, gets the backup tab from `TabManager`
    private func undoCloseTab(state: AppState, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel, window: uuid),
              tabManager.backupCloseTab != nil
        else { return }

        tabManager.undoCloseTab()

        let model = getTabsDisplayModel(for: tabsState.isPrivateMode, uuid: uuid)
        let refreshAction = TabPanelMiddlewareAction(tabDisplayModel: model,
                                                     windowUUID: uuid,
                                                     actionType: TabPanelMiddlewareActionType.refreshTabs)
        store.dispatch(refreshAction)

        // Scroll to the restored tab so the user knows it was restored, especially if it was restored off screen
        // (e.g. restoring the tab in the last row, first column)
        let scrollBehavior: TabScrollBehavior = tabManager.backupCloseTab != nil
            ? .scrollToTab(withTabUUID: tabManager.backupCloseTab!.tab.tabUUID, shouldAnimate: true)
            : .scrollToSelectedTab(shouldAnimate: true)
        let scrollAction = TabPanelMiddlewareAction(tabDisplayModel: model,
                                                    scrollBehavior: scrollBehavior,
                                                    windowUUID: uuid,
                                                    actionType: TabPanelMiddlewareActionType.scrollToTab)
        store.dispatch(scrollAction)
    }

    private func closeAllTabs(state: AppState, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel, window: uuid) else { return }
        Task {
            let normalCount = tabManager.normalTabs.count
            let privateCount = tabManager.privateTabs.count
            await tabManager.removeAllTabs(isPrivateMode: tabsState.isPrivateMode)

            ensureMainThread { [self] in
                let model = getTabsDisplayModel(for: tabsState.isPrivateMode, uuid: uuid)
                let action = TabPanelMiddlewareAction(tabDisplayModel: model,
                                                      windowUUID: uuid,
                                                      actionType: TabPanelMiddlewareActionType.refreshTabs)
                store.dispatch(action)

                if tabsState.isPrivateMode {
                    let action = TabPanelMiddlewareAction(toastType: .closedAllTabs(count: privateCount),
                                                          windowUUID: uuid,
                                                          actionType: TabPanelMiddlewareActionType.showToast)
                    store.dispatch(action)
                } else {
                    let toastAction = GeneralBrowserAction(toastType: .closedAllTabs(count: normalCount),
                                                           windowUUID: uuid,
                                                           actionType: GeneralBrowserActionType.showToast)
                    store.dispatch(toastAction)
                }
            }
        }

        if !tabsState.isPrivateMode {
            let dismissAction = TabTrayAction(windowUUID: uuid,
                                              actionType: TabTrayActionType.dismissTabTray)
            store.dispatch(dismissAction)
        }
    }

    private func undoCloseAllTabs(uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        tabManager.undoCloseAllTabs()

        // The private tab panel is the only panel that stays open after a close all tabs action
        let model = getTabsDisplayModel(for: true, uuid: uuid)
        let refreshAction = TabPanelMiddlewareAction(tabDisplayModel: model,
                                                     windowUUID: uuid,
                                                     actionType: TabPanelMiddlewareActionType.refreshTabs)
        store.dispatch(refreshAction)

        // Scroll to the selected tab if all closed tabs are restored
        let scrollAction = TabPanelMiddlewareAction(tabDisplayModel: model,
                                                    scrollBehavior: .scrollToSelectedTab(shouldAnimate: true),
                                                    windowUUID: uuid,
                                                    actionType: TabPanelMiddlewareActionType.scrollToTab)
        store.dispatch(scrollAction)
    }

    // MARK: - Inactive tabs helper

    /// Close all inactive tabs, removing them from the tabs array on `TabManager`.
    /// Makes a backup of tabs to be deleted in case the undo option is selected.
    private func closeAllInactiveTabs(state: AppState, uuid: WindowUUID) {
        guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel, window: uuid) else { return }
        let tabManager = tabManager(for: uuid)
        Task {
            await tabManager.removeAllInactiveTabs()
            let refreshAction = TabPanelMiddlewareAction(inactiveTabModels: [InactiveTabsModel](),
                                                         windowUUID: uuid,
                                                         actionType: TabPanelMiddlewareActionType.refreshInactiveTabs)
            store.dispatch(refreshAction)

            // Refresh the active tabs panel. Can only happen if the user is in normal browsering mode (not private).
            // Related: FXIOS-10010, FXIOS-9954, FXIOS-9999
            let model = getTabsDisplayModel(for: false, uuid: uuid)
            let refreshActiveTabsPanelAction = TabPanelMiddlewareAction(tabDisplayModel: model,
                                                                        windowUUID: uuid,
                                                                        actionType: TabPanelMiddlewareActionType.refreshTabs)
            store.dispatch(refreshActiveTabsPanelAction)

            let inactiveTabsCount = tabsState.inactiveTabs.count
            let toastAction = TabPanelMiddlewareAction(toastType: .closedAllInactiveTabs(count: inactiveTabsCount),
                                                       windowUUID: uuid,
                                                       actionType: TabPanelMiddlewareActionType.showToast)
            store.dispatch(toastAction)
        }
    }

    /// Handles undo close all inactive tabs. Adding back the backup tabs saved previously
    private func undoCloseAllInactiveTabs(uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        Task {
            await tabManager.undoCloseInactiveTabs()
            let inactiveTabs = self.refreshInactiveTabs(uuid: uuid)
            let refreshAction = TabPanelMiddlewareAction(inactiveTabModels: inactiveTabs,
                                                         windowUUID: uuid,
                                                         actionType: TabPanelMiddlewareActionType.refreshInactiveTabs)
            store.dispatch(refreshAction)
        }
    }

    private func closeInactiveTab(for tabUUID: String, state: AppState, uuid: WindowUUID) {
        guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel, window: uuid) else { return }
        let tabManager = tabManager(for: uuid)
        Task {
            if let tabToClose = tabManager.getTabForUUID(uuid: tabUUID) {
                let index = tabsState.inactiveTabs.firstIndex { $0.tabUUID == tabUUID }
                tabManager.backupCloseTab = BackupCloseTab(
                    tab: tabToClose,
                    restorePosition: index,
                    isSelected: false)
            }
            await tabManager.removeTab(tabUUID)

            let inactiveTabs = self.refreshInactiveTabs(uuid: uuid)
            let refreshAction = TabPanelMiddlewareAction(inactiveTabModels: inactiveTabs,
                                                         windowUUID: uuid,
                                                         actionType: TabPanelMiddlewareActionType.refreshInactiveTabs)
            store.dispatch(refreshAction)

            let toastAction = TabPanelMiddlewareAction(toastType: .closedSingleInactiveTab,
                                                       windowUUID: uuid,
                                                       actionType: TabPanelMiddlewareActionType.showToast)
            store.dispatch(toastAction)
        }
    }

    private func undoCloseInactiveTab(uuid: WindowUUID) {
        let windowTabManager = self.tabManager(for: uuid)
        guard windowTabManager.backupCloseTab != nil else { return }

        windowTabManager.undoCloseTab()
        let inactiveTabs = self.refreshInactiveTabs(uuid: uuid)
        let refreshAction = TabPanelMiddlewareAction(inactiveTabModels: inactiveTabs,
                                                     windowUUID: uuid,
                                                     actionType: TabPanelMiddlewareActionType.refreshInactiveTabs)
        store.dispatch(refreshAction)
    }

    private func didTapLearnMoreAboutPrivate(with urlRequest: URLRequest, uuid: WindowUUID) {
        addNewTab(with: urlRequest, isPrivate: true, for: uuid)
    }

    private func selectTab(for tabUUID: TabUUID, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tab = tabManager.getTabForUUID(uuid: tabUUID) else { return }

        tabManager.selectTab(tab)

        let action = TabTrayAction(windowUUID: uuid,
                                   actionType: TabTrayActionType.dismissTabTray)
        store.dispatch(action)
    }

    private func tabManager(for uuid: WindowUUID) -> TabManager {
        let windowManager: WindowManager = AppContainer.shared.resolve()
        guard uuid != .unavailable else {
            assertionFailure()
            logger.log("Unexpected or unavailable window UUID for requested TabManager.", level: .fatal, category: .tabs)
            return windowManager.allWindowTabManagers().first!
        }

        return windowManager.tabManager(for: uuid)
    }

    // MARK: - Tab Peek

    private func didLoadTabPeek(tabID: TabUUID, uuid: WindowUUID) {
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
                let action = TabPeekAction(tabPeekModel: model,
                                           windowUUID: uuid,
                                           actionType: TabPeekActionType.loadTabPeek)
                store.dispatch(action)
            }
        }
    }

    private func addToBookmarks(with tabID: TabUUID, uuid: WindowUUID) {
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

        let toastAction = TabPanelMiddlewareAction(toastType: .addBookmark,
                                                   windowUUID: uuid,
                                                   actionType: TabPanelMiddlewareActionType.showToast)
        store.dispatch(toastAction)

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .add,
                                     object: .bookmark,
                                     value: .tabTray)
    }

    private func copyURL(tabID: TabUUID, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        UIPasteboard.general.url = tabManager.selectedTab?.canonicalURL
        let toastAction = TabPanelMiddlewareAction(toastType: .copyURL,
                                                   windowUUID: uuid,
                                                   actionType: TabPanelMiddlewareActionType.showToast)
        store.dispatch(toastAction)
    }

    private func tabPeekCloseTab(with tabID: TabUUID, uuid: WindowUUID, isPrivate: Bool) {
        closeTabFromTabPanel(with: tabID, uuid: uuid, isPrivate: isPrivate)
    }

    private func changePanel(_ panel: TabTrayPanelType, uuid: WindowUUID) {
        self.trackPanelChange(panel)
        let isPrivate = panel == TabTrayPanelType.privateTabs
        let tabState = self.getTabsDisplayModel(for: isPrivate, uuid: uuid)
        if panel != .syncedTabs {
            let action = TabPanelMiddlewareAction(tabDisplayModel: tabState,
                                                  windowUUID: uuid,
                                                  actionType: TabPanelMiddlewareActionType.didChangeTabPanel)
            store.dispatch(action)
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

    // MARK: - Main menu actions
    private func resolveMainMenuActions(with action: MainMenuAction, appState: AppState) {
        switch action.actionType {
        case MainMenuMiddlewareActionType.requestTabInfo:
            store.dispatch(
                MainMenuAction(
                    windowUUID: action.windowUUID,
                    actionType: MainMenuActionType.updateCurrentTabInfo,
                    currentTabInfo: getTabInfo(forWindow: action.windowUUID)
                )
            )
        case MainMenuActionType.toggleUserAgent:
            changeUserAgent(forWindow: action.windowUUID)
        default:
            break
        }
    }

    private func getTabInfo(forWindow windowUUID: WindowUUID) -> MainMenuTabInfo? {
        guard let selectedTab = tabManager(for: windowUUID).selectedTab else {
            logger.log(
                "Attempted to get `selectedTab` but it was `nil` when in shouldn't be",
                level: .fatal,
                category: .tabs
            )
            return nil
        }
        let defaultUAisDesktop = UserAgent.isDesktop(ua: UserAgent.getUserAgent())

        return MainMenuTabInfo(
            url: selectedTab.url,
            isHomepage: selectedTab.isFxHomeTab,
            isDefaultUserAgentDesktop: defaultUAisDesktop,
            hasChangedUserAgent: selectedTab.changedUserAgent
        )
    }

    private func changeUserAgent(forWindow windowUUID: WindowUUID) {
        guard let selectedTab = tabManager(for: windowUUID).selectedTab else { return }

        if let url = selectedTab.url {
            selectedTab.toggleChangeUserAgent()
            Tab.ChangeUserAgent.updateDomainList(
                forUrl: url,
                isChangedUA: selectedTab.changedUserAgent,
                isPrivate: selectedTab.isPrivate
            )
        }
    }

    private func resolveHomepageHeaderActions(with action: HeaderAction) {
        switch action.actionType {
        case HeaderActionType.toggleHomepageMode:
            tabManager(for: action.windowUUID).switchPrivacyMode()
        default:
            break
        }
    }
}
