/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.syncLogger

public class SQLiteRemoteClientsAndTabs: RemoteClientsAndTabs {
    let db: BrowserDB
    let clients = RemoteClientsTable<RemoteClient>()
    let tabs = RemoteTabsTable<RemoteTab>()
    let commands = SyncCommandsTable<SyncCommand>()

    public init(db: BrowserDB) {
        self.db = db
        self.db.createOrUpdate(clients, tabs, commands)
    }

    private func doWipe(f: (conn: SQLiteDBConnection, inout err: NSError?) -> ()) -> Deferred<Maybe<()>> {
        let deferred = Deferred<Maybe<()>>(defaultQueue: dispatch_get_main_queue())

        var err: NSError?
        db.transaction(&err) { connection, _ in
            f(conn: connection, err: &err)
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

    public func wipeClients() -> Deferred<Maybe<()>> {
        return self.doWipe { (conn, inout err: NSError?) -> () in
            self.clients.delete(conn, item: nil, err: &err)
        }
    }

    public func wipeRemoteTabs() -> Deferred<Maybe<()>> {
        return self.doWipe { (conn, inout err: NSError?) -> () in
            if let error = conn.executeChange("DELETE FROM \(self.tabs.name) WHERE client_guid IS NOT NULL", withArgs: nil) {
                err = error
            }
        }
    }

    public func wipeTabs() -> Deferred<Maybe<()>> {
        return self.doWipe { (conn, inout err: NSError?) -> () in
            self.tabs.delete(conn, item: nil, err: &err)
        }
    }

    public func insertOrUpdateTabs(tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return self.insertOrUpdateTabsForClientGUID(nil, tabs: tabs)
    }

    public func insertOrUpdateTabsForClientGUID(clientGUID: String?, tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        let deferred = Deferred<Maybe<Int>>(defaultQueue: dispatch_get_main_queue())

        let deleteQuery = "DELETE FROM \(self.tabs.name) WHERE client_guid IS ?"
        let deleteArgs: [AnyObject?] = [clientGUID]

        var err: NSError?

        db.transaction(&err) { connection, _ in
            // Delete any existing tabs.
            if let _ = connection.executeChange(deleteQuery, withArgs: deleteArgs) {
                log.warning("Deleting existing tabs failed.")
                deferred.fill(Maybe(failure: DatabaseError(err: err)))
                return false
            }

            // Insert replacement tabs.
            var inserted = 0
            var err: NSError?
            for tab in tabs {
                // We trust that each tab's clientGUID matches the supplied client!
                // Really tabs shouldn't have a GUID at all. Future cleanup!
                if self.tabs.insert(connection, item: tab, err: &err) > 0 {
                    ++inserted
                } else {
                    if let err = err {
                        log.warning("Got error \(err).")
                        deferred.fill(Maybe(failure: DatabaseError(err: err)))
                        return false
                    }
                    log.debug("Didn't insert tab!")
                }
            }

            deferred.fill(Maybe(success: inserted))
            return true
        }

        return deferred
    }

    public func insertOrUpdateClients(clients: [RemoteClient]) -> Deferred<Maybe<()>> {
        let deferred = Deferred<Maybe<()>>(defaultQueue: dispatch_get_main_queue())

        var err: NSError?

        // TODO: insert multiple clients in a single query.
        // ORM systems are foolish.
        db.transaction(&err) { connection, _ in
            // Update or insert client records.
            for client in clients {

                let updated = self.clients.update(connection, item: client, err: &err)
                if err == nil && updated == 0 {
                    self.clients.insert(connection, item: client, err: &err)
                }

                if let err = err {
                    let databaseError = DatabaseError(err: err)
                    log.warning("insertOrUpdateClients failed: \(databaseError)")
                    deferred.fill(Maybe(failure: databaseError))
                    return false
                }
            }

            deferred.fill(Maybe(success: ()))
            return true
        }

        return deferred
    }

    public func insertOrUpdateClient(client: RemoteClient) -> Deferred<Maybe<()>> {
        return insertOrUpdateClients([client])
    }

    public func getClients() -> Deferred<Maybe<[RemoteClient]>> {
        var err: NSError?

        do {
            let clientCursor = try db.withReadableConnection(&err) { connection, _ in
                return self.clients.query(connection, options: nil)
            }

            if let err = err {
                clientCursor.close()
                throw err
            }
            let clients = clientCursor.asArray()
            clientCursor.close()
            return deferMaybe(clients)
        } catch let error as NSError {
            log.error(error.localizedDescription)
            err = error
        }
        return deferMaybe(DatabaseError(err: err))
    }

    public func getClientGUIDs() -> Deferred<Maybe<Set<GUID>>> {
        let c = db.runQuery("SELECT guid FROM \(TableClients) WHERE guid IS NOT NULL", args: nil, factory: { $0["guid"] as! String })
        return c >>== { cursor in
            let guids = Set<GUID>(cursor.asArray())
            return deferMaybe(guids)
        }
    }

    public func getTabsForClientWithGUID(guid: GUID?) -> Deferred<Maybe<[RemoteTab]>> {
        let tabsSQL: String
        let clientArgs: Args?
        if let _ = guid {
            tabsSQL = "SELECT * FROM \(TableTabs) WHERE client_guid = ?"
            clientArgs = [guid]
        } else {
            tabsSQL = "SELECT * FROM \(TableTabs) WHERE client_guid IS NULL"
            clientArgs = nil
        }

        log.debug("Looking for tabs for client with guid: \(guid)")
        return db.runQuery(tabsSQL, args: clientArgs, factory: tabs.factory!) >>== {
            let tabs = $0.asArray()
            log.debug("Found \(tabs.count) tabs for client with guid: \(guid)")
            return deferMaybe(tabs)
        }
    }

    public func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        var err: NSError?

        do {
            // Now find the clients.
            let clientCursor = try db.withReadableConnection(&err) { connection, _ in
                return self.clients.query(connection, options: nil)
            }

            if let err = err {
                clientCursor.close()
                throw err
            }

            let clients = clientCursor.asArray()
            clientCursor.close()

            log.debug("Found \(clients.count) clients in the DB.")

            let tabCursor = try db.withReadableConnection(&err) { connection, _ in
                return self.tabs.query(connection, options: nil)
            }

            log.debug("Found \(tabCursor.count) raw tabs in the DB.")

            if let err = err {
                tabCursor.close()
                throw err
            }

            let deferred = Deferred<Maybe<[ClientAndTabs]>>(defaultQueue: dispatch_get_main_queue())

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
        } catch let error as NSError {
            log.error(error.localizedDescription)
            err = error
        }
        return deferMaybe(DatabaseError(err: err))
    }

    public func deleteCommands() -> Success {
        var err: NSError?
        db.transaction(&err) { connection, _ in
            self.commands.delete(connection, item: nil, err: &err)
            if let _ = err {
                return false
            }
            return true
        }

        return failOrSucceed(err, op: "deleteCommands")
    }

    public func deleteCommands(clientGUID: GUID) -> Success {
        var err: NSError?
        db.transaction(&err) { connection, _ in
            self.commands.delete(connection, item: SyncCommand(id: nil, value: "", clientGUID: clientGUID), err: &err)
            if let _ = err {
                return false
            }
            return true
        }

        return failOrSucceed(err, op: "deleteCommands")
    }

    public func insertCommand(command: SyncCommand, forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        return insertCommands([command], forClients: clients)
    }

    public func insertCommands(commands: [SyncCommand], forClients clients: [RemoteClient]) -> Deferred<Maybe<Int>> {
        var err: NSError?
        var numberOfInserts = 0
        db.transaction(&err) { connection, _ in
            // Update or insert client records.
            for command in commands {
                for client in clients {
                    if let commandID = self.commands.insert(connection, item: command.withClientGUID(client.guid), err: &err) {
                        log.verbose("Inserted command: \(commandID)")
                        ++numberOfInserts
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

    public func getCommands() -> Deferred<Maybe<[GUID: [SyncCommand]]>> {
        var err: NSError?

        do {
            // Now find the clients.
            let commandCursor = try db.withReadableConnection(&err) { connection, _ in
                return self.commands.query(connection, options: nil)
            }

            if let err = err {
                commandCursor.close()
                throw err
            }

            let allCommands = commandCursor.asArray()
            commandCursor.close()

            let clientSyncCommands = clientsFromCommands(allCommands)

            log.debug("Found \(clientSyncCommands.count) client sync commands in the DB.")
            return failOrSucceed(err, op: "get commands", val: clientSyncCommands)
        }  catch let error as NSError {
            log.error(error.localizedDescription)
            err = error
        }
        return failOrSucceed(err, op: "getCommands", val: [GUID: [SyncCommand]]())
    }

    func clientsFromCommands(commands: [SyncCommand]) -> [GUID: [SyncCommand]] {
        var syncCommands = [GUID: [SyncCommand]]()
        for command in commands {
            var cmds: [SyncCommand] = syncCommands[command.clientGUID!] ?? [SyncCommand]()
            cmds.append(command)
            syncCommands[command.clientGUID!] = cmds
        }
        return syncCommands
    }
}

extension SQLiteRemoteClientsAndTabs: ResettableSyncStorage {
    public func resetClient() -> Success {
        // For this engine, resetting is equivalent to wiping.
        return self.clear()
    }

    public func clear() -> Success {
        return self.doWipe { (conn, inout err: NSError?) -> () in
            self.tabs.delete(conn, item: nil, err: &err)
            self.clients.delete(conn, item: nil, err: &err)
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