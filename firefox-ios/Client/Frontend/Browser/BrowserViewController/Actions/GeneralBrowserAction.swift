// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common
import WebKit
import SummarizeKit

struct GeneralBrowserAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let selectedTabURL: URL?
    let isPrivateBrowsing: Bool?
    let toastType: ToastType?
    let showOverlay: Bool?
    let buttonTapped: UIButton?
    let isNativeErrorPage: Bool?
    let frameContext: PasswordGeneratorFrameContext?
    let summarizerConfig: SummarizerConfig?
    init(selectedTabURL: URL? = nil,
         isPrivateBrowsing: Bool? = nil,
         toastType: ToastType? = nil,
         showOverlay: Bool? = nil,
         buttonTapped: UIButton? = nil,
         isNativeErrorPage: Bool? = nil,
         frameContext: PasswordGeneratorFrameContext? = nil,
         summarizerConfig: SummarizerConfig? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.selectedTabURL = selectedTabURL
        self.isPrivateBrowsing = isPrivateBrowsing
        self.toastType = toastType
        self.buttonTapped = buttonTapped
        self.showOverlay = showOverlay
        self.isNativeErrorPage = isNativeErrorPage
        self.frameContext = frameContext
        self.summarizerConfig = summarizerConfig
    }
}

enum GeneralBrowserActionType: ActionType {
    case showToast
    case showOverlay
    case leaveOverlay
    case updateSelectedTab
    case goToHomepage
    case navigateBack
    case navigateForward
    case showTabTray
    case showBackForwardList
    case showTrackingProtectionDetails
    case showTabsLongPressActions
    case showReloadLongPressAction
    case showMenu
    case showLocationViewLongPressActionSheet
    case showSummarizer
    case stopLoadingWebsite
    case reloadWebsite
    case reloadWebsiteNoCache
    case showShare
    case showReaderMode
    case startAtHome
    case addNewTab
    case showNewTabLongPressActions
    case addToReadingListLongPressAction
    case clearData
    case showPasswordGenerator
    case didSelectedTabChangeToHomepage
    case enteredZeroSearchScreen
    case didUnhideToolbar
    case didCloseTabFromToolbar
    case shakeMotionEnded
}

struct GeneralBrowserMiddlewareAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let scrollOffset: CGPoint?
    let toolbarPosition: SearchBarPosition?

    init(scrollOffset: CGPoint? = nil,
         toolbarPosition: SearchBarPosition? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.scrollOffset = scrollOffset
        self.toolbarPosition = toolbarPosition
    }
}

enum GeneralBrowserMiddlewareActionType: ActionType {
    case browserDidLoad
    case toolbarPositionChanged
    case websiteDidScroll
}
