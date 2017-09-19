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
    
    fileprivate func doWipe(_ f: @escaping (_ conn: SQLiteDBConnection) -> NSError?) -> Deferred<Maybe<()>> {
        let deferred = Deferred<Maybe<()>>(defaultQueue: DispatchQueue.main)

        _ = db.transaction { conn -> Bool in
            if let err = f(conn) {
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
        return doWipe { conn -> NSError? in
            conn.executeChange("DELETE FROM \(TableClients)")
        }
    }

    open func wipeRemoteTabs() -> Deferred<Maybe<()>> {
        return doWipe { conn -> NSError? in
            conn.executeChange("DELETE FROM \(TableTabs) WHERE client_guid IS NOT NULL", withArgs: nil as Args?)
        }
    }

    open func wipeTabs() -> Deferred<Maybe<()>> {
        return doWipe { conn -> NSError? in
            conn.executeChange("DELETE FROM \(TableTabs)")
        }
    }

    open func insertOrUpdateTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return self.insertOrUpdateTabsForClientGUID(nil, tabs: tabs)
    }

    open func insertOrUpdateTabsForClientGUID(_ clientGUID: String?, tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        let deferred = Deferred<Maybe<Int>>(defaultQueue: DispatchQueue.main)

        let deleteQuery = "DELETE FROM \(TableTabs) WHERE client_guid IS ?"
        let deleteArgs: Args = [clientGUID]

        _ = db.transaction { connection -> Bool in
            // Delete any existing tabs.
            if let err = connection.executeChange(deleteQuery, withArgs: deleteArgs) {
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
                if let err = connection.executeChange("INSERT INTO \(TableTabs) (client_guid, url, title, history, last_used) VALUES (?, ?, ?, ?, ?)", withArgs: args) {
                    log.warning("INSERT INTO \(TableTabs) failed: \(err)")
                    deferred.fill(Maybe(failure: DatabaseError(err: err)))
                    throw err
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

        // TODO: insert multiple clients in a single query.
        // ORM systems are foolish.
        _ = db.transaction { connection -> Bool in
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
                
                if let err = connection.executeChange("UPDATE \(TableClients) SET name = ?, modified = ?, type = ?, formfactor = ?, os = ?, version = ?, fxaDeviceId = ? WHERE guid = ?", withArgs: args) {
                    log.warning("UPDATE \(TableClients) failed: \(err)")
                    deferred.fill(Maybe(failure: DatabaseError(err: err)))
                    throw err
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
                    
                    if let err = connection.executeChange("INSERT INTO \(TableClients) (guid, name, modified, type, formfactor, os, version, fxaDeviceId) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", withArgs: args) {
                        log.warning("INSERT INTO \(TableClients) failed: \(err)")
                        deferred.fill(Maybe(failure: DatabaseError(err: err)))
                        throw err
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

    open func deleteClient(guid: GUID) -> Success {
        let deferred = Success(defaultQueue: DispatchQueue.main)

        let deleteTabsQuery = "DELETE FROM \(TableTabs) WHERE client_guid = ?"
        let deleteClientQuery = "DELETE FROM \(TableClients) WHERE guid = ?"
        let deleteArgs: Args = [guid]

        _ = db.transaction { connection -> Bool in
            var err: NSError? = nil
            if let error = connection.executeChange(deleteClientQuery, withArgs: deleteArgs) {
                log.warning("Deleting client failed.")
                err = error
            }

            // Delete any existing tabs.
            if let error = connection.executeChange(deleteTabsQuery, withArgs: deleteArgs) {
                log.warning("Deleting client tabs failed.")
                err = error
            }

            guard err == nil else {
                deferred.fill(Maybe(failure: DatabaseError(err: err)))
                return false
            }
            
            deferred.fill(Maybe(success: ()))
            return true
        }
        
        return deferred
    }

    open func getClient(guid: GUID) -> Deferred<Maybe<RemoteClient?>> {
        let factory = SQLiteRemoteClientsAndTabs.remoteClientFactory
        return self.db.runQuery("SELECT * FROM \(TableClients) WHERE guid = ?", args: [guid], factory: factory) >>== { deferMaybe($0[0]) }
    }

    open func getClient(fxaDeviceId: String) -> Deferred<Maybe<RemoteClient?>> {
        let factory = SQLiteRemoteClientsAndTabs.remoteClientFactory
        return self.db.runQuery("SELECT * FROM \(TableClients) WHERE fxaDeviceId = ?", args: [fxaDeviceId], factory: factory) >>== { deferMaybe($0[0]) }
    }

    open func getClientWithId(_ clientID: GUID) -> Deferred<Maybe<RemoteClient?>> {
        return self.getClient(guid: clientID)
    }

    open func getClients() -> Deferred<Maybe<[RemoteClient]>> {
        do {
            let clientCursor = try db.withConnection { connection in
                return connection.executeQuery("SELECT * FROM \(TableClients) WHERE EXISTS (SELECT 1 FROM \(TableRemoteDevices) rd WHERE rd.guid = fxaDeviceId) ORDER BY modified DESC", factory: SQLiteRemoteClientsAndTabs.remoteClientFactory)
            }
            
            let clients = clientCursor.asArray()
            clientCursor.close()
            
            return deferMaybe(clients)
        } catch let err as NSError {
            return deferMaybe(DatabaseError(err: err))
        }
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
        // Now find the clients.
        let clients: [RemoteClient]
        do {
            let clientCursor = try db.withConnection { connection in
                return connection.executeQuery("SELECT * FROM \(TableClients) WHERE EXISTS (SELECT 1 FROM \(TableRemoteDevices) rd WHERE rd.guid = fxaDeviceId) ORDER BY modified DESC", factory: SQLiteRemoteClientsAndTabs.remoteClientFactory)
            }
            
            clients = clientCursor.asArray()
            clientCursor.close()
        } catch let err as NSError {
            return deferMaybe(DatabaseError(err: err))
        }

        log.debug("Found \(clients.count) clients in the DB.")

        var acc = [String: [RemoteTab]]()
        do {
            let tabCursor = try db.withConnection { connection in
                return connection.executeQuery("SELECT * FROM \(TableTabs) WHERE client_guid IS NOT NULL ORDER BY client_guid DESC, last_used DESC", factory: SQLiteRemoteClientsAndTabs.remoteTabFactory)
            }
            
            log.debug("Found \(tabCursor.count) raw tabs in the DB.")
            
            // Aggregate clientGUID -> RemoteTab.
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
        } catch let err as NSError {
            return deferMaybe(DatabaseError(err: err))
        }

        let deferred = Deferred<Maybe<[ClientAndTabs]>>(defaultQueue: DispatchQueue.main)

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
        let err = db.transaction { connection -> Bool in
            if let err = connection.executeChange("DELETE FROM \(TableSyncCommands)", withArgs: [] as Args) {
                print(err.localizedDescription)
                throw err
            }

            return true
        }

        return failOrSucceed(err, op: "deleteCommands")
    }

    open func deleteCommands(_ clientGUID: GUID) -> Success {
        let err = db.transaction { connection -> Bool in
            if let err = connection.executeChange("DELETE FROM \(TableSyncCommands) WHERE client_guid = ?", withArgs: [clientGUID] as Args) {
                print(err.localizedDescription)
                throw err
            }

            return true
        }

        return failOrSucceed(err, op: "deleteCommands")
    }

    open func insertCommand(_ command: SyncCommand, forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        return insertCommands([command], forClients: clients)
    }

    open func insertCommands(_ commands: [SyncCommand], forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        var numberOfInserts = 0
        let err = db.transaction { connection -> Bool in
            // Update or insert client records.
            for command in commands {
                for client in clients {
                    do {
                        if let commandID = try self.insert(connection, sql: "INSERT INTO \(TableSyncCommands) (client_guid, value) VALUES (?, ?)", args: [client.guid, command.value] as Args) {
                            log.verbose("Inserted command: \(commandID)")
                            numberOfInserts += 1
                        } else {
                            log.warning("Command not inserted, but no error!")
                        }
                    } catch let err as NSError {
                        log.debug("insertCommands:forClients failed: \(err)")
                        throw err
                    }
                }
            }
            return true
        }
        return failOrSucceed(err, op: "insert command", val: numberOfInserts)
    }

    open func getCommands() -> Deferred<Maybe<[GUID: [SyncCommand]]>> {
        // Now find the clients.
        let allCommands: [SyncCommand]
        do {
            let commandCursor = try db.withConnection { connection in
                connection.executeQuery("SELECT * FROM \(TableSyncCommands)", factory: { row -> SyncCommand in
                    SyncCommand(
                        id: row["command_id"] as? Int,
                        value: row["value"] as! String,
                        clientGUID: row["client_guid"] as? GUID)
                })
            }
            
            allCommands = commandCursor.asArray()
            commandCursor.close()
        } catch let err as NSError {
            return failOrSucceed(err, op: "getCommands", val: [GUID: [SyncCommand]]())
        }

        let clientSyncCommands = clientsFromCommands(allCommands)

        log.debug("Found \(clientSyncCommands.count) client sync commands in the DB.")
        return deferMaybe(clientSyncCommands)
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
    
    func insert(_ db: SQLiteDBConnection, sql: String, args: Args?) throws -> Int? {
        let lastID = db.lastInsertedRowID
        if let err = db.executeChange(sql, withArgs: args) {
            throw err
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

        if let err = self.db.transaction({ conn -> Bool in
            func change(_ sql: String, args: Args?=nil) throws {
                if let err = conn.executeChange(sql, withArgs: args) {
                    deferred.fillIfUnfilled(Maybe(failure: DatabaseError(err: err)))
                    throw err
                }
            }

            try change("DELETE FROM \(TableRemoteDevices)")

            let now = Date.now()
            for device in remoteDevices {
                let sql =
                    "INSERT INTO \(TableRemoteDevices) (guid, name, type, is_current_device, date_created, date_modified, last_access_time) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)"
                let args: Args = [device.id, device.name, device.type, device.isCurrentDevice, now, now, device.lastAccessTime]
                try change(sql, args: args)
            }

            // Commit the result.
            return true
        }) {
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
        return doWipe { conn -> NSError? in
            var err: NSError? = nil
            err = conn.executeChange("DELETE FROM \(TableTabs) WHERE client_guid IS NOT NULL")
            err = conn.executeChange("DELETE FROM \(TableClients)")
            return err
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
