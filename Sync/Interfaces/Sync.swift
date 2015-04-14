/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Account
import Shared
import Storage

private func syncClientsToStorage(storage: RemoteClientsAndTabs, ready: Ready, prefs: Prefs) -> Deferred<Result<()>> {
    let clientSynchronizer = ready.synchronizer(ClientsSynchronizer.self, prefs: prefs)
    return clientSynchronizer.synchronizeLocalClients(storage, withServer: ready.client, info: ready.info)
}

private func syncTabsToStorage(storage: RemoteClientsAndTabs, ready: Ready, prefs: Prefs) -> Deferred<Result<()>> {
    let tabSynchronizer = ready.synchronizer(TabsSynchronizer.self, prefs: prefs)
    return tabSynchronizer.synchronizeLocalTabs(storage, withServer: ready.client, info: ready.info)
}

public class Sync {
    public class func fetchSyncedTabsToStorage(storage: RemoteClientsAndTabs, account: FirefoxAccount, syncPrefs: Prefs) -> Deferred<Result<[ClientAndTabs]>> {
        let url = ProductionSync15Configuration().tokenServerEndpointURL
        let authState = account.syncAuthState(url)
        let ready = SyncStateMachine.toReady(authState, prefs: syncPrefs)
        return chainDeferred(ready, { r in
            let clientsDone = syncClientsToStorage(storage, r, syncPrefs)
            return chainDeferred(clientsDone, { () -> Deferred<Result<[ClientAndTabs]>> in
                let tabsDone = syncTabsToStorage(storage, r, syncPrefs)
                return chainDeferred(tabsDone, {
                    return storage.getClientsAndTabs()
                })
            })
        })
    }
}