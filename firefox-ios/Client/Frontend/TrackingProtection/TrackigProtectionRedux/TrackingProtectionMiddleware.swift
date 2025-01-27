// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common
import Shared

final class TrackingProtectionMiddleware {
    private let telemetryWrapper = TrackingProtectionTelemetry()

    lazy var trackingProtectionProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case TrackingProtectionActionType.toggleTrackingProtectionStatus:
            self.toggleSiteSafelistStatus(windowUUID: windowUUID)
        case TrackingProtectionActionType.tappedShowClearCookiesAlert:
            self.tappedShowClearCookiesAndSiteDataAlert(windowUUID: windowUUID)
        case TrackingProtectionActionType.clearCookiesAndSiteData:
            self.clearCookiesAndSiteData(windowUUID: windowUUID)
        case TrackingProtectionActionType.tappedShowTrackingProtectionDetails:
            self.showTrackingProtectionDetails(windowUUID: windowUUID)
        case TrackingProtectionActionType.tappedShowBlockedTrackers:
            self.showBlockedTrackersDetails(windowUUID: windowUUID)
        case TrackingProtectionActionType.tappedShowSettings:
            self.showTrackingProtectionSettings(windowUUID: windowUUID)
        case TrackingProtectionActionType.closeTrackingProtection:
            self.dismissScreen(windowUUID: windowUUID)
        default:
            break
        }
    }

    private func toggleSiteSafelistStatus(windowUUID: WindowUUID) {
        let newAction = TrackingProtectionAction(
            windowUUID: windowUUID,
            actionType: TrackingProtectionActionType.toggleTrackingProtectionStatus
        )
        store.dispatch(newAction)
    }

    private func clearCookiesAndSiteData(windowUUID: WindowUUID) {
        let newAction = TrackingProtectionAction(
            windowUUID: windowUUID,
            actionType: TrackingProtectionMiddlewareActionType.clearCookies
        )
        store.dispatch(newAction)
        telemetryWrapper.clearCookiesAndSiteData()
    }

    private func tappedShowClearCookiesAndSiteDataAlert(windowUUID: WindowUUID) {
        let newAction = TrackingProtectionAction(
            windowUUID: windowUUID,
            actionType: TrackingProtectionMiddlewareActionType.showAlert
        )
        store.dispatch(newAction)
        telemetryWrapper.showClearCookiesAlert()
    }

    private func dismissScreen(windowUUID: WindowUUID) {
        let newAction = TrackingProtectionMiddlewareAction(
            windowUUID: windowUUID,
            actionType: TrackingProtectionMiddlewareActionType.dismissTrackingProtection
        )
        store.dispatch(newAction)
        telemetryWrapper.dismissTrackingProtection()
    }

    private func showTrackingProtectionDetails(windowUUID: WindowUUID) {
        let newAction = TrackingProtectionAction(
            windowUUID: windowUUID,
            actionType: TrackingProtectionMiddlewareActionType.showTrackingProtectionDetails
        )
        store.dispatch(newAction)
        telemetryWrapper.showTrackingProtectionDetails()
    }

    private func showBlockedTrackersDetails(windowUUID: WindowUUID) {
        let newAction = TrackingProtectionAction(
            windowUUID: windowUUID,
            actionType: TrackingProtectionMiddlewareActionType.showBlockedTrackersDetails
        )
        store.dispatch(newAction)
        telemetryWrapper.showBlockedTrackersDetails()
    }

    private func showTrackingProtectionSettings(windowUUID: WindowUUID) {
        let newAction = TrackingProtectionAction(
            windowUUID: windowUUID,
            actionType: TrackingProtectionMiddlewareActionType.navigateToSettings
        )
        store.dispatch(newAction)
        telemetryWrapper.tappedShowSettings()
    }
}
