// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Common
import Shared
import Redux

class RemoteTabsPanelMiddleware {
    private let profile: Profile

    init(profile: Profile = AppContainer.shared.resolve()) {
        self.profile = profile
    }

    lazy var remoteTabsPanelProvider: Middleware<AppState> = { state, action in
        switch action {
        case RemoteTabsPanelAction.refreshTabs:
            self.refreshTabs(updateCache: true)
        default:
            break
        }
    }

    // MARK: - Internal Utilities

    private func refreshTabs(updateCache: Bool = false) {
        ensureMainThread { [self] in
            let hasSyncableAccount = profile.hasSyncableAccount()
            guard hasSyncableAccount else {
                store.dispatch(RemoteTabsPanelAction.refreshDidFail(.notLoggedIn))
                return
            }

            let syncEnabled = (profile.prefs.boolForKey(PrefsKeys.TabSyncEnabled) == true)
            guard syncEnabled else {
                store.dispatch(RemoteTabsPanelAction.refreshDidFail(.syncDisabledByUser))
                return
            }

            // If above checks have succeeded, we know we can perform the tab refresh. We
            // need to update the State to .refreshing since there are implications for being
            // in the middle of a refresh (pull-to-refresh shouldn't trigger a new update etc.)
            store.dispatch(RemoteTabsPanelAction.refreshDidBegin)

            self.profile.getCachedClientsAndTabs { [weak self] result in
                guard let clientAndTabs = result else {
                    store.dispatch(RemoteTabsPanelAction.refreshDidFail(.failedToSync))
                    return
                }

                let results = RemoteTabsPanelCachedResults(clientAndTabs: clientAndTabs,
                                                           isUpdating: updateCache)
                store.dispatch(RemoteTabsPanelAction.cachedTabsAvailable(results))

                if updateCache {
                    self?.profile.getClientsAndTabs { result in
                        guard let clientAndTabs = result else {
                            store.dispatch(RemoteTabsPanelAction.refreshDidFail(.failedToSync))
                            return
                        }
                        store.dispatch(RemoteTabsPanelAction.refreshDidSucceed(clientAndTabs))
                    }
                }
            }
        }
    }
}
