/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = XCGLogger.defaultInstance()

public class DatabaseError: ErrorType {
    let err: NSError?

    public var description: String {
        return err?.localizedDescription ?? "Unknown database error."
    }

    init(err: NSError?) {
        self.err = err
    }
}

public class SQLiteRemoteClientsAndTabs: RemoteClientsAndTabs {
    let files: FileAccessor
    let db: BrowserDB
    let clients = RemoteClientsTable<RemoteClient>()
    let tabs = RemoteTabsTable<RemoteTab>()

    public init(files: FileAccessor) {
        self.files = files
        self.db = BrowserDB(files: files)!
        db.createOrUpdate(clients)
        db.createOrUpdate(tabs)
    }

    public func clear() -> Deferred<Result<()>> {
        let deferred = Deferred<Result<()>>(defaultQueue: dispatch_get_main_queue())

        var err: NSError?
        db.transaction(&err) { connection, _ in
            self.tabs.delete(connection, item: nil, err: &err)
            self.clients.delete(connection, item: nil, err: &err)
            if let err = err {
                let databaseError = DatabaseError(err: err)
                log.debug("Clear failed: \(databaseError)")
                deferred.fill(Result(failure: databaseError))
            } else {
                deferred.fill(Result(success: ()))
            }
            return true
        }

        return deferred
    }

    public func insertOrUpdateTabsForClient(client: String, tabs: [RemoteTab]) -> Deferred<Result<Int>> {
        let deferred = Deferred<Result<Int>>(defaultQueue: dispatch_get_main_queue())

        let deleteQuery = "DELETE FROM \(self.tabs.name) WHERE client_guid = ?"
        let deleteArgs: [AnyObject?] = [client]

        var err: NSError?

        db.transaction(&err) { connection, _ in
            // Delete any existing tabs.
            if let error = connection.executeChange(deleteQuery, withArgs: deleteArgs) {
                deferred.fill(Result(failure: DatabaseError(err: err)))
                return false
            }

            // Insert replacement tabs.
            var inserted = 0
            var err: NSError?
            for tab in tabs {
                // We trust that each tab's clientGUID matches the supplied client!
                // Really tabs shouldn't have a GUID at all. Future cleanup!
                inserted += self.tabs.insert(connection, item: tab, err: &err)
                if let err = err {
                    deferred.fill(Result(failure: DatabaseError(err: err)))
                    return false
                }
            }

            deferred.fill(Result(success: inserted))
            return true
        }

        return deferred
    }

    public func insertOrUpdateClient(client: RemoteClient) -> Deferred<Result<()>> {
        let deferred = Deferred<Result<()>>(defaultQueue: dispatch_get_main_queue())

        var err: NSError?
        db.transaction(&err) { connection, _ in
            // Update or insert client record.
            let updated = self.clients.update(connection, item: client, err: &err)
            if updated == 0 {
                let inserted = self.clients.insert(connection, item: client, err: &err)
            }

            if let err = err {
                let databaseError = DatabaseError(err: err)
                log.debug("insertOrUpdateClient failed: \(databaseError)")
                deferred.fill(Result(failure: databaseError))
                return false
            }

            deferred.fill(Result(success: ()))
            return true
        }

        return deferred
    }

    public func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>> {
        var err: NSError?
        let clients = db.query(&err) { connection, _ in
            return self.clients.query(connection, options: nil)
        }

        if let err = err {
            return Deferred(value: Result(failure: DatabaseError(err: err)))
        }

        let tabs = db.query(&err) { connection, _ in
            return self.tabs.query(connection, options: nil)
        }

        if let err = err {
            return Deferred(value: Result(failure: DatabaseError(err: err)))
        }

        let deferred = Deferred<Result<[ClientAndTabs]>>(defaultQueue: dispatch_get_main_queue())

        // Aggregate clientGUID -> RemoteTab.
        var acc = [String: [RemoteTab]]()
        for tab in tabs {
            if let tab = tab as? RemoteTab {
                if acc[tab.clientGUID] == nil {
                    acc[tab.clientGUID] = []
                }
                acc[tab.clientGUID]!.append(tab)
            }
        }

        // Most recent first.
        let sort: (RemoteTab, RemoteTab) -> Bool = { $0.lastUsed > $1.lastUsed }
        let f: (RemoteClient) -> ClientAndTabs = { client in
            let guid: String = client.guid
            let tabs = acc[guid]   // ?.sorted(sort)   // The sort should be unnecessary: the DB does that.
            return ClientAndTabs(client: client, tabs: tabs ?? [])
        }

        // Why is this whole function synchronous?
        deferred.fill(Result(success: clients.mapAsType(RemoteClient.self, f: f)))
        return deferred
    }

    private let debug_enabled = true
    private func debug(msg: String) {
        if debug_enabled {
            log.info(msg)
        }
    }
}