// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

struct TabPanelViewAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let panelType: TabTrayPanelType?
    let isPrivateModeActive: Bool?
    let urlRequest: URLRequest?
    let tabUUID: TabUUID?
    let selectedTabIndex: Int?
    let toastType: ToastType?
    let shareSheetURL: URL?
    let deleteTabPeriod: TabsDeletionPeriod?

    init(panelType: TabTrayPanelType?,
         isPrivateModeActive: Bool? = nil,
         urlRequest: URLRequest? = nil,
         tabUUID: TabUUID? = nil,
         selectedTabIndex: Int? = nil,
         toastType: ToastType? = nil,
         shareSheetURL: URL? = nil,
         deleteTabPeriod: TabsDeletionPeriod? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.panelType = panelType
        self.isPrivateModeActive = isPrivateModeActive
        self.urlRequest = urlRequest
        self.tabUUID = tabUUID
        self.selectedTabIndex = selectedTabIndex
        self.toastType = toastType
        self.shareSheetURL = shareSheetURL
        self.deleteTabPeriod = deleteTabPeriod
    }
}

enum TabPanelViewActionType: ActionType {
    case tabPanelDidLoad
    case tabPanelWillAppear
    case tabPanelDidAppear
    case closeTab
    case closeAllTabs
    case prefetchScreenshots
}

struct TabPanelMiddlewareAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let tabDisplayModel: TabDisplayModel?
    let toastType: ToastType??
    let scrollBehavior: TabScrollBehavior?

    init(tabDisplayModel: TabDisplayModel? = nil,
         toastType: ToastType? = nil,
         scrollBehavior: TabScrollBehavior? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.tabDisplayModel = tabDisplayModel
        self.toastType = toastType
        self.scrollBehavior = scrollBehavior
    }
}

enum TabPanelMiddlewareActionType: ActionType {
    case didLoadTabPanel
    case willAppearTabPanel
    case didChangeTabPanel
    case refreshTabs
    case scrollToTab
}

struct ScreenshotAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let tab: Tab

    init(windowUUID: WindowUUID, tab: Tab, actionType: any ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.tab = tab
    }
}

enum ScreenshotActionType: ActionType {
    case screenshotTaken
    case screenshotRestored
}

// MARK: Modernizing actions
enum TabPanelViewModernAction: ModernAction {
    case addNewTab(TabTrayPanelType)
    case cancelCloseAllTabs(TabTrayPanelType)
    case confirmCloseAllTabs(isPrivateMode: Bool)
    case deleteTabsOlderThan(TabsDeletionPeriod)
    case moveTab(MoveTabPayload)
    case selectTab(SelectedTabPayload)
    case learnMoreAboutPrivateMode
}

// MARK: Payloads for `TabPanelViewModernAction`
struct SelectedTabPayload {
    let tabUUID: TabUUID
    let index: Int
    let panelType: TabTrayPanelType
}

struct MoveTabPayload {
    let originIndex: Int
    let destinationIndex: Int
    let isPrivate: Bool
}
