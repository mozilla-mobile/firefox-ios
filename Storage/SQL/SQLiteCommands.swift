//
//  SQLiteCommands.swift
//  Client
//
//  Created by Emily Toop on 6/29/15.
//  Copyright (c) 2015 Mozilla. All rights reserved.
//

import Foundation
import Shared
import XCGLogger

private let log = XCGLogger.defaultInstance()

public class SQLiteCommands: SyncCommands {
    let db: BrowserDB
    let commands = CommandSyncTable<SyncCommand>()

    public init(db: BrowserDB) {
        self.db = db
        db.createOrUpdate(commands)
    }

    // wipe all unsynced commands
    public func wipeCommands() -> Deferred<Result<()>> {
        let deferred = Deferred<Result<()>>(defaultQueue: dispatch_get_main_queue())

        var err: NSError?
        db.transaction(&err) { connection, _ in
            self.commands.delete(connection, item: nil, err: &err)
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

    // wipe unsynced commands for a client
    public func wipeCommandsForClient(client: RemoteClient) -> Deferred<Result<()>> {
        let deferred = Deferred<Result<()>>(defaultQueue: dispatch_get_main_queue())
        var err: NSError?
        db.transaction(&err) { connection, _ in
            self.getCommandsForClient(client).upon({ result in
                if let clientCommands = result.successValue {
                    for command in clientCommands {
                        self.commands.delete(connection, item: command, err: &err)
                    }
                }
            })
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

    // insert a single command
    public func insertCommand(command: SyncCommand) -> Deferred<Result<Int>> {
        return self.insertCommands([command])
    }

    // insert a batch of commands
    public func insertCommands(commands: [SyncCommand]) -> Deferred<Result<Int>> {
        let deferred = Deferred<Result<Int>>(defaultQueue: dispatch_get_main_queue())

        var err: NSError?

        db.transaction(&err) { connection, _ in
            var inserted = 0
            var err: NSError?
            for command in commands {
                // We trust that each tab's clientGUID matches the supplied client!
                // Really tabs shouldn't have a GUID at all. Future cleanup!
                self.commands.insert(connection, item: command, err: &err)
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

    // get all unsynced commands
    public func getCommands() -> Deferred<Result<[SyncCommand]>> {
        var err: NSError?

        let commandCursor = db.withReadableConnection(&err) { connection, _ in
            return self.commands.query(connection, options: nil)
        }

        if let err = err {
            commandCursor.close()
            return Deferred(value: Result(failure: DatabaseError(err: err)))
        }

        let commands = commandCursor.asArray()
        commandCursor.close()

        return Deferred(value: Result(success: commands))
    }

    // get all unsyced commands for a client
    public func getCommandsForClient(client: RemoteClient) -> Deferred<Result<[SyncCommand]>> {
        var err: NSError?


        let opts = QueryOptions()
        opts.filter = client.guid
        opts.filterType = FilterType.Guid
        let commandCursor = db.withReadableConnection(&err) { connection, _ in
            return self.commands.query(connection, options: opts)
        }

        if let err = err {
            commandCursor.close()
            return Deferred(value: Result(failure: DatabaseError(err: err)))
        }

        let commands = commandCursor.asArray()
        commandCursor.close()

        return Deferred(value: Result(success: commands))
    }

    // we do something here when accounts are removed
    public func onRemovedAccount() -> Success {
        log.info("Clearing commands after account removal.")
        // TODO: Bug 1168690 - delete our client and tabs records from the server.
        return self.wipeCommands()
    }
}
