/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger

private let log = XCGLogger.defaultInstance()

public class SQLiteRemoteClientsAndTabs: RemoteClientsAndTabs {
    let files: FileAccessor
    let db: BrowserDB
    let clients = RemoteClientsTable<RemoteClient>()
    let tabs = RemoteTabsTable<RemoteTab>()

    public required init(files: FileAccessor) {
        self.files = files
        self.db = BrowserDB(files: files)!
        db.createOrUpdate(clients)
        db.createOrUpdate(tabs)
    }

    public func clear(complete: (success: Bool) -> Void) {
        var err: NSError?
        db.transaction(&err) { connection, _ in
            self.tabs.delete(connection, item: nil, err: &err)
            self.clients.delete(connection, item: nil, err: &err)
            return true
        }
        dispatch_async(dispatch_get_main_queue()) {
            if err != nil {
                self.debug("Clear failed: \(err!.localizedDescription)")
                complete(success: false)
            } else {
                complete(success: true)
            }
        }
    }

    public func insertOrUpdateClient(client: RemoteClient, complete: (success: Bool) -> Void) {
        var err: NSError?
        db.transaction(&err) { connection, _ in
            // Update or insert client record.
            let updated = self.clients.update(connection, item: client, err: &err)
            if updated == 0 {
                let inserted = self.clients.insert(connection, item: client, err: &err)
            }
            if err != nil {
                return false
            }
            // Delete any existing tabs.
            let deleteQuery = "DELETE FROM \(self.tabs.name) WHERE client_guid = ?"
            let deleteArgs: [AnyObject?] = [client.GUID] // Swift crashes without the type annotation.
            if let error = connection.executeChange(deleteQuery, withArgs: deleteArgs) {
                err = error
                return false
            }
            // Insert replacement tabs.
            for tab in client.tabs {
                let updated = self.tabs.update(connection, item: tab, err: &err)
                if updated == 0 {
                    let inserted = self.tabs.insert(connection, item: tab, err: &err)
                }
                if err != nil {
                    return false
                }
            }
            return true
        }
        dispatch_async(dispatch_get_main_queue()) {
            if err != nil {
                self.debug("insertOrUpdateClient failed: \(err!.localizedDescription)")
            }
            complete(success: err == nil)
        }
    }

    public func getClientsAndTabs(complete: (clients: [RemoteClient]?) -> Void) {
        var res: [RemoteClient]! = nil

        var err: NSError?
        let clients = db.query(&err) { connection, _ in
            return self.clients.query(connection, options: nil)
        }
        if err == nil {
            let tabs = db.query(&err) { connection, _ in
                return self.tabs.query(connection, options: nil)
            }
            if err == nil {
                // Aggregate clientGUID -> RemoteTab.
                var D = [String: [RemoteTab]]()
                for tab in tabs {
                    if let tab = tab as? RemoteTab {
                        if D[tab.clientGUID] == nil {
                            D[tab.clientGUID] = []
                        }
                        D[tab.clientGUID]?.append(tab)
                    }
                }

                res = []
                for client in clients {
                    if let client = client as? RemoteClient {
                        // It's possible a client exists with no tabs at all, so handle that case.
                        let tabs = D[client.GUID] ?? []
                        res.append(client.withTabs(tabs.sorted { $0.position < $1.position }))
                    }
                }
                res.sort { $0.lastModified < $1.lastModified }
            }
        }

        dispatch_async(dispatch_get_main_queue()) {
            if err != nil {
                self.debug("getClientsAndTabs failed: \(err!.localizedDescription)")
                complete(clients: nil)
            } else {
                complete(clients: res)
            }
        }
    }

    private let debug_enabled = true
    private func debug(msg: String) {
        if debug_enabled {
            log.info(msg)
        }
    }

}