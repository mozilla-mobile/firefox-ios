/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

let TableLoginsMirror = "loginsM"
let TableLoginsLocal = "loginsL"
let IndexLoginsOverrideHostname = "idx_loginsM_is_overridden_hostname"
let IndexLoginsDeletedHostname = "idx_loginsL_is_deleted_hostname"

private let AllTables: [String] = [
    TableLoginsMirror,
    TableLoginsLocal
]

private let log = Logger.syncLogger

open class LoginsSchema: Schema {
    static let DefaultVersion = 3
    
    public var name: String { return "LOGINS" }
    public var version: Int { return LoginsSchema.DefaultVersion }

    public init() {}

    func run(_ db: SQLiteDBConnection, sql: String, args: Args? = nil) -> Bool {
        do {
            try db.executeChange(sql, withArgs: args)
        } catch let err as NSError {
            log.error("Error running SQL in LoginsSchema: \(err.localizedDescription)")
            log.error("SQL was \(sql)")
            return false
        }

        return true
    }
    
    // TODO: transaction.
    func run(_ db: SQLiteDBConnection, queries: [String]) -> Bool {
        for sql in queries {
            if !run(db, sql: sql, args: nil) {
                return false
            }
        }
        return true
    }
    
    let indexIsOverriddenHostname =
    "CREATE INDEX IF NOT EXISTS \(IndexLoginsOverrideHostname) ON \(TableLoginsMirror) (is_overridden, hostname)"
    
    let indexIsDeletedHostname =
    "CREATE INDEX IF NOT EXISTS \(IndexLoginsDeletedHostname) ON \(TableLoginsLocal) (is_deleted, hostname)"
    
    public func create(_ db: SQLiteDBConnection) -> Bool {
        let common =
            "id INTEGER PRIMARY KEY AUTOINCREMENT" +
                ", hostname TEXT NOT NULL" +
                ", httpRealm TEXT" +
                ", formSubmitURL TEXT" +
                ", usernameField TEXT" +
                ", passwordField TEXT" +
                ", timesUsed INTEGER NOT NULL DEFAULT 0" +
                ", timeCreated INTEGER NOT NULL" +
                ", timeLastUsed INTEGER" +
                ", timePasswordChanged INTEGER NOT NULL" +
                ", username TEXT" +
        ", password TEXT NOT NULL"
        
        let mirror = "CREATE TABLE IF NOT EXISTS \(TableLoginsMirror) (" +
            common +
            ", guid TEXT NOT NULL UNIQUE" +
            ", server_modified INTEGER NOT NULL" +              // Integer milliseconds.
            ", is_overridden TINYINT NOT NULL DEFAULT 0" +
        ")"
        
        let local = "CREATE TABLE IF NOT EXISTS \(TableLoginsLocal) (" +
            common +
            ", guid TEXT NOT NULL UNIQUE " +                  // Typically overlaps one in the mirror unless locally new.
            ", local_modified INTEGER" +                      // Can be null. Client clock. In extremis only.
            ", is_deleted TINYINT NOT NULL DEFAULT 0" +       // Boolean. Locally deleted.
            ", sync_status TINYINT " +                        // SyncStatus enum. Set when changed or created.
            "NOT NULL DEFAULT \(SyncStatus.synced.rawValue)" +
        ")"
        return self.run(db, queries: [mirror, local, indexIsOverriddenHostname, indexIsDeletedHostname])
    }
    
    public func update(_ db: SQLiteDBConnection, from: Int) -> Bool {
        let to = self.version
        if from == to {
            log.debug("Skipping update from \(from) to \(to).")
            return true
        }
        
        if from == 0 {
            // This is likely an upgrade from before Bug 1160399.
            log.debug("Updating logins tables from zero. Assuming drop and recreate.")
            return drop(db) && create(db)
        }
        
        if from < 3 && to >= 3 {
            log.debug("Updating logins tables to include version 3 indices")
            return self.run(db, queries: [indexIsOverriddenHostname, indexIsDeletedHostname])
        }
        
        // TODO: real update!
        log.debug("Updating logins table from \(from) to \(to).")
        return drop(db) && create(db)
    }
    
    public func drop(_ db: SQLiteDBConnection) -> Bool {
        log.debug("Dropping logins table.")
        do {
            try db.executeChange("DROP TABLE IF EXISTS \(name)")
        } catch {
            return false
        }

        return true
    }
}
