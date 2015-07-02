/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = XCGLogger.defaultInstance()

public class SQLiteCommands: SyncCommands {
    let db: BrowserDB
    let commands = SyncCommandsTable()

    public init(db: BrowserDB) {
        self.db = db
        db.createOrUpdate(commands)
    }

    private class func factory(row: SDRow) -> SyncCommand {
        let id = row["id"] as! Int
        let value = row["value"] as! String
        return SyncCommand(id: id, value: value)
    }

    // wipe all unsynced commands
    public func deleteCommands() -> Deferred<Result<()>> {
        let deleteClientsCommands = "DELETE FROM \(TableClientSyncCommands)"
        let deleteCommands = "DELETE FROM \(TableSyncCommands) WHERE id NOT IN (SELECT command_id FROM \(TableClientSyncCommands)"

        return self.db.run(deleteClientsCommands, withArgs: nil) >>> { self.db.run(deleteCommands, withArgs: nil) }
    }

    // wipe unsynced commands for a client
    public func deleteCommandsForClient(client: RemoteClient) -> Deferred<Result<()>> {
        let deleteArgs: Args = [client.guid]
        let deleteClientsCommands = "DELETE FROM \(TableClientSyncCommands) WHERE client_guid = ?"
        let deleteCommands = "DELETE FROM \(TableSyncCommands) WHERE id NOT IN (SELECT command_id FROM \(TableClientSyncCommands)"

        return self.db.run(deleteClientsCommands, withArgs: deleteArgs) >>> { self.db.run(deleteCommands, withArgs: deleteArgs) }
    }

    // wipe unsynced commands for a client
    public func deleteCommand(command: SyncCommand) -> Deferred<Result<()>> {
        let deleteArgs: Args
        var deleteCommand: String
        if let cmdID = command.commandID {
            deleteArgs = [cmdID]
            deleteCommand = "DELETE FROM \(TableClientSyncCommands) WHERE command_id = ? "
        } else {
            deleteArgs = [command.value]
            deleteCommand = "DELETE FROM \(TableClientSyncCommands) WHERE command_id IN (SELECT id FROM \(TableSyncCommands) WHERE value = ?)"
        }

        return self.db.run(deleteCommand, withArgs: deleteArgs)
    }

    // insert a single command
    public func insertCommand(command: SyncCommand, forClients clients: [RemoteClient]) -> Deferred<Result<Int>> {
        return self.insertCommands([command], forClients: clients)
    }

    func idForCommand(command: SyncCommand, connection: SQLiteDBConnection) -> Int? {
        let deferred = Deferred<Result<Int>>(defaultQueue: dispatch_get_main_queue())
        var error: NSError? = nil
        var commandID = command.commandID
        if commandID == nil {
            func getOrCreateCommand(command: SyncCommand) -> Int? {
                // check to see if there are any other commands currently in the DB that match this one exactly
                let select = "SELECT * FROM \(TableSyncCommands) WHERE value = ?"
                let selectArgs: Args = [command.value]
                let commandCursor = connection.executeQuery(select, factory: IntFactory, withArgs: selectArgs)

                if commandCursor.status == CursorStatus.Failure {
                    commandCursor.close()
                    log.warning("select sync command failed with \(commandCursor.statusMessage)")
                    return nil
                }

                if commandCursor.count > 0{
                    return commandCursor[0]
                } else {
                    let insert = "INSERT INTO \(TableSyncCommands) (value) VALUES (" +
                    "?)"
                    let insertArgs: Args? = [command.value]
                    error = connection.executeChange(insert, withArgs: insertArgs)
                    if let err = error {
                        log.warning("Insert sync command failed with \(err.localizedDescription)")
                        return nil
                    }
                    return connection.lastInsertedRowID
                }
            }
            commandID = getOrCreateCommand(command)
        }
        return commandID
    }

    // insert a batch of commands
    public func insertCommands(commands: [SyncCommand], forClients clients: [RemoteClient]) -> Deferred<Result<Int>> {
        var deferred = Deferred<Result<Int>>(defaultQueue: dispatch_get_main_queue())
        var error: NSError? = nil
        self.db.transaction(&error) { connection, _ in
            var success = true
            var numberOfInsertedRows = 0
            for command in commands {
                // get the id for the command
                if let commandID = self.idForCommand(command, connection: connection) {
                    // link the command with the right clients
                    var err: NSError? = nil
                    let insert = "INSERT INTO \(TableClientSyncCommands) (client_guid, command_id) values (?, \(commandID))"
                    for client in clients {
                        let insertArgs: Args = [client.guid]
                        err = connection.executeChange(insert, withArgs: insertArgs)
                        if let insertError = err {
                            log.warning("Insert client commands failed with \(err?.localizedDescription)")
                            success = false
                            error = insertError
                        }
                        else {
                            numberOfInsertedRows += connection.numberOfRowsModified
                        }
                    }
                }
                if !success {
                    break
                }
            }
            error != nil ? deferred.fill(Result(failure: DatabaseError(err: error))) : deferred.fill(Result(success: numberOfInsertedRows))
            return success
        }

        return deferred
    }

    // get all unsynced commands
    public func getCommands() -> Deferred<Result<[SyncCommand]>> {
        var err: NSError?

        let commandCursor = db.withReadableConnection(&err) { (connection, err) -> Cursor<SyncCommand> in
            let select = "SELECT * FROM \(TableSyncCommands)"
            return connection.executeQuery(select, factory: SQLiteCommands.factory, withArgs: nil)
        }

        if let err = err {
            commandCursor.close()
            return deferResult(DatabaseError(err: err))
        }

        let commands = commandCursor.asArray()
        commandCursor.close()

        return deferResult(commands)
    }

    // get all unsyced commands for a client
    public func getCommandsForClient(client: RemoteClient) -> Deferred<Result<[SyncCommand]>> {
        var err: NSError?

        let commandCursor = db.withReadableConnection(&err) { (connection, err) -> Cursor<SyncCommand> in
            let select = "SELECT * FROM \(TableSyncCommands) WHERE id IN (SELECT command_id from \(TableClientSyncCommands) WHERE client_guid = ?)"
            let selectArgs: Args = [client.guid]
            return connection.executeQuery(select, factory: SQLiteCommands.factory, withArgs: selectArgs)
        }

        if commandCursor.status == CursorStatus.Failure {
            commandCursor.close()
            return deferResult(DatabaseError(err: err))
        }

        let commands = commandCursor.asArray()
        commandCursor.close()

        return deferResult(commands)
    }

    // we do something here when accounts are removed
    public func onRemovedAccount() -> Success {
        return self.deleteCommands()
    }
}
