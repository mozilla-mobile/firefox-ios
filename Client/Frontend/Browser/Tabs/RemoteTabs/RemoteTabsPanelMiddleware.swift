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
        case RemoteTabsPanelAction.refreshCachedTabs:
            self.refreshTabs(updateCache: false)
        default:
            break
        }
    }

    // MARK: - Internal Utilities

    private func refreshTabs(updateCache: Bool = false) {
        ensureMainThread { [self] in
            guard profile.hasSyncableAccount() else {
                DispatchQueue.main.async {
                    store.dispatch(RemoteTabsPanelAction.refreshDidFail(.notLoggedIn))
                }
                return
            }

            let syncEnabled = (profile.prefs.boolForKey(PrefsKeys.TabSyncEnabled) == true)
            guard syncEnabled else {
                DispatchQueue.main.async {
                    store.dispatch(RemoteTabsPanelAction.refreshDidFail(.syncDisabledByUser))
                }
                return
            }

            profile.getCachedClientsAndTabs { [weak self] result in
                ensureMainThread {
                    guard let clientAndTabs = result else {
                        store.dispatch(RemoteTabsPanelAction.refreshDidFail(.failedToSync))
                        return
                    }

                    let results = RemoteTabsPanelCachedResults(clientAndTabs: clientAndTabs,
                                                               isUpdating: updateCache)
                    store.dispatch(RemoteTabsPanelAction.cachedTabsAvailable(results))

                    if updateCache {
                        self?.profile.getClientsAndTabs { result in
                            ensureMainThread {
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
    }
}
