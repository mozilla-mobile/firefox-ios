// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

class GeneralBrowserAction: Action {
    let selectedTabURL: URL?
    let isPrivateBrowsing: Bool?
    let toastType: ToastType?
    let showOverlay: Bool?
    let buttonTapped: UIButton?
    let isNativeErrorPage: Bool?
    init(selectedTabURL: URL? = nil,
         isPrivateBrowsing: Bool? = nil,
         toastType: ToastType? = nil,
         showOverlay: Bool? = nil,
         buttonTapped: UIButton? = nil,
         isNativeErrorPage: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.selectedTabURL = selectedTabURL
        self.isPrivateBrowsing = isPrivateBrowsing
        self.toastType = toastType
        self.buttonTapped = buttonTapped
        self.showOverlay = showOverlay
        self.isNativeErrorPage = isNativeErrorPage
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

enum GeneralBrowserActionType: ActionType {
    case showToast
    case showOverlay
    case updateSelectedTab
    case goToHomepage
    case navigateBack
    case navigateForward
    case showTabTray
    case showQRcodeReader
    case showBackForwardList
    case showTrackingProtectionDetails
    case showTabsLongPressActions
    case showReloadLongPressAction
    case showMenu
    case showLocationViewLongPressActionSheet
    case stopLoadingWebsite
    case reloadWebsite
    case reloadWebsiteNoCache
    case showShare
    case showReaderMode
    case addNewTab
    case showNewTabLongPressActions
    case addToReadingListLongPressAction
    case clearData
    case showPasswordGenerator
}

class GeneralBrowserMiddlewareAction: Action {
    let scrollOffset: CGPoint?
    let toolbarPosition: SearchBarPosition?

    init(scrollOffset: CGPoint? = nil,
         toolbarPosition: SearchBarPosition? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.scrollOffset = scrollOffset
        self.toolbarPosition = toolbarPosition
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

enum GeneralBrowserMiddlewareActionType: ActionType {
    case browserDidLoad
    case toolbarPositionChanged
    case websiteDidScroll
}
