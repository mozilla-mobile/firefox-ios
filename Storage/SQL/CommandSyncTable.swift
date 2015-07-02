//
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import XCGLogger


let TableSyncCommands = "commands"
let TableClientSyncCommands = "clientcommands"
let TableClient = "clients"
private let log = XCGLogger.defaultInstance()

public class SyncCommandsTable: Table {
    var name: String { return "CLIENTCOMMANDS" }
    var version: Int { return 1 }
    let sqliteVersion: Int32
    let supportsPartialIndices: Bool

    public init() {
        let v = sqlite3_libversion_number()
        self.sqliteVersion = v
        self.supportsPartialIndices = v >= 3008000          // 3.8.0.
        let ver = String.fromCString(sqlite3_libversion())!
        log.info("SQLite version: \(ver) (\(v)).")
    }

    func run(db: SQLiteDBConnection, sql: String, args: Args? = nil) -> Bool {
        let err = db.executeChange(sql, withArgs: args)
        if err != nil {
            log.error("Error running SQL in ClientCommandsTable. \(err?.localizedDescription)")
            log.error("SQL was \(sql)")
        }
        return err == nil
    }

    // TODO: transaction.
    func run(db: SQLiteDBConnection, queries: [String]) -> Bool {
        for sql in queries {
            if !run(db, sql: sql, args: nil) {
                return false
            }
        }
        return true
    }

    func create(db: SQLiteDBConnection, version: Int) -> Bool {
        // We ignore the version.



        let syncCommands =
        "CREATE TABLE IF NOT EXISTS \(TableSyncCommands) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "value TEXT NOT NULL " +
        ") "

        let clientCommands =
        "CREATE TABLE IF NOT EXISTS \(TableClientSyncCommands) (" +
            "client_guid TEXT NOT NULL REFERENCES \(TableClient)(guid), " +
            "command_id INTEGER NOT NULL REFERENCES \(TableSyncCommands)(id) ON DELETE CASCADE, " +           // Microseconds since epoch.
            "PRIMARY KEY(client_guid, command_id) " +
        ") "

        let queries = [
            syncCommands, clientCommands,
        ]

        log.debug("Creating \(queries.count) tables")
        return self.run(db, queries: queries)
    }

    func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool {

        return true
    }

    /**
    * The Table mechanism expects to be able to check if a 'table' exists. In our (ab)use
    * of Table, that means making sure that any of our tables and views exist.
    * We do that by fetching all tables from sqlite_master with matching names, and verifying
    * that we get back more than one.
    * Note that we don't check for views -- trust to luck.
    */
    func exists(db: SQLiteDBConnection) -> Bool {
        return db.tablesExist([TableClientSyncCommands, TableSyncCommands])
    }

    func drop(db: SQLiteDBConnection) -> Bool {
        log.debug("Dropping all tables.")
        let queries = ["DROP VIEW IF EXISTS \(TableClientSyncCommands)",
            "DROP INDEX IF EXISTS \(TableSyncCommands)"]
        
        return self.run(db, queries: queries)
    }
}