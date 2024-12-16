// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common
import Shared

struct TrackingProtectionState: StateType, Equatable, ScreenState {
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
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case TrackingProtectionMiddlewareActionType.clearCookies:
            return handleClearCookiesAction(from: state)
        case TrackingProtectionMiddlewareActionType.navigateToSettings:
            return handleNavigateToSettingsAction(from: state)
        case TrackingProtectionMiddlewareActionType.showTrackingProtectionDetails:
            return handleShowTrackingProtectionDetailsAction(from: state)
        case TrackingProtectionMiddlewareActionType.showBlockedTrackersDetails:
            return showBlockedTrackersDetailsState(from: state)
        case TrackingProtectionActionType.goBack:
            return goBackState(from: state)
        case TrackingProtectionActionType.updateBlockedTrackerStats:
            return updateBlockedTrackerStatsState(from: state)
        case TrackingProtectionActionType.updateConnectionStatus:
            return updateConnectionStatusState(from: state)
        case TrackingProtectionMiddlewareActionType.showAlert:
            return showAlertState(from: state)
        case TrackingProtectionActionType.toggleTrackingProtectionStatus:
            return toggleTrackingProtectionStatusState(from: state)
        case TrackingProtectionMiddlewareActionType.dismissTrackingProtection:
            return dismissTrackingProtectionState(from: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleClearCookiesAction(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            trackingProtectionEnabled: !state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            shouldClearCookies: true,
            shouldUpdateBlockedTrackerStats: false,
            shouldUpdateConnectionStatus: false,
            navigateTo: .home,
            displayView: nil
        )
    }

    private static func handleNavigateToSettingsAction(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            trackingProtectionEnabled: state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false,
            shouldUpdateConnectionStatus: false,
            navigateTo: .settings,
            displayView: nil
        )
    }

    private static func handleShowTrackingProtectionDetailsAction(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            trackingProtectionEnabled: state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false,
            shouldUpdateConnectionStatus: false,
            navigateTo: nil,
            displayView: .trackingProtectionDetails
        )
    }

    private static func showBlockedTrackersDetailsState(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            trackingProtectionEnabled: state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false,
            shouldUpdateConnectionStatus: false,
            navigateTo: nil,
            displayView: .blockedTrackersDetails
        )
    }

    private static func goBackState(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            trackingProtectionEnabled: state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false,
            shouldUpdateConnectionStatus: false,
            navigateTo: .back,
            displayView: nil
        )
    }

    private static func updateBlockedTrackerStatsState(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            trackingProtectionEnabled: state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            shouldClearCookies: state.shouldClearCookies,
            shouldUpdateBlockedTrackerStats: true,
            shouldUpdateConnectionStatus: false,
            navigateTo: nil,
            displayView: nil
        )
    }

    private static func updateConnectionStatusState(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            trackingProtectionEnabled: state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false,
            shouldUpdateConnectionStatus: true,
            navigateTo: nil,
            displayView: nil
        )
    }

    private static func showAlertState(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            trackingProtectionEnabled: state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false,
            shouldUpdateConnectionStatus: false,
            navigateTo: nil,
            displayView: .clearCookiesAlert
        )
    }

    private static func toggleTrackingProtectionStatusState(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            trackingProtectionEnabled: !state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false,
            shouldUpdateConnectionStatus: false,
            navigateTo: nil,
            displayView: nil
        )
    }

    private static func dismissTrackingProtectionState(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            trackingProtectionEnabled: state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false,
            shouldUpdateConnectionStatus: false,
            navigateTo: .close,
            displayView: nil
        )
    }

    static func defaultState(from state: TrackingProtectionState) -> TrackingProtectionState {
        return TrackingProtectionState(
            windowUUID: state.windowUUID,
            trackingProtectionEnabled: state.trackingProtectionEnabled,
            connectionSecure: state.connectionSecure,
            shouldClearCookies: false,
            shouldUpdateBlockedTrackerStats: false,
            shouldUpdateConnectionStatus: false,
            navigateTo: nil,
            displayView: nil
        )
    }
}
