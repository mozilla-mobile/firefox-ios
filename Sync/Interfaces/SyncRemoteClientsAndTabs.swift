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

    public func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>> {
        return self.db.getClientsAndTabs()
    }
}
