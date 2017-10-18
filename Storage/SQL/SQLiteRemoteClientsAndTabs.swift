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
        guard let data = history?.data(using: String.Encoding.utf8),
            let decoded = try? JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.allowFragments]),
            let urlStrings = decoded as? [String] else {
                return []
        }
        return optFilter(urlStrings.flatMap { URL(string: $0) }) 
    }

    class func convertHistoryToString(_ history: [URL]) -> String? {
        let historyAsStrings = optFilter(history.map { $0.absoluteString })
        
        guard let data = try? JSONSerialization.data(withJSONObject: historyAsStrings, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
    }

    open func wipeClients() -> Success {
        return db.run("DELETE FROM \(TableClients)")
    }

    open func wipeRemoteTabs() -> Success {
        return db.run("DELETE FROM \(TableTabs) WHERE client_guid IS NOT NULL")
    }

    open func wipeTabs() -> Success {
        return db.run("DELETE FROM \(TableTabs)")
    }

    open func insertOrUpdateTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return self.insertOrUpdateTabsForClientGUID(nil, tabs: tabs)
    }

    open func insertOrUpdateTabsForClientGUID(_ clientGUID: String?, tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        let deleteQuery = "DELETE FROM \(TableTabs) WHERE client_guid IS ?"
        let deleteArgs: Args = [clientGUID]

        return db.transaction { connection -> Int in
            // Delete any existing tabs.
            try connection.executeChange(deleteQuery, withArgs: deleteArgs)

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
                try connection.executeChange("INSERT INTO \(TableTabs) (client_guid, url, title, history, last_used) VALUES (?, ?, ?, ?, ?)", withArgs: args)
                
                if connection.lastInsertedRowID == lastInsertedRowID {
                    log.debug("Unable to INSERT RemoteTab!")
                } else {
                    inserted += 1
                }
            }

            return inserted
        }
    }

    open func insertOrUpdateClients(_ clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        // TODO: insert multiple clients in a single query.
        // ORM systems are foolish.
        return db.transaction { connection -> Int in
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
                
                try connection.executeChange("UPDATE \(TableClients) SET name = ?, modified = ?, type = ?, formfactor = ?, os = ?, version = ?, fxaDeviceId = ? WHERE guid = ?", withArgs: args)
                
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
                    
                    try connection.executeChange("INSERT INTO \(TableClients) (guid, name, modified, type, formfactor, os, version, fxaDeviceId) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", withArgs: args)
                    
                    if connection.lastInsertedRowID == lastInsertedRowID {
                        log.debug("INSERT did not change last inserted row ID.")
                    }
                }
                
                succeeded += 1
            }

            return succeeded
        }
    }

    open func insertOrUpdateClient(_ client: RemoteClient) -> Deferred<Maybe<Int>> {
        return insertOrUpdateClients([client])
    }

    open func deleteClient(guid: GUID) -> Success {
        let deleteTabsQuery = "DELETE FROM \(TableTabs) WHERE client_guid = ?"
        let deleteClientQuery = "DELETE FROM \(TableClients) WHERE guid = ?"
        let deleteArgs: Args = [guid]

        return db.transaction { connection -> Void in
            try connection.executeChange(deleteClientQuery, withArgs: deleteArgs)
            try connection.executeChange(deleteTabsQuery, withArgs: deleteArgs)
        }
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
        return db.withConnection { connection -> [RemoteClient] in
            let cursor = connection.executeQuery("SELECT * FROM \(TableClients) WHERE EXISTS (SELECT 1 FROM \(TableRemoteDevices) rd WHERE rd.guid = fxaDeviceId) ORDER BY modified DESC", factory: SQLiteRemoteClientsAndTabs.remoteClientFactory)
            defer {
                cursor.close()
            }

            return cursor.asArray()
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
        return db.withConnection { conn -> ([RemoteClient], [RemoteTab]) in
            let clientsCursor = conn.executeQuery("SELECT * FROM \(TableClients) WHERE EXISTS (SELECT 1 FROM \(TableRemoteDevices) rd WHERE rd.guid = fxaDeviceId) ORDER BY modified DESC", factory: SQLiteRemoteClientsAndTabs.remoteClientFactory)
            let tabsCursor = conn.executeQuery("SELECT * FROM \(TableTabs) WHERE client_guid IS NOT NULL ORDER BY client_guid DESC, last_used DESC", factory: SQLiteRemoteClientsAndTabs.remoteTabFactory)

            defer {
                clientsCursor.close()
                tabsCursor.close()
            }

            return (clientsCursor.asArray(), tabsCursor.asArray())
        } >>== { clients, tabs in
            var acc = [String: [RemoteTab]]()
            for tab in tabs {
                if let guid = tab.clientGUID {
                    if acc[guid] == nil {
                        acc[guid] = [tab]
                    } else {
                        acc[guid]!.append(tab)
                    }
                } else {
                    log.error("RemoteTab (\(tab)) has a nil clientGUID")
                }
            }

            // Most recent first.
            let fillTabs: (RemoteClient) -> ClientAndTabs = { client in
                var tabs: [RemoteTab]? = nil
                if let guid: String = client.guid {
                    tabs = acc[guid]
                }
                return ClientAndTabs(client: client, tabs: tabs ?? [])
            }

            return deferMaybe(clients.map(fillTabs))
        }
    }

    open func deleteCommands() -> Success {
        return db.run("DELETE FROM \(TableSyncCommands)")
    }

    open func deleteCommands(_ clientGUID: GUID) -> Success {
        return db.run("DELETE FROM \(TableSyncCommands) WHERE client_guid = ?", withArgs: [clientGUID] as Args)
    }

    open func insertCommand(_ command: SyncCommand, forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        return insertCommands([command], forClients: clients)
    }

    open func insertCommands(_ commands: [SyncCommand], forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        return db.transaction { connection -> Int in
            var numberOfInserts = 0

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
                        log.error("insertCommands(_:, forClients:) failed: \(err.localizedDescription) (numberOfInserts: \(numberOfInserts)")
                        throw err
                    }
                }
            }

            return numberOfInserts
        }
    }

    open func getCommands() -> Deferred<Maybe<[GUID: [SyncCommand]]>> {
        return db.withConnection { connection -> [GUID: [SyncCommand]] in
            let cursor = connection.executeQuery("SELECT * FROM \(TableSyncCommands)", factory: { row -> SyncCommand in
                SyncCommand(
                    id: row["command_id"] as? Int,
                    value: row["value"] as! String,
                    clientGUID: row["client_guid"] as? GUID)
            })
            defer {
                cursor.close()
            }

            return self.clientsFromCommands(cursor.asArray())
        }
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
        try db.executeChange(sql, withArgs: args)
        
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

        return db.transaction { conn -> Void in
            try conn.executeChange("DELETE FROM \(TableRemoteDevices)")

            let now = Date.now()

            for device in remoteDevices {
                let sql =
                    "INSERT INTO \(TableRemoteDevices) (guid, name, type, is_current_device, date_created, date_modified, last_access_time) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)"
                let args: Args = [device.id, device.name, device.type, device.isCurrentDevice, now, now, device.lastAccessTime]
                try conn.executeChange(sql, withArgs: args)
            }
        }
    }
}

extension SQLiteRemoteClientsAndTabs: ResettableSyncStorage {
    public func resetClient() -> Success {
        // For this engine, resetting is equivalent to wiping.
        return self.clear()
    }

    public func clear() -> Success {
        return db.transaction { conn -> Void in
            try conn.executeChange("DELETE FROM \(TableTabs) WHERE client_guid IS NOT NULL")
            try conn.executeChange("DELETE FROM \(TableClients)")
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
