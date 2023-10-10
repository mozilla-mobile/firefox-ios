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
        let tabPanelState = state.screenState(RemoteTabsPanelState.self, for: .remoteTabsPanel)
        switch action {
        case RemoteTabsPanelAction.refreshTabs:
            self.updateSyncableAccountState(for: tabPanelState, then: { refreshAllowed in
                if refreshAllowed {
                    self.refreshTabs(updateCache: true)
                } else {
                    store.dispatch(RemoteTabsPanelAction.refreshDidFail(.notLoggedIn))
                }
            })
        case RemoteTabsPanelAction.refreshCachedTabs:
            self.refreshTabs(updateCache: false)
        default:
            break
        }
    }

    // MARK: - Internal Utilities

    private func updateSyncableAccountState(for state: RemoteTabsPanelState?,
                                            then action: ((Bool) -> Void)? = nil) {
        guard let state else { return }
        let allowsRefresh = profile.hasSyncableAccount()
        if state.allowsRefresh != allowsRefresh {
            DispatchQueue.main.async {
                store.dispatch(RemoteTabsPanelAction.syncableAccountStatusChanged(allowsRefresh))
                action?(allowsRefresh)
            }
        } else {
            action?(allowsRefresh)
        }
    }

    private func refreshTabs(updateCache: Bool = false) {
        ensureMainThread { [self] in
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
