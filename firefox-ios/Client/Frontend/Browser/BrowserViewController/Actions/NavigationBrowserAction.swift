// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

/// Actions that are related to navigation from the user perspective
struct NavigationBrowserAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let navigationDestination: NavigationDestination

    init(navigationDestination: NavigationDestination,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.navigationDestination = navigationDestination
    }
}

enum NavigationBrowserActionType: ActionType {
    // Native views
    case tapOnTrackingProtection
    case tapOnShareSheet
    case tapOnSettingsSection

    // link related
    case tapOnLink
    case tapOnOpenInNewTab

    // cell related
    case tapOnCell
    case longPressOnCell
    case tapOnJumpBackInShowAllButton
    case tapOnBookmarksShowMoreButton
    case tapOnHomepageSearchBar
    case tapOnShortcutsShowAllButton
    case tapOnAllStoriesButton
    case tapOnPrivacyNoticeLink
    case tapOnShowCertificatesFromErrorPage
    case tapOnNativeErrorPageLearnMore
}
