/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import Deferred

private let log = Logger.syncLogger

open class SQLiteRemoteClientsAndTabs: RemoteClientsAndTabs {
    let db: BrowserDB

    public init(db: BrowserDB) {
        self.db = db
    }
    
    class func remoteClientFactory(_ row: SDRow) -> RemoteClient {
        let guid = row["guid"] as? String
        let name = row["name"] as! String
        let mod = (row["modified"] as! NSNumber).uint64Value
        let type = row["type"] as? String
        let form = row["formfactor"] as? String
        let os = row["os"] as? String
        let version = row["version"] as? String
        let fxaDeviceId = row["fxaDeviceId"] as? String
        return RemoteClient(guid: guid, name: name, modified: mod, type: type, formfactor: form, os: os, version: version, fxaDeviceId: fxaDeviceId)
    }
    
    class func remoteTabFactory(_ row: SDRow) -> RemoteTab {
        let clientGUID = row["client_guid"] as? String
        let url = URL(string: row["url"] as! String)! // TODO: find a way to make this less dangerous.
        let title = row["title"] as! String
        let history = SQLiteRemoteClientsAndTabs.convertStringToHistory(row["history"] as? String)
        let lastUsed = row.getTimestamp("last_used")!
        return RemoteTab(clientGUID: clientGUID, URL: url, title: title, history: history, lastUsed: lastUsed, icon: nil)
    }

    class func convertStringToHistory(_ history: String?) -> [URL] {
        if let data = history?.data(using: String.Encoding.utf8) {
            if let urlStrings = try! JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments]) as? [String] {
                return optFilter(urlStrings.map { URL(string: $0) })
            }
        }
        return []
    }

    class func convertHistoryToString(_ history: [URL]) -> String? {
        let historyAsStrings = optFilter(history.map { $0.absoluteString })
        
        let data = try! JSONSerialization.data(withJSONObject: historyAsStrings, options: [])
        return String(data: data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
    }
    
    fileprivate func doWipe(_ f: @escaping (_ conn: SQLiteDBConnection, _ err: inout NSError?) -> Void) -> Deferred<Maybe<()>> {
        let deferred = Deferred<Maybe<()>>(defaultQueue: DispatchQueue.main)

        var err: NSError?
        _ = db.transaction(&err) { connection, _ in
            f(connection, &err)
            if let err = err {
                let databaseError = DatabaseError(err: err)
                log.debug("Wipe failed: \(databaseError)")
                deferred.fill(Maybe(failure: databaseError))
            } else {
                deferred.fill(Maybe(success: ()))
            }
            return true
        }

        return deferred
    }

    open func wipeClients() -> Deferred<Maybe<()>> {
        return self.doWipe { (conn, err: inout NSError?) -> Void in
            if let error = conn.executeChange("DELETE FROM \(TableClients)") {
                err = error
            }
        }
    }

    open func wipeRemoteTabs() -> Deferred<Maybe<()>> {
        return self.doWipe { (conn, err: inout NSError?) -> Void in
            if let error = conn.executeChange("DELETE FROM \(TableTabs) WHERE client_guid IS NOT NULL", withArgs: nil as Args?) {
                err = error
            }
        }
    }

    open func wipeTabs() -> Deferred<Maybe<()>> {
        return self.doWipe { (conn, err: inout NSError?) -> Void in
            if let error = conn.executeChange("DELETE FROM \(TableTabs)") {
                err = error
            }
        }
    }

    open func insertOrUpdateTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return self.insertOrUpdateTabsForClientGUID(nil, tabs: tabs)
    }

    open func insertOrUpdateTabsForClientGUID(_ clientGUID: String?, tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        let deferred = Deferred<Maybe<Int>>(defaultQueue: DispatchQueue.main)

        let deleteQuery = "DELETE FROM \(TableTabs) WHERE client_guid IS ?"
        let deleteArgs: Args = [clientGUID]

        var err: NSError?

        _ = db.transaction(&err) { connection, _ in
            // Delete any existing tabs.
            if let _ = connection.executeChange(deleteQuery, withArgs: deleteArgs) {
                log.warning("Deleting existing tabs failed.")
                deferred.fill(Maybe(failure: DatabaseError(err: err)))
                return false
            }

            // Insert replacement tabs.
            var inserted = 0
            for tab in tabs {
                let args: Args = [
                    tab.clientGUID,
                    tab.URL.absoluteString,
                    tab.title,
                    SQLiteRemoteClientsAndTabs.convertHistoryToString(tab.history),
                    NSNumber(value: tab.lastUsed)
                ]
                
                let lastInsertedRowID = connection.lastInsertedRowID
                
                // We trust that each tab's clientGUID matches the supplied client!
                // Really tabs shouldn't have a GUID at all. Future cleanup!
                if let error = connection.executeChange("INSERT INTO \(TableTabs) (client_guid, url, title, history, last_used) VALUES (?, ?, ?, ?, ?)", withArgs: args) {
                    err = error
                    log.warning("INSERT INTO \(TableTabs) failed: \(error)")
                    deferred.fill(Maybe(failure: DatabaseError(err: error)))
                    return false
                }
                
                if connection.lastInsertedRowID == lastInsertedRowID {
                    log.debug("Unable to INSERT RemoteTab!")
                } else {
                    inserted += 1
                }
            }

            deferred.fill(Maybe(success: inserted))
            return true
        }

        return deferred
    }

    open func insertOrUpdateClients(_ clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        let deferred = Deferred<Maybe<Int>>(defaultQueue: DispatchQueue.main)

        var err: NSError?

        // TODO: insert multiple clients in a single query.
        // ORM systems are foolish.
        _ = db.transaction(&err) { connection, _ in
            var succeeded = 0

            // Update or insert client records.
            for client in clients {
                let args: Args = [
                    client.name,
                    NSNumber(value: client.modified),
                    client.type,
                    client.formfactor,
                    client.os,
                    client.version,
                    client.fxaDeviceId,
                    client.guid
                ]
                
                if let error = connection.executeChange("UPDATE \(TableClients) SET name = ?, modified = ?, type = ?, formfactor = ?, os = ?, version = ?, fxaDeviceId = ? WHERE guid = ?", withArgs: args) {
                    err = error
                    log.warning("UPDATE \(TableClients) failed: \(error)")
                    deferred.fill(Maybe(failure: DatabaseError(err: error)))
                    return false
                }
                
                if connection.numberOfRowsModified == 0 {
                    let args: Args = [
                        client.guid,
                        client.name,
                        NSNumber(value: client.modified),
                        client.type,
                        client.formfactor,
                        client.os,
                        client.version,
                        client.fxaDeviceId
                    ]
                    
                    let lastInsertedRowID = connection.lastInsertedRowID
                    
                    if let error = connection.executeChange("INSERT INTO \(TableClients) (guid, name, modified, type, formfactor, os, version, fxaDeviceId) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", withArgs: args) {
                        err = error
                        log.warning("INSERT INTO \(TableClients) failed: \(error)")
                        deferred.fill(Maybe(failure: DatabaseError(err: error)))
                        return false
                    }
                    
                    if connection.lastInsertedRowID == lastInsertedRowID {
                        log.debug("INSERT did not change last inserted row ID.")
                    }
                }
                
                succeeded += 1
            }

            deferred.fill(Maybe(success: succeeded))
            return true
        }

        return deferred
    }

    open func insertOrUpdateClient(_ client: RemoteClient) -> Deferred<Maybe<Int>> {
        return insertOrUpdateClients([client])
    }

    open func getClientWithId(_ clientID: GUID) -> Deferred<Maybe<RemoteClient?>> {
        return self.db.runQuery("SELECT * FROM \(TableClients) WHERE guid = ?", args: [clientID], factory: SQLiteRemoteClientsAndTabs.remoteClientFactory) >>== { deferMaybe($0[0]) }
    }

    open func getClients() -> Deferred<Maybe<[RemoteClient]>> {
        var err: NSError?

        let clientCursor = db.withConnection(&err) { connection, _ in
            return connection.executeQuery("SELECT * FROM \(TableClients) WHERE EXISTS (SELECT 1 FROM \(TableRemoteDevices) rd WHERE rd.guid = fxaDeviceId) ORDER BY modified DESC", factory: SQLiteRemoteClientsAndTabs.remoteClientFactory)
        }

        if let err = err {
            clientCursor.close()
            return deferMaybe(DatabaseError(err: err))
        }

        let clients = clientCursor.asArray()
        clientCursor.close()

        return deferMaybe(clients)
    }

    open func getClientGUIDs() -> Deferred<Maybe<Set<GUID>>> {
        let c = db.runQuery("SELECT guid FROM \(TableClients) WHERE guid IS NOT NULL", args: nil, factory: { $0["guid"] as! String })
        return c >>== { cursor in
            let guids = Set<GUID>(cursor.asArray())
            return deferMaybe(guids)
        }
    }

    open func getTabsForClientWithGUID(_ guid: GUID?) -> Deferred<Maybe<[RemoteTab]>> {
        let tabsSQL: String
        let clientArgs: Args?
        if let _ = guid {
            tabsSQL = "SELECT * FROM \(TableTabs) WHERE client_guid = ?"
            clientArgs = [guid]
        } else {
            tabsSQL = "SELECT * FROM \(TableTabs) WHERE client_guid IS NULL"
            clientArgs = nil
        }

        log.debug("Looking for tabs for client with guid: \(guid ?? "nil")")
        return db.runQuery(tabsSQL, args: clientArgs, factory: SQLiteRemoteClientsAndTabs.remoteTabFactory) >>== {
            let tabs = $0.asArray()
            log.debug("Found \(tabs.count) tabs for client with guid: \(guid ?? "nil")")
            return deferMaybe(tabs)
        }
    }

    open func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        var err: NSError?

        // Now find the clients.
        let clientCursor = db.withConnection(&err) { connection, _ in
            return connection.executeQuery("SELECT * FROM \(TableClients) WHERE EXISTS (SELECT 1 FROM \(TableRemoteDevices) rd WHERE rd.guid = fxaDeviceId) ORDER BY modified DESC", factory: SQLiteRemoteClientsAndTabs.remoteClientFactory)
        }

        if let err = err {
            clientCursor.close()
            return deferMaybe(DatabaseError(err: err))
        }

        let clients = clientCursor.asArray()
        clientCursor.close()

        log.debug("Found \(clients.count) clients in the DB.")

        let tabCursor = db.withConnection(&err) { connection, _ in
            return connection.executeQuery("SELECT * FROM \(TableTabs) WHERE client_guid IS NOT NULL ORDER BY client_guid DESC, last_used DESC", factory: SQLiteRemoteClientsAndTabs.remoteTabFactory)
        }

        log.debug("Found \(tabCursor.count) raw tabs in the DB.")

        if let err = err {
            tabCursor.close()
            return deferMaybe(DatabaseError(err: err))
        }

        let deferred = Deferred<Maybe<[ClientAndTabs]>>(defaultQueue: DispatchQueue.main)

        // Aggregate clientGUID -> RemoteTab.
        var acc = [String: [RemoteTab]]()
        for tab in tabCursor {
            if let tab = tab, let guid = tab.clientGUID {
                if acc[guid] == nil {
                    acc[guid] = [tab]
                } else {
                    acc[guid]!.append(tab)
                }
            } else {
                log.error("Couldn't cast tab (\(tab ??? "nil")) to RemoteTab.")
            }
        }

        tabCursor.close()

        // Most recent first.
        let fillTabs: (RemoteClient) -> ClientAndTabs = { client in
            var tabs: [RemoteTab]? = nil
            if let guid: String = client.guid {
                tabs = acc[guid]
            }
            return ClientAndTabs(client: client, tabs: tabs ?? [])
        }

        let removeLocalClient: (RemoteClient) -> Bool = { client in
            return client.guid != nil
        }

        // Why is this whole function synchronous?
        deferred.fill(Maybe(success: clients.filter(removeLocalClient).map(fillTabs)))
        return deferred
    }

    open func deleteCommands() -> Success {
        var err: NSError?
        _ = db.transaction(&err) { connection, _ in
            if let error = connection.executeChange("DELETE FROM \(TableSyncCommands)", withArgs: [] as Args) {
                print(error.description)
                err = error
                return false
            }
            
            return true
        }

        return failOrSucceed(err, op: "deleteCommands")
    }

    open func deleteCommands(_ clientGUID: GUID) -> Success {
        var err: NSError?
        _ = db.transaction(&err) { connection, _ in
            if let error = connection.executeChange("DELETE FROM \(TableSyncCommands) WHERE client_guid = ?", withArgs: [clientGUID] as Args) {
                print(error.description)
                err = error
                return false
            }
            
            return true
        }

        return failOrSucceed(err, op: "deleteCommands")
    }

    open func insertCommand(_ command: SyncCommand, forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        return insertCommands([command], forClients: clients)
    }

    open func insertCommands(_ commands: [SyncCommand], forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        var err: NSError?
        var numberOfInserts = 0
        _ = db.transaction(&err) { connection, _ in
            // Update or insert client records.
            for command in commands {
                for client in clients {
                    if let commandID = self.insert(connection, sql: "INSERT INTO \(TableSyncCommands) (client_guid, value) VALUES (?, ?)", args: [client.guid, command.value] as Args, err: &err) {
                        log.verbose("Inserted command: \(commandID)")
                        numberOfInserts += 1
                    } else {
                        if let err = err {
                            log.debug("insertCommands:forClients failed: \(err)")
                            return false
                        }
                        log.warning("Command not inserted, but no error!")
                    }
                }
            }
            return true
        }
        return failOrSucceed(err, op: "insert command", val: numberOfInserts)
    }

    open func getCommands() -> Deferred<Maybe<[GUID: [SyncCommand]]>> {
        var err: NSError?

        // Now find the clients.
        let commandCursor = db.withConnection(&err) { connection, _ in
            connection.executeQuery("SELECT * FROM \(TableSyncCommands)", factory: { row -> SyncCommand in
                SyncCommand(
                    id: row["command_id"] as? Int,
                    value: row["value"] as! String,
                    clientGUID: row["client_guid"] as? GUID)
            })
        }

        if let err = err {
            commandCursor.close()
            return failOrSucceed(err, op: "getCommands", val: [GUID: [SyncCommand]]())
        }

        let allCommands = commandCursor.asArray()
        commandCursor.close()

        let clientSyncCommands = clientsFromCommands(allCommands)

        log.debug("Found \(clientSyncCommands.count) client sync commands in the DB.")
        return failOrSucceed(err, op: "get commands", val: clientSyncCommands)
    }

    func clientsFromCommands(_ commands: [SyncCommand]) -> [GUID: [SyncCommand]] {
        var syncCommands = [GUID: [SyncCommand]]()
        for command in commands {
            var cmds: [SyncCommand] = syncCommands[command.clientGUID!] ?? [SyncCommand]()
            cmds.append(command)
            syncCommands[command.clientGUID!] = cmds
        }
        return syncCommands
    }
    
    func insert(_ db: SQLiteDBConnection, sql: String, args: Args?, err: inout NSError?) -> Int? {
        let lastID = db.lastInsertedRowID
        if let error = db.executeChange(sql, withArgs: args) {
            err = error
            return nil
        }
        
        let id = db.lastInsertedRowID
        if id == lastID {
            log.debug("INSERT did not change last inserted row ID.")
            return nil
        }
        
        return id
    }
}

extension SQLiteRemoteClientsAndTabs: RemoteDevices {
    open func replaceRemoteDevices(_ remoteDevices: [RemoteDevice]) -> Success {
        // Drop corrupted records and our own record too.
        let remoteDevices = remoteDevices.filter { $0.id != nil && $0.type != nil && !$0.isCurrentDevice }

        let deferred = Success()
        var err: NSError?
        let resultError = self.db.transaction(&err) { (conn, err: inout NSError?) in
            func change(_ sql: String, args: Args?=nil) -> Bool {
                if let e = conn.executeChange(sql, withArgs: args) {
                    err = e
                    deferred.fillIfUnfilled(Maybe(failure: DatabaseError(err: e)))
                    return false
                }
                return true
            }

            _ = change("DELETE FROM \(TableRemoteDevices)")

            if err != nil {
                return false
            }

            let now = Date.now()
            for device in remoteDevices {
                let sql =
                    "INSERT INTO \(TableRemoteDevices) (guid, name, type, is_current_device, date_created, date_modified, last_access_time) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)"
                let args: Args = [device.id, device.name, device.type, device.isCurrentDevice, now, now, device.lastAccessTime]
                if !change(sql, args: args) {
                    break
                }
            }

            if err != nil {
                return false
            }

            // Commit the result.
            return true
        }

        if let err = resultError {
            log.warning("Got error “\(err.localizedDescription)”")
            deferred.fillIfUnfilled(Maybe(failure: DatabaseError(err: err)))
        } else {
            deferred.fillIfUnfilled(Maybe(success: ()))
        }

        return deferred
    }
}

extension SQLiteRemoteClientsAndTabs: ResettableSyncStorage {
    public func resetClient() -> Success {
        // For this engine, resetting is equivalent to wiping.
        return self.clear()
    }

    public func clear() -> Success {
        return self.doWipe { (conn, err: inout NSError?) -> Void in
            if let error = conn.executeChange("DELETE FROM \(TableTabs) WHERE client_guid IS NOT NULL") {
                err = error
            }
            if let error = conn.executeChange("DELETE FROM \(TableClients)") {
                err = error
            }
        }
    }
}

extension SQLiteRemoteClientsAndTabs: AccountRemovalDelegate {
    public func onRemovedAccount() -> Success {
        log.info("Clearing clients and tabs after account removal.")
        // TODO: Bug 1168690 - delete our client and tabs records from the server.
        return self.resetClient()
    }
}
