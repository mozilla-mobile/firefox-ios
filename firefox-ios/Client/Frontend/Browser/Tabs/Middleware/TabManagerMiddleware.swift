// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import Storage

import enum MozillaAppServices.BookmarkRoots

class TabManagerMiddleware: BookmarksRefactorFeatureFlagProvider,
                            FeatureFlaggable {
    private let profile: Profile
    private let logger: Logger
    private let inactiveTabTelemetry = InactiveTabsTelemetry()
    private let bookmarksSaver: BookmarksSaver
    private let toastTelemetry: ToastTelemetry

    private var isTabTrayUIExperimentsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly)
        && UIDevice.current.userInterfaceIdiom != .pad
    }

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         bookmarksSaver: BookmarksSaver? = nil,
         gleanWrapper: GleanWrapper = DefaultGleanWrapper()
    ) {
        self.profile = profile
        self.logger = logger
        self.bookmarksSaver = bookmarksSaver ?? DefaultBookmarksSaver(profile: profile)
        self.toastTelemetry = ToastTelemetry(gleanWrapper: gleanWrapper)
    }

    lazy var tabsPanelProvider: Middleware<AppState> = { state, action in
        if let action = action as? TabPeekAction {
            self.resolveTabPeekActions(action: action, state: state)
        } else if let action = action as? RemoteTabsPanelAction {
            self.resolveRemoteTabsPanelActions(action: action, state: state)
        } else if let action = action as? TabTrayAction {
            self.resolveTabTrayActions(action: action, state: state)
        } else if let action = action as? TabPanelViewAction {
            self.resolveTabPanelViewActions(action: action, state: state)
        } else if let action = action as? MainMenuAction {
            self.resolveMainMenuActions(with: action, appState: state)
        } else if let action = action as? ScreenshotAction {
            self.resolveScreenshotActions(action: action, state: state)
        } else {
            self.resolveHomepageActions(with: action)
        }
    }

    private func resolveScreenshotActions(action: ScreenshotAction, state: AppState) {
        guard let tabsState = state.screenState(TabsPanelState.self,
                                                for: .tabsPanel,
                                                window: action.windowUUID) else { return }
        let manager = tabManager(for: action.windowUUID)
        manager.tabDidSetScreenshot(action.tab)
        triggerRefresh(uuid: action.windowUUID, isPrivate: tabsState.isPrivateMode)
    }

    private func resolveTabPeekActions(action: TabPeekAction, state: AppState) {
        guard let tabUUID = action.tabUUID else { return }
        switch action.actionType {
        case TabPeekActionType.didLoadTabPeek:
            didLoadTabPeek(tabID: tabUUID, uuid: action.windowUUID)

        case TabPeekActionType.addToBookmarks:
            let shareItem = createShareItem(with: tabUUID, and: action.windowUUID)
            addToBookmarks(shareItem)
            setBookmarkQuickActions(with: shareItem, uuid: action.windowUUID)
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
            openSelectedURL(url: url, showOverlay: false, windowUUID: action.windowUUID)
        case RemoteTabsPanelActionType.closeSelectedRemoteURL:
            guard let url = action.url, let deviceId = action.targetDeviceId else { return }
            closeSelectedRemoteTab(deviceId: deviceId, url: url, windowUUID: action.windowUUID)
        case RemoteTabsPanelActionType.undoCloseSelectedRemoteURL:
            guard let url = action.url, let deviceId = action.targetDeviceId else { return }
            undoCloseSelectedRemoteTab(deviceId: deviceId, url: url, windowUUID: action.windowUUID)
        case RemoteTabsPanelActionType.flushTabCommands:
            guard let deviceId = action.targetDeviceId else { return }
            flushTabCommands(deviceId: deviceId, windowUUID: action.windowUUID)
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

        case TabTrayActionType.closePrivateTabsSettingToggled:
            preserveTabs(uuid: action.windowUUID)

        // FXIOS-11740 - This is relate to homepage actions, so if we want to break up this middleware
        // then this action should go to the homepage specific middleware.
        case TabTrayActionType.dismissTabTray, TabTrayActionType.modalSwipedToClose, TabTrayActionType.doneButtonTapped:
            dispatchRecentlyAccessedTabs(action: action)
        default:
            break
        }
    }

    private func resolveTabPanelViewActions(action: TabPanelViewAction, state: AppState) {
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
            addNewTab(with: action.urlRequest, isPrivate: isPrivateMode, showOverlay: true, for: action.windowUUID)
            dispatchRecentlyAccessedTabs(action: action)
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
            selectTab(for: tabUUID, uuid: action.windowUUID, isInactiveTab: action.isInactiveTab ?? false)

        case TabPanelViewActionType.closeAllInactiveTabs:
            closeAllInactiveTabs(state: state, uuid: action.windowUUID)

        case TabPanelViewActionType.undoCloseAllInactiveTabs:
            undoCloseAllInactiveTabs(uuid: action.windowUUID)

        case TabPanelViewActionType.closeInactiveTab:
            guard let tabUUID = action.tabUUID else { return }
            closeInactiveTab(for: tabUUID, state: state, uuid: action.windowUUID)

        case TabPanelViewActionType.undoCloseInactiveTab:
            undoCloseInactiveTab(uuid: action.windowUUID)

        case TabPanelViewActionType.learnMorePrivateMode:
            guard let urlRequest = action.urlRequest else { return }
            didTapLearnMoreAboutPrivate(with: urlRequest, uuid: action.windowUUID)

        case TabPanelViewActionType.toggleInactiveTabs:
            guard let tabState = state.screenState(TabsPanelState.self,
                                                   for: .tabsPanel,
                                                   window: action.windowUUID)
            else { return }
            let expanded = tabState.isInactiveTabsExpanded
            inactiveTabTelemetry.sectionToggled(hasExpanded: expanded)
            break

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

    private func openSelectedURL(url: URL, showOverlay: Bool, windowUUID: WindowUUID) {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .open,
                                     object: .syncTab)
        let urlRequest = URLRequest(url: url)
        self.addNewTab(with: urlRequest, isPrivate: false, showOverlay: showOverlay, for: windowUUID)
    }

    private func closeSelectedRemoteTab(deviceId: String, url: URL, windowUUID: WindowUUID) {
        self.profile.addTabToCommandQueue(deviceId, url: url)
    }

    private func undoCloseSelectedRemoteTab(deviceId: String, url: URL, windowUUID: WindowUUID) {
        self.profile.removeTabFromCommandQueue(deviceId, url: url)
    }

    private func flushTabCommands(deviceId: String, windowUUID: WindowUUID) {
        self.profile.flushTabCommands(toDeviceId: deviceId)
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
    private func addNewTab(with urlRequest: URLRequest?, isPrivate: Bool, showOverlay: Bool, for uuid: WindowUUID) {
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

        let overlayAction = GeneralBrowserAction(showOverlay: showOverlay,
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
    @MainActor
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
        Task { @MainActor in
            let shouldDismiss = await self.closeTab(with: tabUUID, uuid: uuid, isPrivate: isPrivate)
            triggerRefresh(uuid: uuid, isPrivate: isPrivate)

            if isPrivate && tabManager(for: uuid).privateTabs.isEmpty {
                let didLoadAction = TabPanelViewAction(panelType: isPrivate ? .privateTabs : .tabs,
                                                       windowUUID: uuid,
                                                       actionType: TabPanelViewActionType.tabPanelDidLoad)
                store.dispatch(didLoadAction)

                if !isTabTrayUIExperimentsEnabled {
                    let toastAction = TabPanelMiddlewareAction(toastType: .closedSingleTab,
                                                               windowUUID: uuid,
                                                               actionType: TabPanelMiddlewareActionType.showToast)
                    store.dispatch(toastAction)
                }
            } else if shouldDismiss {
                let dismissAction = TabTrayAction(windowUUID: uuid,
                                                  actionType: TabTrayActionType.dismissTabTray)
                store.dispatch(dismissAction)

                if !isTabTrayUIExperimentsEnabled {
                    let toastAction = GeneralBrowserAction(toastType: .closedSingleTab,
                                                           windowUUID: uuid,
                                                           actionType: GeneralBrowserActionType.showToast)
                    store.dispatch(toastAction)
                }
                addNewTabIfPrivate(uuid: uuid)
            } else if !isTabTrayUIExperimentsEnabled {
                let toastAction = TabPanelMiddlewareAction(toastType: .closedSingleTab,
                                                           windowUUID: uuid,
                                                           actionType: TabPanelMiddlewareActionType.showToast)
                store.dispatch(toastAction)
            }
        }
    }

    private func setBookmarkQuickActions(with shareItem: ShareItem?, uuid: WindowUUID) {
        guard let shareItem else { return }

        var userData = [QuickActionInfos.tabURLKey: shareItem.url]
        if let title = shareItem.title {
            userData[QuickActionInfos.tabTitleKey] = title
        }

        QuickActionsImplementation().addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                             withUserData: userData,
                                                                             toApplication: .shared)

        // The Tab Tray uses a "SimpleToast", so the urlString will go unused
        let toastAction = TabPanelMiddlewareAction(toastType: .addBookmark(urlString: shareItem.url),
                                                   windowUUID: uuid,
                                                   actionType: TabPanelMiddlewareActionType.showToast)
        store.dispatch(toastAction)

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .add,
                                     object: .bookmark,
                                     value: .tabTray)
    }

    /// Trigger refreshTabs action after a change in `TabManager`
    private func triggerRefresh(uuid: WindowUUID, isPrivate: Bool) {
        let model = getTabsDisplayModel(for: isPrivate, uuid: uuid)
        let action = TabPanelMiddlewareAction(tabDisplayModel: model,
                                              windowUUID: uuid,
                                              actionType: TabPanelMiddlewareActionType.refreshTabs)
        store.dispatch(action)
    }

    /// Handles undoing the close tab action, gets the backup tab from `TabManager`
    private func undoCloseTab(state: AppState, uuid: WindowUUID) {
        toastTelemetry.undoClosedSingleTab()
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

                if tabsState.isPrivateMode && !isTabTrayUIExperimentsEnabled {
                    let action = TabPanelMiddlewareAction(toastType: .closedAllTabs(count: privateCount),
                                                          windowUUID: uuid,
                                                          actionType: TabPanelMiddlewareActionType.showToast)
                    store.dispatch(action)
                } else {
                    if !isTabTrayUIExperimentsEnabled {
                        let toastAction = GeneralBrowserAction(toastType: .closedAllTabs(count: normalCount),
                                                               windowUUID: uuid,
                                                               actionType: GeneralBrowserActionType.showToast)
                        store.dispatch(toastAction)
                    }
                    addNewTabIfPrivate(uuid: uuid)
                }
            }
        }

        if !tabsState.isPrivateMode {
            let dismissAction = TabTrayAction(windowUUID: uuid,
                                              actionType: TabTrayActionType.dismissTabTray)
            store.dispatch(dismissAction)
        }
    }

    /// Add a new tab when privateMode is selected and all or last normal tabs/tab are/is going to be closed
    private func addNewTabIfPrivate(uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        if let selectedTab = tabManager.selectedTab, selectedTab.isPrivate {
            tabManager.addTab(nil, isPrivate: false)
        }
    }

    private func undoCloseAllTabs(uuid: WindowUUID) {
        toastTelemetry.undoClosedAllTabs()
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
        inactiveTabTelemetry.closedAllTabs()
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
        inactiveTabTelemetry.tabSwipedToClose()
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
        addNewTab(with: urlRequest, isPrivate: true, showOverlay: false, for: uuid)
    }

    private func selectTab(for tabUUID: TabUUID, uuid: WindowUUID, isInactiveTab: Bool) {
        let tabManager = tabManager(for: uuid)
        guard let tab = tabManager.getTabForUUID(uuid: tabUUID) else { return }

        tabManager.selectTab(tab)

        let action = TabTrayAction(windowUUID: uuid,
                                   actionType: TabTrayActionType.dismissTabTray)
        store.dispatch(action)

        if isInactiveTab {
            inactiveTabTelemetry.tabOpened()
        }
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

    private func copyURL(tabID: TabUUID, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        UIPasteboard.general.url = tabManager.getTabForUUID(uuid: tabID)?.canonicalURL
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
        case MainMenuActionType.tapToggleUserAgent:
            changeUserAgent(forWindow: action.windowUUID)
        case MainMenuMiddlewareActionType.requestTabInfo:
            provideTabInfo(forWindow: action.windowUUID)
        case MainMenuDetailsActionType.tapAddToBookmarks:
            guard let tabID = action.tabID else { return }
            let shareItem = createShareItem(with: tabID, and: action.windowUUID)
            addToBookmarks(shareItem)

            guard let shareItem else { return }
            store.dispatch(
                GeneralBrowserAction(
                    toastType: .addBookmark(urlString: shareItem.url),
                    windowUUID: action.windowUUID,
                    actionType: GeneralBrowserActionType.showToast
                )
            )
        case MainMenuDetailsActionType.tapAddToReadingList:
            addToReadingList(with: action.tabID, uuid: action.windowUUID)
        case MainMenuDetailsActionType.tapRemoveFromReadingList:
            removeFromReadingList(with: action.tabID, uuid: action.windowUUID)
        case MainMenuDetailsActionType.tapAddToShortcuts:
            addToShortcuts(with: action.tabID, uuid: action.windowUUID)
        case MainMenuDetailsActionType.tapRemoveFromShortcuts:
            removeFromShortcuts(with: action.tabID, uuid: action.windowUUID)

        default:
            break
        }
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

    /// A helper struct for getting tab info for the main menu
    private struct ProfileTabInfo {
        let isBookmarked: Bool
        let isInReadingList: Bool
        let isPinned: Bool
    }

    private func provideTabInfo(forWindow windowUUID: WindowUUID) {
        guard let selectedTab = tabManager(for: windowUUID).selectedTab else {
            logger.log(
                "Attempted to get `selectedTab` but it was `nil` when in shouldn't be",
                level: .fatal,
                category: .tabs
            )
            return
        }

        fetchProfileTabInfo(for: selectedTab.url) { profileTabInfo in
            store.dispatch(
                MainMenuAction(
                    windowUUID: windowUUID,
                    actionType: MainMenuActionType.updateCurrentTabInfo,
                    currentTabInfo: MainMenuTabInfo(
                        tabID: selectedTab.tabUUID,
                        url: selectedTab.url,
                        canonicalURL: selectedTab.canonicalURL?.displayURL,
                        isHomepage: selectedTab.isFxHomeTab,
                        isDefaultUserAgentDesktop: UserAgent.isDesktop(ua: UserAgent.getUserAgent()),
                        hasChangedUserAgent: selectedTab.changedUserAgent,
                        zoomLevel: selectedTab.pageZoom,
                        readerModeIsAvailable: selectedTab.readerModeAvailableOrActive,
                        isBookmarked: profileTabInfo.isBookmarked,
                        isInReadingList: profileTabInfo.isInReadingList,
                        isPinned: profileTabInfo.isPinned
                    )
                )
            )
        }
    }

    private func fetchProfileTabInfo(
        for tabURL: URL?,
        dataLoadingCompletion: ((ProfileTabInfo) -> Void)?
    ) {
        guard let tabURL = tabURL, let url = absoluteStringFrom(tabURL) else {
            dataLoadingCompletion?(
                ProfileTabInfo(
                    isBookmarked: false,
                    isInReadingList: false,
                    isPinned: false
                )
            )
            return
        }

        let group = DispatchGroup()
        let dataQueue = DispatchQueue.global()

        var isBookmarkedResult = false
        var isPinnedResult = false
        var isInReadingListResult = false

        group.enter()
        getIsBookmarked(url: url, dataQueue: dataQueue) { result in
            isBookmarkedResult = result
            group.leave()
        }

        group.enter()
        getIsPinned(url: url, dataQueue: dataQueue) { result in
            isPinnedResult = result
            group.leave()
        }

        group.enter()
        getIsInReadingList(url: url, dataQueue: dataQueue) { result in
            isInReadingListResult = result
            group.leave()
        }

        group.notify(queue: dataQueue) {
            dataLoadingCompletion?(
                ProfileTabInfo(
                    isBookmarked: isBookmarkedResult,
                    isInReadingList: isInReadingListResult,
                    isPinned: isPinnedResult
                )
            )
        }
    }

    private func absoluteStringFrom(_ url: URL) -> String? {
        if let urlDecoded = url.decodeReaderModeURL {
            return urlDecoded.absoluteString
        }

        return url.absoluteString
    }

    private func getIsBookmarked(
        url: String,
        dataQueue: DispatchQueue,
        completion: @escaping (Bool) -> Void
    ) {
        profile.places.isBookmarked(url: url).uponQueue(dataQueue) { result in
            completion(result.successValue ?? false)
        }
    }

    private func getIsPinned(
        url: String,
        dataQueue: DispatchQueue,
        completion: @escaping (Bool) -> Void
    ) {
        profile.pinnedSites.isPinnedTopSite(url).uponQueue(dataQueue) { result in
            completion(result.successValue ?? false)
        }
    }

    private func getIsInReadingList(
        url: String,
        dataQueue: DispatchQueue,
        completion: @escaping (Bool) -> Void
    ) {
        profile.readingList.getRecordWithURL(url).uponQueue(dataQueue) { result in
            completion(result.successValue != nil)
        }
    }

    // MARK: - Homepage Related Actions
    private func resolveHomepageActions(with action: Action) {
        switch action.actionType {
        case HomepageActionType.viewWillAppear,
            JumpBackInActionType.fetchLocalTabs,
            TopTabsActionType.didTapNewTab,
            TopTabsActionType.didTapCloseTab:
            dispatchRecentlyAccessedTabs(action: action)
        case JumpBackInActionType.tapOnCell:
            guard let jumpBackInAction = action as? JumpBackInAction,
                  let tab = jumpBackInAction.tab else { return }
            tabManager(for: action.windowUUID).selectTab(tab)
        default:
            break
        }
    }

    // MARK: - Tab Manager Helper functions
    private func createShareItem(with tabID: TabUUID, and uuid: WindowUUID) -> ShareItem? {
        let tabManager = tabManager(for: uuid)
        guard let tab = tabManager.getTabForUUID(uuid: tabID),
              let url = tab.url?.absoluteString, !url.isEmpty
        else { return nil }

        var title = (tab.tabState.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            title = url
        }
        return ShareItem(url: url, title: title)
    }

    private func addToBookmarks(_ shareItem: ShareItem?) {
        guard let shareItem else { return }

        Task {
            await self.bookmarksSaver.createBookmark(url: shareItem.url, title: shareItem.title, position: 0)
        }

        var userData = [QuickActionInfos.tabURLKey: shareItem.url]
        if let title = shareItem.title {
            userData[QuickActionInfos.tabTitleKey] = title
        }
        QuickActionsImplementation().addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                             withUserData: userData,
                                                                             toApplication: .shared)
    }

    private func addToReadingList(with tabID: TabUUID?, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tabID = tabID,
              let tab = tabManager.getTabForUUID(uuid: tabID),
              let url = tab.url?.displayURL?.absoluteString
        else { return }

        profile.readingList.createRecordWithURL(
            url,
            title: tab.title ?? "",
            addedBy: UIDevice.current.name
        )

        store.dispatch(
            GeneralBrowserAction(
                toastType: .addToReadingList,
                windowUUID: uuid,
                actionType: GeneralBrowserActionType.showToast
            )
        )
    }

    private func removeFromReadingList(with tabID: TabUUID?, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tabID = tabID,
              let tab = tabManager.getTabForUUID(uuid: tabID),
              let url = tab.url?.displayURL?.absoluteString,
              let record = profile.readingList.getRecordWithURL(url).value.successValue
        else { return }

        profile.readingList.deleteRecord(record, completion: nil)

        store.dispatch(
            GeneralBrowserAction(
                toastType: .removeFromReadingList,
                windowUUID: uuid,
                actionType: GeneralBrowserActionType.showToast
            )
        )
    }

    private func addToShortcuts(with tabID: TabUUID?, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tabID = tabID,
              let tab = tabManager.getTabForUUID(uuid: tabID),
              let url = tab.url?.displayURL?.absoluteString
        else { return }

        let site = Site.createBasicSite(url: url, title: tab.displayTitle)

        profile.pinnedSites.addPinnedTopSite(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }

            store.dispatch(
                GeneralBrowserAction(
                    toastType: .addShortcut,
                    windowUUID: uuid,
                    actionType: GeneralBrowserActionType.showToast
                )
            )
        }
    }

    private func removeFromShortcuts(with tabID: TabUUID?, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tabID = tabID,
              let tab = tabManager.getTabForUUID(uuid: tabID),
              let url = tab.url?.displayURL?.absoluteString
        else { return }

        let site = Site.createBasicSite(url: url, title: tab.displayTitle)

        profile.pinnedSites.removeFromPinnedTopSites(site).uponQueue(.main) { result in
            guard result.isSuccess else { return }
            store.dispatch(
                GeneralBrowserAction(
                    toastType: .removeShortcut,
                    windowUUID: uuid,
                    actionType: GeneralBrowserActionType.showToast
                )
            )
        }
    }

    private func preserveTabs(uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        tabManager.preserveTabs()
    }

    /// Sends out updated recent tabs which is currently used for the homepage jumpBackIn section
    private func dispatchRecentlyAccessedTabs(action: Action) {
        // TODO: FXIOS-10919 - Consider testing better with Tasks here
        // and modifying how we fetch recentlyAccessedNormalTabs since
        // it doesn't retrieve the proper tabs without this task block
        // See more details on issue here [FXIOS-5149] [FXIOS-11644]
        Task { @MainActor in
            // [FXIOS-5149] Recent tabs need to be accessed from .main thread
            let recentTabs = self.tabManager(for: action.windowUUID).recentlyAccessedNormalTabs
            store.dispatch(
                TabManagerAction(
                    recentTabs: recentTabs,
                    windowUUID: action.windowUUID,
                    actionType: TabManagerMiddlewareActionType.fetchedRecentTabs
                )
            )
        }
    }
}
