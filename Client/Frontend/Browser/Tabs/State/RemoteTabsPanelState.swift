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

    init(_ appState: AppState) {
        guard let panelState = store.state.screenState(RemoteTabsPanelState.self, for: .remoteTabsPanel) else {
            self.init()
            return
        }

        self.init(refreshState: panelState.refreshState,
                  allowsRefresh: panelState.allowsRefresh,
                  clientAndTabs: panelState.clientAndTabs,
                  showingEmptyState: panelState.showingEmptyState)
    }

    init() {
        self.init(refreshState: .idle,
                  allowsRefresh: false,
                  clientAndTabs: [],
                  showingEmptyState: .noTabs)
    }

    init(refreshState: RemoteTabsPanelRefreshState,
         allowsRefresh: Bool,
         clientAndTabs: [ClientAndTabs],
         showingEmptyState: RemoteTabsPanelEmptyStateReason?) {
        self.refreshState = refreshState
        self.allowsRefresh = allowsRefresh
        self.clientAndTabs = clientAndTabs
        self.showingEmptyState = showingEmptyState
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case RemoteTabsPanelAction.refreshTabs:
            // No change to state until middleware performs necessary logic to
            // determine whether we can sync account
            return state
        case RemoteTabsPanelAction.refreshDidBegin:
            let newState = RemoteTabsPanelState(refreshState: .refreshing,
                                                allowsRefresh: state.allowsRefresh,
                                                clientAndTabs: state.clientAndTabs,
                                                showingEmptyState: state.showingEmptyState)
            return newState
        case RemoteTabsPanelAction.refreshDidFail(let reason):
            // Refresh failed. Show error empty state.
            let allowsRefresh = reason.allowsRefresh
            let newState = RemoteTabsPanelState(refreshState: .idle,
                                                allowsRefresh: allowsRefresh,
                                                clientAndTabs: state.clientAndTabs,
                                                showingEmptyState: reason)
            return newState
        case RemoteTabsPanelAction.refreshDidSucceed(let newClientAndTabs):
            // Send client and tabs state, ensure empty state is nil and refresh is idle
            let newState = RemoteTabsPanelState(refreshState: .idle,
                                                allowsRefresh: true,
                                                clientAndTabs: newClientAndTabs,
                                                showingEmptyState: nil)
            return newState
        case RemoteTabsPanelAction.cachedTabsAvailable(let cachedResults):
            let newState = RemoteTabsPanelState(refreshState: cachedResults.isUpdating ? .refreshing : .idle,
                                                allowsRefresh: true,
                                                clientAndTabs: cachedResults.clientAndTabs,
                                                showingEmptyState: nil)
            return newState
        default:
            return state
        }
    }
}
