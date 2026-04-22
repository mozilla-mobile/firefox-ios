// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux
import Storage

import struct MozillaAppServices.Device

/// Status of Sync tab refresh.
enum RemoteTabsPanelRefreshState {
    /// Not performing any type of refresh.
    case idle
    /// Currently performing a refresh of the user's tabs.
    case refreshing
    /// Currently performing a sync of the user's tabs.
    case syncingTabs
}

/// Replaces LegacyRemoteTabsErrorDataSource.ErrorType
enum RemoteTabsPanelEmptyStateReason {
    case notLoggedIn
    case noClients
    case noTabs
    case failedToSync
    case syncDisabledByUser

    func localizedString() -> String {
        switch self {
        case .notLoggedIn: return .EmptySyncedTabsPanelNotSignedInStateDescription
        case .noClients: return .EmptySyncedTabsPanelNullStateDescription
        case .noTabs: return .RemoteTabErrorNoTabs
        case .failedToSync: return .RemoteTabErrorFailedToSync
        case .syncDisabledByUser: return .TabsTray.Sync.SyncTabsDisabled
        }
    }

    /// Whether this state allows the user to refresh tabs.
    var allowsRefresh: Bool {
        switch self {
        case .notLoggedIn, .syncDisabledByUser:
            return false
        default:
            return true
        }
    }
}

/// State for RemoteTabsPanel. WIP.
@CopyWithUpdates
struct RemoteTabsPanelState: ScreenState, Sendable {
    let windowUUID: WindowUUID
    let refreshState: RemoteTabsPanelRefreshState
    let allowsRefresh: Bool
    let clientAndTabs: [ClientAndTabs]
    let showingEmptyState: RemoteTabsPanelEmptyStateReason?// If showing empty (or error) state
    let devices: [Device]

    init(appState: AppState, uuid: WindowUUID) {
        guard let panelState = appState.componentState(
            RemoteTabsPanelState.self,
            for: .remoteTabsPanel,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self = panelState.copyWithUpdates()
    }

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  refreshState: .idle,
                  allowsRefresh: false,
                  clientAndTabs: [],
                  showingEmptyState: .noTabs,
                  devices: [])
    }

    init(windowUUID: WindowUUID,
         refreshState: RemoteTabsPanelRefreshState,
         allowsRefresh: Bool,
         clientAndTabs: [ClientAndTabs],
         showingEmptyState: RemoteTabsPanelEmptyStateReason?,
         devices: [Device]
    ) {
        self.windowUUID = windowUUID
        self.refreshState = refreshState
        self.allowsRefresh = allowsRefresh
        self.clientAndTabs = clientAndTabs
        self.showingEmptyState = showingEmptyState
        self.devices = devices
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID,
              let action = action as? RemoteTabsPanelAction else { return defaultState(from: state) }

        switch action.actionType {
        case RemoteTabsPanelActionType.refreshDidBegin:
            return handleRefreshDidBeginAction(state: state)
        case RemoteTabsPanelActionType.refreshDidFail:
            guard let reason = action.reason else { return defaultState(from: state) }
            // Refresh failed. Show error empty state.
            return handleRefreshDidFailAction(reason: reason, state: state)
        case RemoteTabsPanelActionType.refreshDidSucceed:
            guard let clientAndTabs = action.clientAndTabs else { return defaultState(from: state) }
            return handleRefreshDidSucceedAction(clientAndTabs: clientAndTabs,
                                                 state: state,
                                                 action: action)
        case RemoteTabsPanelActionType.remoteDevicesChanged:
            guard let devices = action.devices else { return defaultState(from: state) }
            return handleRemoteDevicesChangedAction(devices: devices, state: state)
        case RemoteTabsPanelActionType.syncDidBegin:
            return handleSyncDidBeginAction(state: state)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleRefreshDidBeginAction(state: RemoteTabsPanelState) -> RemoteTabsPanelState {
        return state.copyWithUpdates(refreshState: .refreshing)
    }

    private static func handleRefreshDidFailAction(reason: RemoteTabsPanelEmptyStateReason,
                                                   state: RemoteTabsPanelState) -> RemoteTabsPanelState {
        let allowsRefresh = reason.allowsRefresh
        return state.copyWithUpdates(refreshState: .idle,
                                     allowsRefresh: allowsRefresh,
                                     showingEmptyState: reason)
    }

    private static func handleRefreshDidSucceedAction(clientAndTabs: [ClientAndTabs],
                                                      state: RemoteTabsPanelState,
                                                      action: RemoteTabsPanelAction) -> RemoteTabsPanelState {
        return state.copyWithUpdates(refreshState: .idle,
                                     allowsRefresh: true,
                                     clientAndTabs: clientAndTabs,
                                     showingEmptyState: nil,
                                     devices: action.devices ?? state.devices)
    }

    private static func handleRemoteDevicesChangedAction(devices: [Device],
                                                         state: RemoteTabsPanelState) -> RemoteTabsPanelState {
        return state.copyWithUpdates(refreshState: .idle,
                                     devices: devices)
    }

    private static func handleSyncDidBeginAction(state: RemoteTabsPanelState) -> RemoteTabsPanelState {
        return state.copyWithUpdates(refreshState: .syncingTabs,
                                     allowsRefresh: false)
    }

    static func defaultState(from state: RemoteTabsPanelState) -> RemoteTabsPanelState {
        return state.copyWithUpdates()
    }
}
