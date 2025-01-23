// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

final class TrackingProtectionAction: Action { }

enum TrackingProtectionActionType: ActionType {
    case toggleTrackingProtectionStatus
    case clearCookiesAndSiteData
    case closeTrackingProtection
    case tappedShowSettings
    case tappedShowTrackingProtectionDetails
    case tappedShowBlockedTrackers
    case tappedShowClearCookiesAlert
    case goBack
    case updateBlockedTrackerStats
    case updateConnectionStatus
}

final class TrackingProtectionMiddlewareAction: Action { }

enum TrackingProtectionMiddlewareActionType: ActionType {
    case dismissTrackingProtection
    case navigateToSettings
    case showTrackingProtectionDetails
    case showBlockedTrackersDetails
    case showAlert
    case clearCookies
}
