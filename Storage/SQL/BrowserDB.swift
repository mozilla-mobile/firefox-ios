/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger
import Shared

private let log = XCGLogger.defaultInstance()

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
// Version 1 - Basic history table.
// Version 2 - Added a visits table, refactored the history table to be a GenericTable.
// Version 3 - Added a favicons table.
// Version 4 - Added a readinglist table.
// Version 5 - Added the clients and the tabs tables.
// Version 6 - Visit timestamps are now microseconds.
// Version 7 - Eliminate most tables.
public class BrowserDB {
    private let db: SwiftData
    // XXX: Increasing this should blow away old history, since we currently don't support any upgrades.
    private let Version: Int = 7
    private let FileName = "browser.db"
    private let files: FileAccessor
    private let schemaTable: SchemaTable<TableInfo>

    private var initialized = [String]()

    // SQLITE_MAX_VARIABLE_NUMBER = 999 by default. This controls how many ?s can
    // appear in a query string.
    static let MaxVariableNumber = 999

    public init(files: FileAccessor) {
        log.debug("Initializing BrowserDB.")
        self.files = files
        db = SwiftData(filename: files.getAndEnsureDirectory()!.stringByAppendingPathComponent(FileName))
        self.schemaTable = SchemaTable()
        self.createOrUpdate(self.schemaTable)
    }

    var filename: String {
        return db.filename
    }

    // Creates a table and writes its table info into the table-table database.
    private func createTable<T: Table>(db: SQLiteDBConnection, table: T) -> Bool {
        log.debug("Try create \(table.name) version \(table.version)")
        if !table.create(db, version: table.version) {
            // If creating failed, we'll bail without storing the table info
            log.debug("Creation failed.")
            return false
        }

        var err: NSError? = nil
        return schemaTable.insert(db, item: table, err: &err) > -1
    }

    // Updates a table and writes its table into the table-table database.
    private func updateTable<T: Table>(db: SQLiteDBConnection, table: T) -> Bool {
        log.debug("Trying update \(table.name) version \(table.version)")
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
            // If the update failed, we'll bail without writing the change to the table-table.
            log.debug("Updating failed.")
            return false
        }

        var err: NSError? = nil

        // Yes, we UPDATE OR INSERT… because we might be transferring ownership of a database table
        // to a different Table. It'll trigger exists, and thus take the update path, but we won't
        // necessarily have an existing schema entry -- i.e., we'll be updating from 0.
        return schemaTable.update(db, item: table, err: &err) > 0 ||
               schemaTable.insert(db, item: table, err: &err) > 0
    }

    // Utility for table classes. They should call this when they're initialized to force
    // creation of the table in the database.
    func createOrUpdate<T: Table>(table: T) -> Bool {
        log.debug("Create or update \(table.name) version \(table.version).")
        var success = true
        db.transaction({ connection -> Bool in
            // If the table doesn't exist, we'll create it
            if !table.exists(connection) {
                success = self.createTable(connection, table: table)
            } else {
                // Otherwise, we'll update it
                success = self.updateTable(connection, table: table)
                if !success {
                    log.error("Update failed for \(table.name). Dropping and recreating.")

                    table.drop(connection)
                    var err: NSError? = nil
                    self.schemaTable.delete(connection, item: table, err: &err)

                    success = self.createTable(connection, table: table)
                }
            }

            // If we failed, move the file and try again. This will probably break things that are already
            // attached and expecting a working DB, but at least we should be able to restart.
            if !success {
                log.debug("Couldn't create or update \(table.name).")
                log.debug("Attempting to move \(self.FileName) to another location.")

                // Note that a backup file might already exist! We append a counter to avoid this.
                var bakCounter = 0
                var bak: String
                do {
                    bak = "\(self.FileName).bak.\(++bakCounter)"
                } while self.files.exists(bak)

                success = self.files.move(self.FileName, toRelativePath: bak)
                assert(success)
                success = self.createTable(connection, table: table)
            }
            return success
        })

        return success
    }

    typealias IntCallback = (connection: SQLiteDBConnection, inout err: NSError?) -> Int

    func withConnection<T>(#flags: SwiftData.Flags, inout err: NSError?, callback: (connection: SQLiteDBConnection, inout err: NSError?) -> T) -> T {
        var res: T!
        db.withConnection(flags) { connection in
            var err: NSError? = nil
            res = callback(connection: connection, err: &err)
            return err
        }
        return res
    }

    func withWritableConnection<T>(inout err: NSError?, callback: (connection: SQLiteDBConnection, inout err: NSError?) -> T) -> T {
        return withConnection(flags: SwiftData.Flags.ReadWrite, err: &err, callback: callback)
    }

    func withReadableConnection<T>(inout err: NSError?, callback: (connection: SQLiteDBConnection, inout err: NSError?) -> Cursor<T>) -> Cursor<T> {
        return withConnection(flags: SwiftData.Flags.ReadOnly, err: &err, callback: callback)
    }

    func transaction(inout err: NSError?, callback: (connection: SQLiteDBConnection, inout err: NSError?) -> Bool) {
        db.transaction { connection in
            var err: NSError? = nil
            return callback(connection: connection, err: &err)
        }
    }
}

extension BrowserDB {
    public class func varlist(count: Int) -> String {
        return "(" + ", ".join(Array(count: count, repeatedValue: "?")) + ")"
    }

    enum InsertOperation: String {
        case Insert = "INSERT"
        case Replace = "REPLACE"
        case InsertOrIgnore = "INSERT OR IGNORE"
        case InsertOrReplace = "INSERT OR REPLACE"
        case InsertOrRollback = "INSERT OR ROLLBACK"
        case InsertOrAbort = "INSERT OR ABORT"
        case InsertOrFail = "INSERT OR FAIL"
    }

    /**
     * Insert multiple sets of values into the given table.
     *
     * Assumptions:
     * 1. The table exists and contains the provided columns.
     * 2. Every item in `values` is the same length.
     * 3. That length is the same as the length of `columns`.
     * 4. Every value in each element of `values` is non-nil.
     *
     * If there are too many items to insert, multiple individual queries will run
     * in sequence.
     *
     * A failure anywhere in the sequence will cause immediate return of failure, but
     * will not roll back — use a transaction if you need one.
     */
    func bulkInsert(table: String, op: InsertOperation, columns: [String], values: [Args]) -> Success {
        // Note that there's a limit to how many ?s can be in a single query!
        // So here we execute 999 / (columns * rows) insertions per query.
        // Note that we can't use variables for the column names, so those don't affect the count.
        if values.isEmpty {
            log.debug("No values to insert.")
            return succeed()
        }

        let variablesPerRow = columns.count

        // Sanity check.
        assert(values[0].count == variablesPerRow)

        let cols = ", ".join(columns)
        let queryStart = "\(op) INTO \(table) (\(cols)) VALUES "

        let varString = BrowserDB.varlist(variablesPerRow)

        let insertChunk: [Args] -> Success = { vals -> Success in
            let valuesString = ", ".join(Array(count: vals.count, repeatedValue: varString))
            let args: Args = vals.flatMap { $0 }
            return self.run(queryStart + valuesString, withArgs: args)
        }

        let rowCount = values.count
        if (variablesPerRow * rowCount) < BrowserDB.MaxVariableNumber {
            return insertChunk(values)
        }

        log.debug("Splitting bulk insert across multiple runs. I hope you started a transaction!")
        let rowsPerInsert = (999 / variablesPerRow)
        let chunks = chunk(values, by: rowsPerInsert)
        log.debug("Inserting in \(chunks.count) chunks.")

        // There's no real reason why we can't pass the ArraySlice here, except that I don't
        // want to keep fighting Swift.
        return walk(chunks, { insertChunk(Array($0)) })
    }

    func run(sql: String, withArgs args: Args) -> Success {
        var err: NSError?
        return self.withWritableConnection(&err) { (conn, inout err: NSError?) -> Success in
            err = conn.executeChange(sql, withArgs: args)
            if err == nil {
                log.debug("Modified rows: \(conn.numberOfRowsModified).")
                return succeed()
            }
            return deferResult(DatabaseError(err: err))
        }
    }

    func runQuery<T>(sql: String, args: Args?, factory: SDRow -> T) -> Deferred<Result<Cursor<T>>> {
        func f(conn: SQLiteDBConnection, inout err: NSError?) -> Cursor<T> {
            return conn.executeQuery(sql, factory: factory, withArgs: args)
        }

        var err: NSError? = nil
        let cursor = self.withReadableConnection(&err, callback: f)

        return deferResult(cursor)
    }
}