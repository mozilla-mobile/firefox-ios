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

    init(selectedTabURL: URL? = nil,
         isPrivateBrowsing: Bool? = nil,
         toastType: ToastType? = nil,
         showOverlay: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.selectedTabURL = selectedTabURL
        self.isPrivateBrowsing = isPrivateBrowsing
        self.toastType = toastType
        self.showOverlay = showOverlay
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
}

class GeneralBrowserMiddlewareAction: Action {
}

enum GeneralBrowserMiddlewareActionType: ActionType {
    case browserDidLoad
}
