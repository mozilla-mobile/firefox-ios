/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum QuerySort {
    case None, LastVisit, Frecency
}

public enum FilterType {
    case ExactUrl
    case Url
    case Guid
    case Id
    case None
}

public class QueryOptions {
    // A filter string to apploy to the query
    public var filter: AnyObject? = nil

    // Allows for customizing how the filter is applied (i.e. only urls or urls and titles?)
    public var filterType: FilterType = .None

    // The way to sort the query
    public var sort: QuerySort = .None

    public init(filter: AnyObject? = nil, filterType: FilterType = .None, sort: QuerySort = .None) {
        self.filter = filter
        self.filterType = filterType
        self.sort = sort
    }
}

let DBCouldNotOpenErrorCode = 200

/* This is a base interface into our browser db. It holds arrays of tables and handles basic creation/updating of them. */
// Version 1 - Basic history table
// Version 2 - Added a visits table, refactored the history table to be a GenericTable
// Version 3 - Added a favicons table
// Version 4 - Added a readinglist table
// Version 5 - Added the clients and the tabs tables.
class BrowserDB {
    private let db: SwiftData
    // XXX: Increasing this should blow away old history, since we currently dont' support any upgrades
    private let Version: Int = 5
    private let FileName = "browser.db"
    private let files: FileAccessor
    private let schemaTable: SchemaTable<TableInfo>

    private var initialized = [String]()

    init?(files: FileAccessor) {
        self.files = files
        db = SwiftData(filename: files.getAndEnsureDirectory()!.stringByAppendingPathComponent(FileName))
        self.schemaTable = SchemaTable()
        self.createOrUpdate(self.schemaTable)
    }

    var filename: String {
        return db.filename
    }

    // Creates a table and writes its table info the the table-table database.
    private func createTable<T:Table>(db: SQLiteDBConnection, table: T) -> Bool {
        debug("Try create \(table.name) version \(table.version)")
        if !table.create(db, version: table.version) {
            // If creating failed, we'll bail without storing the table info
            return false
        }

        var err: NSError? = nil
        return schemaTable.insert(db, item: table, err: &err) > -1
    }

    // Updates a table and writes its table into the table-table database.
    private func updateTable<T: Table>(db: SQLiteDBConnection, table: T) -> Bool {
        debug("Try update \(table.name) version \(table.version)")
        var from = 0
        // Try to find the stored version of the table
        let cursor = schemaTable.query(db, options: QueryOptions(filter: table.name))
        if cursor.count > 0 {
            if let info = cursor[0] as? TableInfoWrapper {
                from = info.version
            }
        }

        // If the versions match, no need to update
        if from == table.version {
            return true
        }

        if !table.updateTable(db, from: from, to: table.version) {
            // If the update failed, we'll bail without writing the change to the table-table
            return false
        }

        var err: NSError? = nil
        return schemaTable.update(db, item: table, err: &err) > 0
    }

    // Utility for table classes. They should call then when they're initialized to force
    // creation of the table in the database
    func createOrUpdate<T: Table>(table: T) -> Bool {
        debug("Create or update \(table.name) version \(table.version)")
        var success = true
        db.transaction({ connection -> Bool in
            // If the table doesn't exist, we'll create it
            if !table.exists(connection) {
                success = self.createTable(connection, table: table)
            } else {
                // Otherwise, we'll update it
                success = self.updateTable(connection, table: table)
                if !success {
                    println("Update failed for \(table.name). Dropping and recreating")

                    table.drop(connection)
                    var err: NSError? = nil
                    self.schemaTable.delete(connection, item: table, err: &err)

                    success = self.createTable(connection, table: table)
                }
            }

            // If we failed, move the file and try again. This will probably break things that are already
            // attached and expecting a working DB, but at least we should be able to restart
            if !success {
                println("Couldn't create or update \(table.name)")
                success = self.files.move(self.FileName, toRelativePath: "\(self.FileName).bak")
                assert(success)
                success = self.createTable(connection, table: table)
            }
            return success
        })

        return success
    }

    typealias CursorCallback = (connection: SQLiteDBConnection, inout err: NSError?) -> Cursor
    typealias IntCallback = (connection: SQLiteDBConnection, inout err: NSError?) -> Int

    func insert(inout err: NSError?, callback: IntCallback) -> Int {
        var res = 0
        db.withConnection(SwiftData.Flags.ReadWrite) { connection in
            var err: NSError? = nil
            res = callback(connection: connection, err: &err)
            return err
        }
        return res
    }

    func update(inout err: NSError?, callback: IntCallback) -> Int {
        var res = 0
        db.withConnection(SwiftData.Flags.ReadWrite) { connection in
            var err: NSError? = nil
            res = callback(connection: connection, err: &err)
            return err
        }
        return res
    }

    func delete(inout err: NSError?, callback: IntCallback) -> Int {
        var res = 0
        db.withConnection(SwiftData.Flags.ReadWrite) { connection in
            var err: NSError? = nil
            res = callback(connection: connection, err: &err)
            return err
        }
        return res
    }

    func query(inout err: NSError?, callback: CursorCallback) -> Cursor {
        var c: Cursor!
        db.withConnection(SwiftData.Flags.ReadOnly) { connection in
            var err: NSError? = nil
            c = callback(connection: connection, err: &err)
            return err
        }
        return c
    }

    func transaction(inout err: NSError?, callback: (connection: SQLiteDBConnection, inout err: NSError?) -> Bool) {
        db.transaction { connection in
            var err: NSError? = nil
            return callback(connection: connection, err: &err)
        }
    }

    private let debug_enabled = false
    private func debug(err: NSError) {
        debug("\(err.code): \(err.localizedDescription)")
    }

    private func debug(msg: String) {
        if debug_enabled {
            println("BrowserDB: " + msg)
        }
    }
}
