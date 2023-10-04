// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared
import Storage

struct RemoteTabsPanelState {
    let refreshState: RemoteTabsPanelRefreshState
    let clientAndTabs: [ClientAndTabs]
    let allowsRefresh: Bool // True if hasSyncableAccount
    let showingError: RemoteTabsPanelErrorState?
    let syncIsSupported: Bool // Reference: `prefs.boolForKey(PrefsKeys.TabSyncEnabled)`

    static func emptyState() -> RemoteTabsPanelState {
        return RemoteTabsPanelState(refreshState: .loaded,
                                    clientAndTabs: [],
                                    allowsRefresh: false,
                                    showingError: nil,
                                    syncIsSupported: true)
    }
}

enum RemoteTabsPanelRefreshState {
    case loaded
    case refreshing
}

// This now replaces RemoteTabsErrorDataSource.ErrorType
enum RemoteTabsPanelErrorState {
    case notLoggedIn
    case noClients
    case noTabs
    case failedToSync
    case syncDisabledByUser
}
