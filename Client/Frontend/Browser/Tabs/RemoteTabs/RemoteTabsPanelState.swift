// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import Storage

/// Status of tab refresh.
enum RemoteTabsPanelRefreshState {
    case loaded
    case refreshing
}

/// Replaces RemoteTabsErrorDataSource.ErrorType
enum RemoteTabsPanelEmptyState {
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
}

/// State for RemoteTabsPanel. WIP.
struct RemoteTabsPanelState: ScreenState, Equatable {
    let refreshState: RemoteTabsPanelRefreshState
    let clientAndTabs: [ClientAndTabs]
    let allowsRefresh: Bool                                // True if `hasSyncableAccount()`
    let showingEmptyState: RemoteTabsPanelEmptyState?      // If showing empty (or error) state
    let syncIsSupported: Bool                              // Reference: `prefs.boolForKey(PrefsKeys.TabSyncEnabled)`

    init(_ appState: AppState) {
//        guard let panelState = store.state.screenState(RemoteTabsPanelState.self, for: .remoteTabsPanel) else {
//            self.init()
//            logger.log("Error retrieving screen state",
//                       level: .debug,
//                       category: .redux)
//        }
//        self.init(
        self.init()
    }

    init() {
        refreshState = .loaded
        clientAndTabs = []
        allowsRefresh = false
        showingEmptyState = .noTabs
        syncIsSupported = false
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        default: return state
        }
    }
}
