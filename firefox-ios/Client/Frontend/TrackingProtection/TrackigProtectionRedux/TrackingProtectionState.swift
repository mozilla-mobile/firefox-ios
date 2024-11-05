// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common
import Shared

struct TrackingProtectionState: StateType, Equatable, ScreenState {
    let windowUUID: WindowUUID
    var shouldDismiss: Bool
    var showTrackingProtectionSettings: Bool
    var showDetails: Bool
    var showBlockedTrackers: Bool
    var trackingProtectionEnabled: Bool
    var connectionSecure: Bool
    var showsClearCookiesAlert: Bool
    var shouldClearCookies: Bool
    var shouldUpdateBlockedTrackerStats: Bool

    init(appState: AppState,
         uuid: WindowUUID) {
        guard let trackingProtectionState = store.state.screenState(
            TrackingProtectionState.self,
            for: .trackingProtection,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: trackingProtectionState.windowUUID,
            shouldDismiss: trackingProtectionState.shouldDismiss,
            showTrackingProtectionSettings: trackingProtectionState.showTrackingProtectionSettings,
            trackingProtectionEnabled: trackingProtectionState.trackingProtectionEnabled,
            connectionSecure: trackingProtectionState.connectionSecure,
            showDetails: trackingProtectionState.showDetails,
            showBlockedTrackers: trackingProtectionState.showBlockedTrackers,
            showsClearCookiesAlert: trackingProtectionState.showsClearCookiesAlert,
            shouldClearCookies: trackingProtectionState.shouldClearCookies,
            shouldUpdateBlockedTrackerStats: trackingProtectionState.shouldUpdateBlockedTrackerStats
        )
    }

    init(
        windowUUID: WindowUUID
    ) {
        self.init(
            windowUUID: windowUUID,
            shouldDismiss: false,
            showTrackingProtectionSettings: false,
            trackingProtectionEnabled: true,
            connectionSecure: true,
            showDetails: false,
            showBlockedTrackers: false,
            showsClearCookiesAlert: false,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        shouldDismiss: Bool,
        showTrackingProtectionSettings: Bool,
        trackingProtectionEnabled: Bool,
        connectionSecure: Bool,
        showDetails: Bool,
        showBlockedTrackers: Bool,
        showsClearCookiesAlert: Bool,
        shouldClearCookies: Bool,
        shouldUpdateBlockedTrackerStats: Bool
    ) {
        self.windowUUID = windowUUID
        self.shouldDismiss = shouldDismiss
        self.showTrackingProtectionSettings = showTrackingProtectionSettings
        self.trackingProtectionEnabled = trackingProtectionEnabled
        self.connectionSecure = connectionSecure
        self.showDetails = showDetails
        self.showBlockedTrackers = showBlockedTrackers
        self.showsClearCookiesAlert = showsClearCookiesAlert
        self.shouldClearCookies = shouldClearCookies
        self.shouldUpdateBlockedTrackerStats = shouldUpdateBlockedTrackerStats
    }

    static let reducer: Reducer<TrackingProtectionState> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultActionState(from: state)
        }

        switch action.actionType {
        case TrackingProtectionMiddlewareActionType.clearCookies:
            return TrackingProtectionState(
                windowUUID: state.windowUUID,
                shouldDismiss: false,
                showTrackingProtectionSettings: false,
                trackingProtectionEnabled: !state.trackingProtectionEnabled,
                connectionSecure: state.connectionSecure,
                showDetails: false,
                showBlockedTrackers: false,
                showsClearCookiesAlert: false,
                shouldClearCookies: true,
                shouldUpdateBlockedTrackerStats: false
            )
        case TrackingProtectionMiddlewareActionType.navigateToSettings:
            return TrackingProtectionState(
                windowUUID: state.windowUUID,
                shouldDismiss: true,
                showTrackingProtectionSettings: true,
                trackingProtectionEnabled: state.trackingProtectionEnabled,
                connectionSecure: state.connectionSecure,
                showDetails: false,
                showBlockedTrackers: false,
                showsClearCookiesAlert: false,
                shouldClearCookies: false,
                shouldUpdateBlockedTrackerStats: false
            )
        case TrackingProtectionMiddlewareActionType.showTrackingProtectionDetails:
            return TrackingProtectionState(
                windowUUID: state.windowUUID,
                shouldDismiss: false,
                showTrackingProtectionSettings: false,
                trackingProtectionEnabled: state.trackingProtectionEnabled,
                connectionSecure: state.connectionSecure,
                showDetails: true,
                showBlockedTrackers: false,
                showsClearCookiesAlert: false,
                shouldClearCookies: false,
                shouldUpdateBlockedTrackerStats: false
            )
        case TrackingProtectionMiddlewareActionType.showBlockedTrackersDetails:
            return TrackingProtectionState(
                windowUUID: state.windowUUID,
                shouldDismiss: false,
                showTrackingProtectionSettings: false,
                trackingProtectionEnabled: state.trackingProtectionEnabled,
                connectionSecure: state.connectionSecure,
                showDetails: false,
                showBlockedTrackers: true,
                showsClearCookiesAlert: false,
                shouldClearCookies: false,
                shouldUpdateBlockedTrackerStats: false
            )
        case TrackingProtectionActionType.goBack:
            return TrackingProtectionState(
                windowUUID: state.windowUUID,
                shouldDismiss: false,
                showTrackingProtectionSettings: false,
                trackingProtectionEnabled: state.trackingProtectionEnabled,
                connectionSecure: state.connectionSecure,
                showDetails: false,
                showBlockedTrackers: false,
                showsClearCookiesAlert: false,
                shouldClearCookies: false,
                shouldUpdateBlockedTrackerStats: false
            )
        case TrackingProtectionActionType.updateBlockedTrackerStats:
            return TrackingProtectionState(
                windowUUID: state.windowUUID,
                shouldDismiss: false,
                showTrackingProtectionSettings: false,
                trackingProtectionEnabled: state.trackingProtectionEnabled,
                connectionSecure: state.connectionSecure,
                showDetails: false,
                showBlockedTrackers: false,
                showsClearCookiesAlert: false,
                shouldClearCookies: false,
                shouldUpdateBlockedTrackerStats: true
            )
        case TrackingProtectionMiddlewareActionType.showAlert:
            return TrackingProtectionState(
                windowUUID: state.windowUUID,
                shouldDismiss: false,
                showTrackingProtectionSettings: false,
                trackingProtectionEnabled: state.trackingProtectionEnabled,
                connectionSecure: state.connectionSecure,
                showDetails: false,
                showBlockedTrackers: false,
                showsClearCookiesAlert: true,
                shouldClearCookies: false,
                shouldUpdateBlockedTrackerStats: false
            )
        case TrackingProtectionActionType.toggleTrackingProtectionStatus:
            return TrackingProtectionState(
                windowUUID: state.windowUUID,
                shouldDismiss: false,
                showTrackingProtectionSettings: false,
                trackingProtectionEnabled: !state.trackingProtectionEnabled,
                connectionSecure: state.connectionSecure,
                showDetails: false,
                showBlockedTrackers: false,
                showsClearCookiesAlert: false,
                shouldClearCookies: false,
                shouldUpdateBlockedTrackerStats: false
            )
        case TrackingProtectionMiddlewareActionType.dismissTrackingProtection:
            return TrackingProtectionState(
                windowUUID: state.windowUUID,
                shouldDismiss: true,
                showTrackingProtectionSettings: false,
                trackingProtectionEnabled: state.trackingProtectionEnabled,
                connectionSecure: state.connectionSecure,
                showDetails: false,
                showBlockedTrackers: false,
                showsClearCookiesAlert: false,
                shouldClearCookies: false,
                shouldUpdateBlockedTrackerStats: false
            )
        default:
            return defaultActionState(from: state)
        }
    }

    static func defaultActionState(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            shouldDismiss: false,
            showTrackingProtectionSettings: false,
            trackingProtectionEnabled: state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            showDetails: false,
            showBlockedTrackers: false,
            showsClearCookiesAlert: false,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false
        )
    }
}
