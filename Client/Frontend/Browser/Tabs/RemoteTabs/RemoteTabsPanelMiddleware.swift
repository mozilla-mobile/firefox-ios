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
            // TODO: WIP; additional changes forthcoming. [FXIOS-7509]
            self.refreshTabs(updateCache: true)
            break
        default:
            break
        }
    }

    // MARK: - Internal Utilities

    private func refreshTabs(updateCache: Bool = false) {
        ensureMainThread { [self] in
            guard profile.hasSyncableAccount() else {
                store.dispatch(RemoteTabsPanelAction.refreshDidFail)
                return
            }

            // TODO: Work-in-progress. [FXIOS-7509]
            profile.getCachedClientsAndTabs().uponQueue(.main) { [weak self] result in
                guard let clientAndTabs = result.successValue else {
                    store.dispatch(RemoteTabsPanelAction.refreshDidFail)
                    return
                }

                if updateCache {
                    self?.profile.getClientsAndTabs().uponQueue(.main) { result in
                        guard let clientAndTabs = result.successValue else {
                            store.dispatch(RemoteTabsPanelAction.refreshDidFail)
                            return
                        }

                        store.dispatch(RemoteTabsPanelAction.refreshDidSucceed(clientAndTabs))
                    }
                } else {
                    store.dispatch(RemoteTabsPanelAction.refreshDidSucceed(clientAndTabs))
                }
            }
        }
    }
}
