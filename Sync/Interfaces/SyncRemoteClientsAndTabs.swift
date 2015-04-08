/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Account
import Shared
import Storage


public class SyncRemoteClientsAndTabs: RemoteClientsAndTabs {
    private let db: SQLiteRemoteClientsAndTabs
    private let account: FirefoxAccount?

    public init(files: FileAccessor, account: FirefoxAccount?) {
        self.db = SQLiteRemoteClientsAndTabs(files: files)
        self.account = account
    }

    public func wipeClients() -> Deferred<Result<()>> {
        return self.db.wipeClients()
    }

    public func wipeTabs() -> Deferred<Result<()>> {
        return self.db.wipeTabs()
    }

    public func getClients() -> Deferred<Result<[RemoteClient]>> {
        return self.db.getClients()
    }

    public func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>> {
        return self.db.getClientsAndTabs()
    }

    public func insertOrUpdateClient(client: RemoteClient) -> Deferred<Result<()>> {
        return self.db.insertOrUpdateClient(client)
    }

    public func insertOrUpdateClients(clients: [RemoteClient]) -> Deferred<Result<()>> {
        return self.db.insertOrUpdateClients(clients)
    }

    public func insertOrUpdateTabsForClientGUID(clientGUID: String, tabs: [RemoteTab]) -> Deferred<Result<Int>> {
        return self.db.insertOrUpdateTabsForClientGUID(clientGUID, tabs: tabs)
    }
}
