// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import Storage
import Account
import SiteImageView
import SummarizeKit

import enum MozillaAppServices.BookmarkRoots

@MainActor
final class TabManagerMiddleware: FeatureFlaggable,
                                  CanRemoveQuickActionBookmark {
    private let profile: Profile
    private let logger: Logger
    private let windowManager: WindowManager
    private let bookmarksSaver: BookmarksSaver
    private let toastTelemetry: ToastTelemetry
    private let summarizerNimbusUtils: SummarizerNimbusUtils
    private let summarizationChecker: SummarizationCheckerProtocol
    private let summarizerServiceFactory: SummarizerServiceFactory
    private let tabsPanelTelemetry: TabsPanelTelemetry
    var bookmarksHandler: BookmarksHandler

    private var isTabTrayUIExperimentsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly)
        && UIDevice.current.userInterfaceIdiom != .pad
    }
    private var isSummarizerEnabled: Bool {
        return summarizerNimbusUtils.isSummarizeFeatureToggledOn
    }
    private var isAppleSummarizerEnabled: Bool {
        return summarizerNimbusUtils.isAppleSummarizerEnabled()
    }
    private var isHostedSummaryEnabled: Bool {
        return summarizerNimbusUtils.isHostedSummarizerEnabled()
    }

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         windowManager: WindowManager = AppContainer.shared.resolve(),
         summarizerNimbusUtility: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils(),
         summarizerServiceFactory: SummarizerServiceFactory = DefaultSummarizerServiceFactory(),
         summarizationChecker: SummarizationCheckerProtocol = SummarizationChecker(),
         bookmarksSaver: BookmarksSaver? = nil,
         gleanWrapper: GleanWrapper = DefaultGleanWrapper()
    ) {
        self.summarizerNimbusUtils = summarizerNimbusUtility
        self.profile = profile
        self.bookmarksHandler = profile.places
        self.summarizationChecker = summarizationChecker
        self.logger = logger
        self.summarizerServiceFactory = summarizerServiceFactory
        self.windowManager = windowManager
        self.bookmarksSaver = bookmarksSaver ?? DefaultBookmarksSaver(profile: profile)
        self.toastTelemetry = ToastTelemetry(gleanWrapper: gleanWrapper)
        self.tabsPanelTelemetry = TabsPanelTelemetry(gleanWrapper: gleanWrapper, logger: logger)
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
        } else if let action = action as? ShortcutsLibraryAction {
            self.resolveShortcutsLibrartActions(action: action, state: state)
        } else {
            self.resolveHomepageActions(with: action)
        }
    }

    private func resolveShortcutsLibrartActions(action: ShortcutsLibraryAction, state: AppState) {
        switch action.actionType {
        case ShortcutsLibraryActionType.switchTabToastButtonTapped:
            tabManager(for: action.windowUUID).selectTab(action.tab)
        default:
            break
        }
    }

    private func resolveScreenshotActions(action: ScreenshotAction, state: AppState) {
        // TODO: FXIOS-12101 this should be removed once we figure out screenshots
        guard windowManager.windows[action.windowUUID]?.tabManager != nil else {
            logger.log("Tab manager does not exist for this window, bailing from taking a screenshot.", level: .fatal, category: .tabs, extra: ["windowUUID": "\(action.windowUUID)"])
            return
        }

        let manager = tabManager(for: action.windowUUID)
        manager.tabDidSetScreenshot(action.tab)

        guard let tabsState = state.screenState(TabsPanelState.self,
                                                for: .tabsPanel,
                                                window: action.windowUUID) else { return }
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
        case TabPeekActionType.removeBookmark:
            removeBookmark(with: tabUUID, uuid: action.windowUUID)
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
        // Sanity check to ensure the window this action is for is still around
        // Short-term fix to avoid potential crashes where actions are processed
        // after the window scene has been torn down [FXIOS-13809]
        let windowManager: WindowManager = AppContainer.shared.resolve()
        guard windowManager.windowExists(uuid: action.windowUUID) else {
            logger.log("Window does not exist (\(action.windowUUID.uuidString.prefix(4))) for resolveTabTrayActions()",
                       level: .warning,
                       category: .tabs)
            return
        }

        switch action.actionType {
        case TabTrayActionType.tabTrayDidLoad:
            tabTrayDidLoad(for: action.windowUUID, panelType: action.panelType)

        case TabTrayActionType.changePanel:
            guard let panelType = action.panelType else { return }
            changePanel(panelType, appState: state, uuid: action.windowUUID)

        case TabTrayActionType.closePrivateTabsSettingToggled:
            preserveTabs(uuid: action.windowUUID)

        // FXIOS-11740 - This is relate to homepage actions, so if we want to break up this middleware
        // then this action should go to the homepage specific middleware.
        case TabTrayActionType.dismissTabTray, TabTrayActionType.modalSwipedToClose:
            dispatchRecentlyAccessedTabs(action: action)
        case TabTrayActionType.doneButtonTapped:
            tabsPanelTelemetry.doneButtonTapped(mode: action.panelType?.modeForTelemetry ?? .normal)
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
            tabsPanelTelemetry.newTabButtonTapped(mode: action.panelType?.modeForTelemetry ?? .normal)
            UserConversionMetrics().didOpenNewTab()
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

        case TabPanelViewActionType.cancelCloseAllTabs:
            tabsPanelTelemetry.closeAllTabsSheetOptionSelected(
                option: .cancel,
                mode: (action.panelType ?? .tabs).modeForTelemetry
            )

        case TabPanelViewActionType.confirmCloseAllTabs:
            closeAllTabs(state: state, uuid: action.windowUUID)

        case TabPanelViewActionType.deleteTabsOlderThan:
            guard let period = action.deleteTabPeriod else { return }
            deleteNormalTabsOlderThan(period: period, uuid: action.windowUUID)

        case TabPanelViewActionType.undoCloseAllTabs:
            undoCloseAllTabs(uuid: action.windowUUID)

        case TabPanelViewActionType.selectTab:
            guard let tabUUID = action.tabUUID else { return }
            selectTab(
                for: tabUUID,
                uuid: action.windowUUID,
                panelType: action.panelType ?? .tabs,
                selectedTabIndex: action.selectedTabIndex
            )

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

    private func normalTabsCountTextForTabTray(for windowUUID: WindowUUID) -> String {
        return tabManager(for: windowUUID).normalTabs.count.description
    }

    private func privateTabsCountTextForTabTray(for windowUUID: WindowUUID) -> String {
        return tabManager(for: windowUUID).privateTabs.count.description
    }

    private func shouldEnableDeleteTabsButton(for windowUUID: WindowUUID, isPrivateMode: Bool) -> Bool {
        let tabManager = tabManager(for: windowUUID)
        let tabsCount = !isPrivateMode ? tabManager.normalTabs.count : tabManager.privateTabs.count
        return tabsCount > 0 ? true : false
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
                            normalTabsCount: normalTabsCountTextForTabTray(for: window),
                            privateTabsCount: privateTabsCountTextForTabTray(for: window),
                            hasSyncableAccount: false,
                            enableDeleteTabsButton: shouldEnableDeleteTabsButton(for: window, isPrivateMode: isPrivate))
    }

    /// Gets initial model for TabDisplay from `TabManager`, including list of tabs and inactive tabs.
    /// - Parameter isPrivateMode: if Private mode is enabled or not
    /// - Returns:  initial model for `TabDisplayPanel`
    private func getTabsDisplayModel(for isPrivateMode: Bool,
                                     uuid: WindowUUID) -> TabDisplayModel {
        let tabs = refreshTabs(for: isPrivateMode, uuid: uuid)
        let tabDisplayModel = TabDisplayModel(
            isPrivateMode: isPrivateMode,
            tabs: tabs,
            normalTabsCount: normalTabsCountTextForTabTray(for: uuid),
            privateTabsCount: privateTabsCountTextForTabTray(for: uuid),
            enableDeleteTabsButton: shouldEnableDeleteTabsButton(for: uuid, isPrivateMode: isPrivateMode)
        )
        return tabDisplayModel
    }

    /// Gets the list of tabs from `TabManager` and builds the array of TabModel to use in TabDisplayView
    /// - Parameter isPrivateMode: is on Private mode or not
    /// - Returns: Array of TabModel used to configure collection view
    private func refreshTabs(for isPrivateMode: Bool, uuid: WindowUUID) -> [TabModel] {
        var tabs = [TabModel]()
        let tabManager = tabManager(for: uuid)
        let selectedTab = tabManager.selectedTab
        let tabManagerTabs = isPrivateMode ? tabManager.privateTabs : tabManager.normalTabs
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

    /// Creates a new tab in `TabManager` using optional `URLRequest`
    ///
    /// - Parameters:
    ///   - urlRequest: URL request to load
    ///   - isPrivate: if the tab should be created in private mode or not
    private func addNewTab(with urlRequest: URLRequest?, isPrivate: Bool, showOverlay: Bool, for uuid: WindowUUID) {
        MainActor.assertIsolated("Expected to be called only on main actor.")
        // TODO: Legacy class has a guard to cancel adding new tab if dragging was enabled,
        // check if change is still needed
        let tabManager = tabManager(for: uuid)
        let tab = tabManager.addTab(urlRequest, isPrivate: isPrivate)
        tabManager.selectTab(tab)

        let dismissAction = TabTrayAction(windowUUID: uuid,
                                          actionType: TabTrayActionType.dismissTabTray)
        store.dispatch(dismissAction)

        if !isTabTrayUIExperimentsEnabled {
            let overlayAction = GeneralBrowserAction(showOverlay: showOverlay,
                                                     windowUUID: uuid,
                                                     actionType: GeneralBrowserActionType.showOverlay)
            store.dispatch(overlayAction)
        }
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
    private func closeTab(with tabUUID: TabUUID, uuid: WindowUUID, isPrivate: Bool) -> Bool {
        tabsPanelTelemetry.tabClosed(mode: isPrivate ? .private : .normal)
        let tabManager = tabManager(for: uuid)
        // In non-private mode, if:
        //      A) the last normal active tab is closed, or
        //      B) the last of ALL normal tabs are closed (i.e. all tabs are inactive and closed at once),
        // then we want to close the tray.
        let isLastActiveTab = isPrivate
                            ? tabManager.privateTabs.count == 1
                            : tabManager.normalTabs.count == 1
        tabManager.removeTab(tabUUID)
        return isLastActiveTab
    }

    /// Close tab and trigger refresh
    /// - Parameter tabUUID: UUID of the tab to be closed/removed
    private func closeTabFromTabPanel(with tabUUID: TabUUID, uuid: WindowUUID, isPrivate: Bool) {
        let shouldDismiss = self.closeTab(with: tabUUID, uuid: uuid, isPrivate: isPrivate)
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

    private func setBookmarkQuickActions(with shareItem: ShareItem?, uuid: WindowUUID) {
        guard let shareItem else { return }

        var userData = [QuickActionInfos.tabURLKey: shareItem.url]
        if let title = shareItem.title {
            userData[QuickActionInfos.tabTitleKey] = title
        }

        QuickActionsImplementation().addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                             withUserData: userData,
                                                                             toApplication: .shared)

        if !isTabTrayUIExperimentsEnabled {
            // The Tab Tray uses a "SimpleToast", so the urlString will go unused
            let toastAction = TabPanelMiddlewareAction(toastType: .addBookmark(urlString: shareItem.url),
                                                       windowUUID: uuid,
                                                       actionType: TabPanelMiddlewareActionType.showToast)
            store.dispatch(toastAction)
        }

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
        guard tabManager.backupCloseTab != nil else { return }

        tabManager.undoCloseTab()

        guard let tabsState = state.screenState(TabsPanelState.self, for: .tabsPanel, window: uuid) else { return }

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

        tabsPanelTelemetry.closeAllTabsSheetOptionSelected(option: .all, mode: tabsState.isPrivateMode ? .private : .normal)
        let normalCount = tabManager.normalTabs.count
        let privateCount = tabManager.privateTabs.count
        tabManager.removeAllTabs(isPrivateMode: tabsState.isPrivateMode)

        triggerRefresh(uuid: uuid, isPrivate: tabsState.isPrivateMode)

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

        if !tabsState.isPrivateMode {
            let dismissAction = TabTrayAction(windowUUID: uuid,
                                              actionType: TabTrayActionType.dismissTabTray)
            store.dispatch(dismissAction)
        }
    }

    private func deleteNormalTabsOlderThan(period: TabsDeletionPeriod, uuid: WindowUUID) {
        tabsPanelTelemetry.deleteNormalTabsSheetOptionSelected(period: period)
        let tabManager = tabManager(for: uuid)
        tabManager.removeNormalTabsOlderThan(period: period, currentDate: .now)

        // We are not closing the tab tray, so we need to refresh the tabs on screen
        let model = getTabsDisplayModel(for: false, uuid: uuid)
        let refreshAction = TabPanelMiddlewareAction(tabDisplayModel: model,
                                                     windowUUID: uuid,
                                                     actionType: TabPanelMiddlewareActionType.refreshTabs)
        store.dispatch(refreshAction)
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

    private func didTapLearnMoreAboutPrivate(with urlRequest: URLRequest, uuid: WindowUUID) {
        addNewTab(with: urlRequest, isPrivate: true, showOverlay: false, for: uuid)
    }

    private func selectTab(
        for tabUUID: TabUUID,
        uuid: WindowUUID,
        panelType: TabTrayPanelType,
        selectedTabIndex: Int?
    ) {
        let tabManager = tabManager(for: uuid)
        guard let tab = tabManager.getTabForUUID(uuid: tabUUID) else { return }

        tabManager.selectTab(tab)

        tabsPanelTelemetry.tabSelected(at: selectedTabIndex, mode: panelType.modeForTelemetry)

        let action = TabTrayAction(windowUUID: uuid,
                                   actionType: TabTrayActionType.dismissTabTray)
        store.dispatch(action)
    }

    private func tabManager(for uuid: WindowUUID) -> TabManager {
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
        let urlString = tab?.url?.absoluteString ?? ""
        let profile = self.profile

        profile.places.isBookmarked(url: urlString).uponQueue(.main) { isBookmarkedResult in
            ensureMainThread {
                guard case .success(let isBookmarked) = isBookmarkedResult else {
                    return
                }

                let canBeSaved: Bool
                if isBookmarked || (tab?.urlIsTooLong ?? false) || (tab?.isFxHomeTab ?? false) {
                    canBeSaved = false
                } else {
                    canBeSaved = true
                }

                let browserProfile = profile as? BrowserProfile
                browserProfile?.tabs.getClientGUIDs { (result, error) in
                    ensureMainThread {
                        let model = TabPeekModel(canTabBeSaved: canBeSaved,
                                                 canTabBeRemoved: isBookmarked,
                                                 canCopyURL: !(tab?.isFxHomeTab ?? false),
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
        }
    }

    private func copyURL(tabID: TabUUID, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        UIPasteboard.general.url = tabManager.getTabForUUID(uuid: tabID)?.canonicalURL
    }

    private func tabPeekCloseTab(with tabID: TabUUID, uuid: WindowUUID, isPrivate: Bool) {
        closeTabFromTabPanel(with: tabID, uuid: uuid, isPrivate: isPrivate)
    }

    private func changePanel(_ panel: TabTrayPanelType, appState: AppState, uuid: WindowUUID) {
        tabsPanelTelemetry.tabModeSelected(mode: panel.modeForTelemetry)
        let isPrivate = panel == TabTrayPanelType.privateTabs
        let tabState = self.getTabsDisplayModel(for: isPrivate, uuid: uuid)
        if panel != .syncedTabs {
            let action = TabPanelMiddlewareAction(tabDisplayModel: tabState,
                                                  windowUUID: uuid,
                                                  actionType: TabPanelMiddlewareActionType.didChangeTabPanel)
            store.dispatch(action)
        }
    }

    // MARK: - Main menu actions
    private func resolveMainMenuActions(with action: MainMenuAction, appState: AppState) {
        switch action.actionType {
        case MainMenuActionType.tapToggleUserAgent:
            changeUserAgent(forWindow: action.windowUUID)
        case MainMenuMiddlewareActionType.requestTabInfo, MainMenuActionType.viewWillTransition:
            handleDidInstantiateViewAction(action: action)
        case MainMenuMiddlewareActionType.requestTabInfoForSiteProtectionsHeader:
            provideTabInfoForSiteProtectionsHeader(forWindow: action.windowUUID)
        case MainMenuActionType.tapAddToBookmarks:
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
        case MainMenuActionType.tapAddToShortcuts:
            addToShortcuts(with: action.tabID, uuid: action.windowUUID)
        case MainMenuActionType.tapRemoveFromShortcuts:
            removeFromShortcuts(with: action.tabID, uuid: action.windowUUID)

        default:
            break
        }
    }

    private func changeUserAgent(forWindow windowUUID: WindowUUID) {
        guard let selectedTab = tabManager(for: windowUUID).selectedTab else { return }

        if let url = selectedTab.url {
            // When the user changes user agent do the new request using the original URL
            let originalURL = InternalURL(url)?.originalURLFromErrorPage ?? url
            selectedTab.toggleChangeUserAgent(originalURL: originalURL)
            Tab.ChangeUserAgent.updateDomainList(
                forUrl: originalURL,
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

    private func provideTabInfo(forWindow windowUUID: WindowUUID, accountData: AccountData) {
        guard let selectedTab = tabManager(for: windowUUID).selectedTab else {
            logger.log(
                "Attempted to get `selectedTab` but it was `nil` when in shouldn't be",
                level: .fatal,
                category: .tabs
            )
            return
        }
        dispatchDefaultTabInfo(windowUUID: windowUUID, selectedTab: selectedTab, accountData: accountData)
        let isSummarizerEnabled = isSummarizerEnabled
        fetchProfileTabInfo(for: selectedTab.url) { [weak self] profileTabInfo in
            assert(Thread.isMainThread)
            if isSummarizerEnabled, !selectedTab.isFxHomeTab {
                Task {
                    let summarizeMiddleware = SummarizerMiddleware()
                    let summarizationCheckResult = await summarizeMiddleware.checkSummarizationResult(selectedTab)
                    let contentType = summarizationCheckResult?.contentType ?? .generic
                    self?.dispatchTabInfo(
                        info: profileTabInfo,
                        selectedTab: selectedTab,
                        windowUUID: windowUUID,
                        accountData: accountData,
                        canSummarize: summarizationCheckResult?.canSummarize ?? false,
                        summarizerConfig: summarizeMiddleware.getConfig(for: contentType)
                    )
                    self?.provideProfileImage(forWindow: windowUUID, accountData: accountData)
                }
            } else {
                self?.dispatchTabInfo(
                    info: profileTabInfo,
                    selectedTab: selectedTab,
                    windowUUID: windowUUID,
                    accountData: accountData,
                    canSummarize: false
                )
                self?.provideProfileImage(forWindow: windowUUID, accountData: accountData)
            }
        }
    }

    @MainActor
    private func provideProfileImage(forWindow windowUUID: WindowUUID, accountData: AccountData) {
        if let iconURL = accountData.iconURL {
            GeneralizedImageFetcher().getImageFor(url: iconURL) { image in
                ensureMainThread { [weak self] in
                    self?.dispatchProfileImage(
                        windowUUID: windowUUID,
                        profileImage: image
                    )
                }
            }
        }
    }

    private func dispatchDefaultTabInfo(windowUUID: WindowUUID, selectedTab: Tab, accountData: AccountData) {
        self.dispatchTabInfo(
            info: ProfileTabInfo(isBookmarked: false, isInReadingList: false, isPinned: false),
            selectedTab: selectedTab,
            windowUUID: windowUUID,
            accountData: accountData,
            canSummarize: false,
            summarizerConfig: SummarizerMiddleware().getConfig(for: .generic)
        )
    }

    private func fetchProfileTabInfo(
        for tabURL: URL?,
        dataLoadingCompletion: (@MainActor (ProfileTabInfo) -> Void)?
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

        // TODO: FXIOS-13675 These should be made actually threadsafe
        nonisolated(unsafe) var isBookmarkedResult = false
        nonisolated(unsafe) var isPinnedResult = false
        nonisolated(unsafe) var isInReadingListResult = false

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

        group.notify(queue: .main) {
            dataLoadingCompletion?(
                ProfileTabInfo(
                    isBookmarked: isBookmarkedResult,
                    isInReadingList: isInReadingListResult,
                    isPinned: isPinnedResult
                )
            )
        }
    }

    private func dispatchTabInfo(
        info: ProfileTabInfo,
        selectedTab: Tab,
        windowUUID: WindowUUID,
        accountData: AccountData,
        canSummarize: Bool,
        summarizerConfig: SummarizerConfig? = nil
    ) {
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
                    summaryIsAvailable: canSummarize,
                    summarizerConfig: summarizerConfig,
                    isBookmarked: info.isBookmarked,
                    isInReadingList: info.isInReadingList,
                    isPinned: info.isPinned,
                    accountData: accountData
                )
            )
        )
    }

    private func dispatchProfileImage(
        windowUUID: WindowUUID,
        profileImage: UIImage?
    ) {
        store.dispatch(
            MainMenuAction(
                windowUUID: windowUUID,
                actionType: MainMenuActionType.updateProfileImage,
                accountProfileImage: profileImage
            )
        )
    }

    private func handleDidInstantiateViewAction(action: MainMenuAction) {
        let accountData = getAccountData()
        provideTabInfo(forWindow: action.windowUUID, accountData: accountData)
    }

    private func getAccountData() -> AccountData {
        let rustAccount = RustFirefoxAccounts.shared
        let needsReAuth = rustAccount.accountNeedsReauth()

        if let userProfile = rustAccount.userProfile {
            let title: String = {
                return userProfile.displayName ?? userProfile.email
            }()

            let subtitle: String? = needsReAuth ?
                .MainMenu.Account.SyncErrorDescription : .MainMenu.Account.SignedInDescription

            var iconURL: URL?
            if let str = rustAccount.userProfile?.avatarUrl,
               let url = URL(string: str) {
                iconURL = url
            }

            return AccountData(title: title,
                               subtitle: subtitle,
                               needsReAuth: needsReAuth,
                               iconURL: iconURL)
        }
        return defaultAccountData()
    }

    private func defaultAccountData() -> AccountData {
        return AccountData(title: .MainMenu.Account.SignedOutTitle,
                           subtitle: .MainMenu.Account.SignedOutDescriptionV2,
                           needsReAuth: nil,
                           iconURL: nil)
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
        completion: @escaping @Sendable (Bool) -> Void
    ) {
        profile.places.isBookmarked(url: url).uponQueue(dataQueue) { result in
            completion(result.successValue ?? false)
        }
    }

    private func getIsPinned(
        url: String,
        dataQueue: DispatchQueue,
        completion: @escaping @Sendable (Bool) -> Void
    ) {
        profile.pinnedSites.isPinnedTopSite(url).uponQueue(dataQueue) { result in
            completion(result.successValue ?? false)
        }
    }

    private func getIsInReadingList(
        url: String,
        dataQueue: DispatchQueue,
        completion: @escaping @Sendable (Bool) -> Void
    ) {
        profile.readingList.getRecordWithURL(url).uponQueue(dataQueue) { result in
            completion(result.successValue != nil)
        }
    }

    private func provideTabInfoForSiteProtectionsHeader(forWindow windowUUID: WindowUUID) {
        guard let selectedTab = tabManager(for: windowUUID).selectedTab else {
            logger.log(
                "Attempted to get `selectedTab` but it was `nil` when in shouldn't be",
                level: .fatal,
                category: .tabs
            )
            return
        }
        store.dispatch(
            MainMenuAction(
                windowUUID: windowUUID,
                actionType: MainMenuActionType.updateSiteProtectionsHeader,
                siteProtectionsData: SiteProtectionsData(
                    title: selectedTab.displayTitle,
                    subtitle: selectedTab.url?.baseDomain,
                    image: selectedTab.url?.absoluteString,
                    state: getSiteProtectionState(for: selectedTab)
                )
            )
        )
    }

    private func getSiteProtectionState(for selectedTab: Tab) -> SiteProtectionsState {
        let isContentBlockingConfigEnabled = profile.prefs.boolForKey(ContentBlockingConfig.Prefs.EnabledKey) ?? true
        guard let url = selectedTab.url,
              !ContentBlocker.shared.isSafelisted(url: url),
              isContentBlockingConfigEnabled else { return .off }

        let hasSecureContent = selectedTab.currentWebView()?.hasOnlySecureContent ?? false

        if !hasSecureContent {
            return .notSecure
        }

        return .on
    }

    // MARK: - Homepage Related Actions
    private func resolveHomepageActions(with action: Action) {
        switch action.actionType {
        case HomepageActionType.viewWillAppear,
            HomepageMiddlewareActionType.jumpBackInLocalTabsUpdated,
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

    func removeBookmark(with tabID: TabUUID, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tab = tabManager.getTabForUUID(uuid: tabID),
              let url = tab.url?.absoluteString, !url.isEmpty
        else { return }

        profile.places.deleteBookmarksWithURL(url: url)
            .uponQueue(.main) { result in
                // FXIOS-13228 It should be safe to assumeIsolated here because of `.main` queue above
                MainActor.assumeIsolated {
                    guard result.isSuccess else { return }
                    self.removeBookmarkShortcut()
                }
            }
    }

    private func addToShortcuts(with tabID: TabUUID?, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tabID = tabID,
              let tab = tabManager.getTabForUUID(uuid: tabID),
              let url = tab.url?.displayURL?.absoluteString
        else { return }

        let site = Site.createBasicSite(url: url, title: tab.displayTitle)

        profile.pinnedSites.addPinnedTopSite(site)
    }

    private func removeFromShortcuts(with tabID: TabUUID?, uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        guard let tabID = tabID,
              let tab = tabManager.getTabForUUID(uuid: tabID),
              let url = tab.url?.displayURL?.absoluteString
        else { return }

        let site = Site.createBasicSite(url: url, title: tab.displayTitle)

        profile.pinnedSites.removeFromPinnedTopSites(site)
    }

    private func preserveTabs(uuid: WindowUUID) {
        let tabManager = tabManager(for: uuid)
        tabManager.preserveTabs()
    }

    /// Sends out updated recent tabs which is currently used for the homepage jumpBackIn section
    private func dispatchRecentlyAccessedTabs(action: Action) {
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
