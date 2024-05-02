// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import Storage

/// Status of Sync tab refresh.
enum RemoteTabsPanelRefreshState {
    /// Not performing any type of refresh.
    case idle
    /// Currently performing a refresh of the user's tabs.
    case refreshing
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
struct RemoteTabsPanelState: ScreenState, Equatable {
    let refreshState: RemoteTabsPanelRefreshState
    let allowsRefresh: Bool
    let clientAndTabs: [ClientAndTabs]
    let showingEmptyState: RemoteTabsPanelEmptyStateReason?// If showing empty (or error) state
    let windowUUID: WindowUUID

    init(appState: AppState, uuid: WindowUUID) {
        guard let panelState = store.state.screenState(RemoteTabsPanelState.self,
                                                       for: .remoteTabsPanel,
                                                       window: uuid) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: panelState.windowUUID,
                  refreshState: panelState.refreshState,
                  allowsRefresh: panelState.allowsRefresh,
                  clientAndTabs: panelState.clientAndTabs,
                  showingEmptyState: panelState.showingEmptyState)
    }

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  refreshState: .idle,
                  allowsRefresh: false,
                  clientAndTabs: [],
                  showingEmptyState: .noTabs)
    }

    init(windowUUID: WindowUUID,
         refreshState: RemoteTabsPanelRefreshState,
         allowsRefresh: Bool,
         clientAndTabs: [ClientAndTabs],
         showingEmptyState: RemoteTabsPanelEmptyStateReason?) {
        self.windowUUID = windowUUID
        self.refreshState = refreshState
        self.allowsRefresh = allowsRefresh
        self.clientAndTabs = clientAndTabs
        self.showingEmptyState = showingEmptyState
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID,
              let action = action as? RemoteTabsPanelAction else { return state }

        switch action.actionType {
        case RemoteTabsPanelActionType.refreshDidBegin:
            let newState = RemoteTabsPanelState(windowUUID: state.windowUUID,
                                                refreshState: .refreshing,
                                                allowsRefresh: state.allowsRefresh,
                                                clientAndTabs: state.clientAndTabs,
                                                showingEmptyState: state.showingEmptyState)
            return newState
        case RemoteTabsPanelActionType.refreshDidFail:
            guard let reason = action.reason else { return state }
            // Refresh failed. Show error empty state.
            let allowsRefresh = reason.allowsRefresh
            let newState = RemoteTabsPanelState(windowUUID: state.windowUUID,
                                                refreshState: .idle,
                                                allowsRefresh: allowsRefresh,
                                                clientAndTabs: state.clientAndTabs,
                                                showingEmptyState: reason)
            return newState
        case RemoteTabsPanelActionType.refreshDidSucceed:
            guard let clientAndTabs = action.clientAndTabs else { return state }
            let newState = RemoteTabsPanelState(windowUUID: state.windowUUID,
                                                refreshState: .idle,
                                                allowsRefresh: true,
                                                clientAndTabs: clientAndTabs,
                                                showingEmptyState: nil)
            return newState
        default:
            return state
        }
    }
}
