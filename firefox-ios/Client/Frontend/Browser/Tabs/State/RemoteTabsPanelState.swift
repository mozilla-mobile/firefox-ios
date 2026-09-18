// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Redux

import struct MozillaAppServices.Device
import struct Storage.ClientAndTabs

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

/// Tabs or an empty state, if empty then why.
enum RemoteTabsPanelContentState: Equatable {
    case tabs
    case empty(RemoteTabsPanelEmptyStateReason)
}

/// State for RemoteTabsPanel. WIP.
@Copyable
struct RemoteTabsPanelState: ScreenState, Sendable {
    let windowUUID: WindowUUID
    let refreshState: RemoteTabsPanelRefreshState
    let allowsRefresh: Bool
    let clientAndTabs: [ClientAndTabs]
    let contentState: RemoteTabsPanelContentState
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

        self.init(windowUUID: panelState.windowUUID,
                  refreshState: panelState.refreshState,
                  allowsRefresh: panelState.allowsRefresh,
                  clientAndTabs: panelState.clientAndTabs,
                  contentState: panelState.contentState,
                  devices: panelState.devices)
    }

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  refreshState: .idle,
                  allowsRefresh: false,
                  clientAndTabs: [],
                  contentState: .empty(.noTabs),
                  devices: [])
    }

    init(windowUUID: WindowUUID,
         refreshState: RemoteTabsPanelRefreshState,
         allowsRefresh: Bool,
         clientAndTabs: [ClientAndTabs],
         contentState: RemoteTabsPanelContentState,
         devices: [Device]
    ) {
        self.windowUUID = windowUUID
        self.refreshState = refreshState
        self.allowsRefresh = allowsRefresh
        self.clientAndTabs = clientAndTabs
        self.contentState = contentState
        self.devices = devices
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
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
        return state.copy(refreshState: .refreshing)
    }

    private static func handleRefreshDidFailAction(reason: RemoteTabsPanelEmptyStateReason,
                                                   state: RemoteTabsPanelState) -> RemoteTabsPanelState {
        return state
            .copy(refreshState: .idle)
            .copy(allowsRefresh: reason.allowsRefresh)
            .copy(contentState: .empty(reason))
    }

    private static func handleRefreshDidSucceedAction(clientAndTabs: [ClientAndTabs],
                                                      state: RemoteTabsPanelState,
                                                      action: RemoteTabsPanelAction) -> RemoteTabsPanelState {
        return state
            .copy(refreshState: .idle)
            .copy(allowsRefresh: true)
            .copy(clientAndTabs: clientAndTabs)
            .copy(contentState: contentState(for: clientAndTabs))
            .copy(devices: action.devices ?? state.devices)
    }

    private static func contentState(for clientAndTabs: [ClientAndTabs]) -> RemoteTabsPanelContentState {
        if clientAndTabs.isEmpty {
            return .empty(.noClients)
        }

        if clientAndTabs.allSatisfy({ $0.tabs.isEmpty }) {
            return .empty(.noTabs)
        }

        return .tabs
    }

    private static func handleRemoteDevicesChangedAction(devices: [Device],
                                                         state: RemoteTabsPanelState) -> RemoteTabsPanelState {
        return state
            .copy(refreshState: .idle)
            .copy(devices: devices)
    }

    private static func handleSyncDidBeginAction(state: RemoteTabsPanelState) -> RemoteTabsPanelState {
        return state
            .copy(refreshState: .syncingTabs)
            .copy(allowsRefresh: false)
    }

    static func defaultState(from state: RemoteTabsPanelState) -> RemoteTabsPanelState {
        return RemoteTabsPanelState(windowUUID: state.windowUUID,
                                    refreshState: state.refreshState,
                                    allowsRefresh: state.allowsRefresh,
                                    clientAndTabs: state.clientAndTabs,
                                    contentState: state.contentState,
                                    devices: state.devices)
    }
}
