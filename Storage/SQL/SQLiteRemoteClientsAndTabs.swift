/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = XCGLogger.defaultInstance()

public class SQLiteRemoteClientsAndTabs: RemoteClientsAndTabs {
    let db: BrowserDB
    let clients = RemoteClientsTable<RemoteClient>()
    let tabs = RemoteTabsTable<RemoteTab>()

    public init(db: BrowserDB) {
        self.db = db
        db.createOrUpdate(clients)
        db.createOrUpdate(tabs)
    }

    private func doWipe(f: (conn: SQLiteDBConnection, inout err: NSError?) -> ()) -> Deferred<Result<()>> {
        let deferred = Deferred<Result<()>>(defaultQueue: dispatch_get_main_queue())

        var err: NSError?
        db.transaction(&err) { connection, _ in
            f(conn: connection, err: &err)
            if let err = err {
                let databaseError = DatabaseError(err: err)
                log.debug("Wipe failed: \(databaseError)")
                deferred.fill(Result(failure: databaseError))
            } else {
                deferred.fill(Result(success: ()))
            }
            return true
        }

        return deferred
    }

    public func wipeClients() -> Deferred<Result<()>> {
        return self.doWipe { (conn, inout err: NSError?) -> () in
            self.clients.delete(conn, item: nil, err: &err)
        }
    }

    public func wipeTabs() -> Deferred<Result<()>> {
        return self.doWipe { (conn, inout err: NSError?) -> () in
            self.tabs.delete(conn, item: nil, err: &err)
        }
    }

    public func clear() -> Deferred<Result<()>> {
        return self.doWipe { (conn, inout err: NSError?) -> () in
            self.tabs.delete(conn, item: nil, err: &err)
            self.clients.delete(conn, item: nil, err: &err)
        }
    }

    public func insertOrUpdateTabs(tabs: [RemoteTab]) -> Deferred<Result<Int>> {
        return self.insertOrUpdateTabsForClientGUID(nil, tabs: tabs)
    }

    public func insertOrUpdateTabsForClientGUID(clientGUID: String?, tabs: [RemoteTab]) -> Deferred<Result<Int>> {
        let deferred = Deferred<Result<Int>>(defaultQueue: dispatch_get_main_queue())

        let deleteQuery = "DELETE FROM \(self.tabs.name) WHERE client_guid IS ?"
        let deleteArgs: [AnyObject?] = [clientGUID]

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
                self.tabs.insert(connection, item: tab, err: &err)
                if let err = err {
                    deferred.fill(Result(failure: DatabaseError(err: err)))
                    return false
                }
                inserted++;
            }

            deferred.fill(Result(success: inserted))
            return true
        }

        return deferred
    }

    public func insertOrUpdateClients(clients: [RemoteClient]) -> Deferred<Result<()>> {
        let deferred = Deferred<Result<()>>(defaultQueue: dispatch_get_main_queue())

        var err: NSError?

        // TODO: insert multiple clients in a single query.
        // ORM systems are foolish.
        db.transaction(&err) { connection, _ in
            // Update or insert client records.
            for client in clients {

                let updated = self.clients.update(connection, item: client, err: &err)
                log.info("Updated clients: \(updated)")

                if err == nil && updated == 0 {
                    let inserted = self.clients.insert(connection, item: client, err: &err)
                    log.info("Inserted clients: \(inserted)")
                }

                if let err = err {
                    let databaseError = DatabaseError(err: err)
                    log.debug("insertOrUpdateClients failed: \(databaseError)")
                    deferred.fill(Result(failure: databaseError))
                    return false
                }
            }

            deferred.fill(Result(success: ()))
            return true
        }

        return deferred
    }

    public func insertOrUpdateClient(client: RemoteClient) -> Deferred<Result<()>> {
        return insertOrUpdateClients([client])
    }

    public func getClients() -> Deferred<Result<[RemoteClient]>> {
        var err: NSError?

        let clientCursor = db.withReadableConnection(&err) { connection, _ in
            return self.clients.query(connection, options: nil)
        }

        if let err = err {
            clientCursor.close()
            return Deferred(value: Result(failure: DatabaseError(err: err)))
        }

        let clients = clientCursor.asArray()
        clientCursor.close()

        return Deferred(value: Result(success: clients))
    }

    public func getClientsAndTabs() -> Deferred<Result<[ClientAndTabs]>> {
        var err: NSError?

        // Now find the clients.
        let clientCursor = db.withReadableConnection(&err) { connection, _ in
            return self.clients.query(connection, options: nil)
        }

        if let err = err {
            clientCursor.close()
            return Deferred(value: Result(failure: DatabaseError(err: err)))
        }

        let clients = clientCursor.asArray()
        clientCursor.close()

        log.info("Found \(clients.count) clients in the DB.")

        let tabCursor = db.withReadableConnection(&err) { connection, _ in
            return self.tabs.query(connection, options: nil)
        }

        log.info("Found \(tabCursor.count) raw tabs in the DB.")

        if let err = err {
            tabCursor.close()
            return Deferred(value: Result(failure: DatabaseError(err: err)))
        }

        let deferred = Deferred<Result<[ClientAndTabs]>>(defaultQueue: dispatch_get_main_queue())

        // Aggregate clientGUID -> RemoteTab.
        var acc = [String: [RemoteTab]]()
        for tab in tabCursor {
            if let tab = tab, guid = tab.clientGUID {
                if acc[guid] == nil {
                    acc[guid] = [tab]
                } else {
                    acc[guid]!.append(tab)
                }
            } else {
                log.error("Couldn't cast tab \(tab) to RemoteTab.")
            }
        }

        tabCursor.close()
        log.info("Accumulated tabs with client GUIDs \(acc.keys).")

        // Most recent first.
        let sort: (RemoteTab, RemoteTab) -> Bool = { $0.lastUsed > $1.lastUsed }
        let fillTabs: (RemoteClient) -> ClientAndTabs = { client in
            var tabs: [RemoteTab]? = nil
            if let guid: String = client.guid {
                tabs = acc[guid]   // ?.sorted(sort)   // The sort should be unnecessary: the DB does that.
            }
            return ClientAndTabs(client: client, tabs: tabs ?? [])
        }

        let removeLocalClient: (RemoteClient) -> Bool = { client in
            return client.guid != nil
        }

        // Why is this whole function synchronous?
        deferred.fill(Result(success: clients.filter(removeLocalClient).map(fillTabs)))
        return deferred
    }

    public func onRemovedAccount() -> Success {
        log.info("Clearing clients and tabs after account removal.")
        // TODO: Bug 1168690 - delete our client and tabs records from the server.
        return self.clear()
    }

    private let debug_enabled = true
    private func debug(msg: String) {
        if debug_enabled {
            log.info(msg)
        }
    }
}
