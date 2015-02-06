/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum QuerySort {
    case None, LastVisit, Frecency
}

public enum FilterType {
    case None
}

public class QueryOptions {
    // A filter string to apploy to the query
    public var filter: AnyObject? = nil

    // Allows for customizing how the filter is applied (i.e. only urls or urls and titles?)
    public var filterType: FilterType = .None

    // The way to sort the query
    public var sort: QuerySort = .None

    public init(filter: String? = nil, filterType: FilterType = .None, sort: QuerySort = .None) {
        self.filter = filter
        self.filterType = filterType
        self.sort = sort
    }
}

/* A table in our database. Note this doesn't have to be a real table. It might be backed by a join or something else interesting. */
protocol Table {
    typealias Type
    var name: String { get }

    func exists(db: SQLiteDBConnection) -> Bool
    func drop(db: SQLiteDBConnection) -> Bool
    func create(db: SQLiteDBConnection, version: Int) -> Bool
    func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool

    func insert(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int
    func update(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int
    func delete(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int
    func query(db: SQLiteDBConnection, options: QueryOptions?) -> Cursor
}

let DBCouldNotOpenErrorCode = 200

/* This is a base interface into our browser db. It holds arrays of tables and handles basic creation/updating of them. */
// Version 1 - Basic history table
// Version 2 - Added a visits table, refactored the history table to be a GenericTable
// Version 3 - Added a favicons table
class BrowserDB {
    private let db: SwiftData
    // XXX: Increasing this should blow away old history, since we currently dont' support any upgrades
    private let Version: Int = 4
    private let FileName = "browser.db"
    private let files: FileAccessor

    private var initialized = [String]()

    init?(files: FileAccessor) {
        self.files = files
        db = SwiftData(filename: files.get(FileName)!)
    }

    func create<T: Table>(table: T) -> Bool {
        var success = true
        db.transaction({ connection -> Bool in
            if !table.exists(connection) {
                if !table.create(connection, version: self.Version) {
                    println("Creating \(table.name) failed")
                    success = false
                }
            } else {
                let version = connection.version
                if version != self.Version {
                    // TODO: Support table upgrades.
                    // table.updateTable(connection, from: version, to: self.Version)
                    println("Table upgrades aren't supported yet")
                    success = false
                    connection.version = self.Version
                }
            }

            // If the creation or ugrade failed, drop the table and try creating it.
            if !success {
                println("Dropping and recreating table \(table.name)")
                table.drop(connection)
                success = table.create(connection, version: self.Version)
            }

            // If the creation failed again, delete the file and try creating this again. This isn't
            // particularly safe, but at least we should start on next run....
            if !success {
                println("Deleting db file")
                self.files.move(self.FileName, dest: "\(self.FileName).bak")
                success = table.create(connection, version: self.Version)
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

    private let debug_enabled = true
    private func debug(err: NSError) {
        debug("\(err.code): \(err.localizedDescription)")
    }

    private func debug(msg: String) {
        if debug_enabled {
            println("BrowserDB: " + msg)
        }
    }
}
