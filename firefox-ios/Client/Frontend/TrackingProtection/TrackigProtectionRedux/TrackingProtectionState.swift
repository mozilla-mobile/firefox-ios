// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Foundation
import Redux

@Copyable
struct TrackingProtectionState: ScreenState {
    enum NavType {
        case home
        case back
        case close
        case settings
    }

    enum DisplayType: Equatable {
        case blockedTrackersDetails
        case trackingProtectionDetails
        case certificatesDetails
        case clearCookiesAlert
    }

    let windowUUID: WindowUUID
    var trackingProtectionEnabled: Bool
    var connectionSecure: Bool
    var shouldClearCookies: Bool
    var shouldUpdateBlockedTrackerStats: Bool
    var shouldUpdateConnectionStatus: Bool
    var navigateTo: NavType?
    var displayView: DisplayType?

    init(appState: AppState,
         uuid: WindowUUID) {
        guard let trackingProtectionState = appState.componentState(
            TrackingProtectionState.self,
            for: .trackingProtection,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: trackingProtectionState.windowUUID,
            trackingProtectionEnabled: trackingProtectionState.trackingProtectionEnabled,
            connectionSecure: trackingProtectionState.connectionSecure,
            shouldClearCookies: trackingProtectionState.shouldClearCookies,
            shouldUpdateBlockedTrackerStats: trackingProtectionState.shouldUpdateBlockedTrackerStats,
            shouldUpdateConnectionStatus: trackingProtectionState.shouldUpdateConnectionStatus,
            navigateTo: trackingProtectionState.navigateTo,
            displayView: trackingProtectionState.displayView
        )
    }

    init(
        windowUUID: WindowUUID
    ) {
        self.init(
            windowUUID: windowUUID,
            trackingProtectionEnabled: true,
            connectionSecure: true,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false,
            shouldUpdateConnectionStatus: false,
            navigateTo: .home,
            displayView: nil
        )
    }

    private init(
        windowUUID: WindowUUID,
        trackingProtectionEnabled: Bool,
        connectionSecure: Bool,
        shouldClearCookies: Bool,
        shouldUpdateBlockedTrackerStats: Bool,
        shouldUpdateConnectionStatus: Bool,
        navigateTo: NavType? = nil,
        displayView: DisplayType? = nil
    ) {
        self.windowUUID = windowUUID
        self.trackingProtectionEnabled = trackingProtectionEnabled
        self.connectionSecure = connectionSecure
        self.shouldClearCookies = shouldClearCookies
        self.shouldUpdateBlockedTrackerStats = shouldUpdateBlockedTrackerStats
        self.shouldUpdateConnectionStatus = shouldUpdateConnectionStatus
        self.navigateTo = navigateTo
        self.displayView = displayView
    }

    static let reducer: Reducer<TrackingProtectionState> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case TrackingProtectionMiddlewareActionType.clearCookies:
            return handleClearCookiesAction(from: state)
        case TrackingProtectionMiddlewareActionType.navigateToSettings:
            return handleNavigateToSettingsAction(from: state)
        case TrackingProtectionMiddlewareActionType.showTrackingProtectionDetails:
            return handleShowTrackingProtectionDetailsAction(from: state)
        case TrackingProtectionMiddlewareActionType.showBlockedTrackersDetails:
            return handleShowBlockedTrackersDetailsAction(from: state)
        case TrackingProtectionActionType.goBack:
            return handleGoBackAction(from: state)
        case TrackingProtectionActionType.updateBlockedTrackerStats:
            return handleUpdateBlockedTrackerStatsAction(from: state)
        case TrackingProtectionActionType.updateConnectionStatus:
            return handleUpdateConnectionStatusAction(from: state)
        case TrackingProtectionMiddlewareActionType.showAlert:
            return handleShowAlertAction(from: state)
        case TrackingProtectionActionType.toggleTrackingProtectionStatus:
            return handleToggleTrackingProtectionStatusAction(from: state)
        case TrackingProtectionMiddlewareActionType.dismissTrackingProtection:
            return handleDismissTrackingProtectionAction(from: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleClearCookiesAction(from state: TrackingProtectionState) -> TrackingProtectionState {
        return state
            .copy(trackingProtectionEnabled: !state.trackingProtectionEnabled)
            .copy(shouldClearCookies: true)
            .copy(shouldUpdateBlockedTrackerStats: false)
            .copy(shouldUpdateConnectionStatus: false)
            .copy(navigateTo: .home)
            .copy(displayView: nil)
    }

    private static func handleNavigateToSettingsAction(from state: TrackingProtectionState) -> TrackingProtectionState {
        return state
            .copy(shouldClearCookies: false)
            .copy(shouldUpdateBlockedTrackerStats: false)
            .copy(shouldUpdateConnectionStatus: false)
            .copy(navigateTo: .settings)
            .copy(displayView: nil)
    }

    private static func handleShowTrackingProtectionDetailsAction(
        from state: TrackingProtectionState
    ) -> TrackingProtectionState {
        return state
            .copy(shouldClearCookies: false)
            .copy(shouldUpdateBlockedTrackerStats: false)
            .copy(shouldUpdateConnectionStatus: false)
            .copy(navigateTo: nil)
            .copy(displayView: .trackingProtectionDetails)
    }

    private static func handleShowBlockedTrackersDetailsAction(
        from state: TrackingProtectionState
    ) -> TrackingProtectionState {
        return state
            .copy(shouldClearCookies: false)
            .copy(shouldUpdateBlockedTrackerStats: false)
            .copy(shouldUpdateConnectionStatus: false)
            .copy(navigateTo: nil)
            .copy(displayView: .blockedTrackersDetails)
    }

    private static func handleGoBackAction(from state: TrackingProtectionState) -> TrackingProtectionState {
        return state
            .copy(shouldClearCookies: false)
            .copy(shouldUpdateBlockedTrackerStats: false)
            .copy(shouldUpdateConnectionStatus: false)
            .copy(navigateTo: .back)
            .copy(displayView: nil)
    }

    private static func handleUpdateBlockedTrackerStatsAction(
        from state: TrackingProtectionState
    ) -> TrackingProtectionState {
        return state
            .copy(shouldUpdateBlockedTrackerStats: true)
            .copy(shouldUpdateConnectionStatus: false)
            .copy(navigateTo: nil)
            .copy(displayView: nil)
    }

    private static func handleUpdateConnectionStatusAction(from state: TrackingProtectionState) -> TrackingProtectionState {
        return state
            .copy(shouldClearCookies: false)
            .copy(shouldUpdateBlockedTrackerStats: false)
            .copy(shouldUpdateConnectionStatus: true)
            .copy(navigateTo: nil)
            .copy(displayView: nil)
    }

    private static func handleShowAlertAction(from state: TrackingProtectionState) -> TrackingProtectionState {
        return state
            .copy(shouldClearCookies: false)
            .copy(shouldUpdateBlockedTrackerStats: false)
            .copy(shouldUpdateConnectionStatus: false)
            .copy(navigateTo: nil)
            .copy(displayView: .clearCookiesAlert)
    }

    private static func handleToggleTrackingProtectionStatusAction(
        from state: TrackingProtectionState
    ) -> TrackingProtectionState {
        return state
            .copy(trackingProtectionEnabled: !state.trackingProtectionEnabled)
            .copy(shouldClearCookies: false)
            .copy(shouldUpdateBlockedTrackerStats: false)
            .copy(shouldUpdateConnectionStatus: false)
            .copy(navigateTo: nil)
            .copy(displayView: nil)
    }

    private static func handleDismissTrackingProtectionAction(
        from state: TrackingProtectionState
    ) -> TrackingProtectionState {
        return state
            .copy(shouldClearCookies: false)
            .copy(shouldUpdateBlockedTrackerStats: false)
            .copy(shouldUpdateConnectionStatus: false)
            .copy(navigateTo: .close)
            .copy(displayView: nil)
    }

    static func defaultState(from state: TrackingProtectionState) -> TrackingProtectionState {
        return state
            .copy(shouldClearCookies: false)
            .copy(shouldUpdateBlockedTrackerStats: false)
            .copy(shouldUpdateConnectionStatus: false)
            .copy(navigateTo: nil)
            .copy(displayView: nil)
    }
}
