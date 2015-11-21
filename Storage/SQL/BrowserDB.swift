/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger
import Shared

private let log = Logger.syncLogger

typealias Args = [AnyObject?]

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
    private let files: FileAccessor
    private let filename: String
    private let secretKey: String?
    private let schemaTable: SchemaTable

    private var initialized = [String]()

    // SQLITE_MAX_VARIABLE_NUMBER = 999 by default. This controls how many ?s can
    // appear in a query string.
    static let MaxVariableNumber = 999

    public init(filename: String, secretKey: String? = nil, files: FileAccessor) {
        log.debug("Initializing BrowserDB: \(filename).")
        self.files = files
        self.filename = filename
        self.schemaTable = SchemaTable()
        self.secretKey = secretKey

        let file = ((try! files.getAndEnsureDirectory()) as NSString).stringByAppendingPathComponent(filename)
        self.db = SwiftData(filename: file, key: secretKey, prevKey: nil)

        if AppConstants.BuildChannel == .Developer && secretKey != nil {
            log.debug("Creating db: \(file) with secret = \(secretKey)")
        }

        // Create or update will also delete and create the database if our key was incorrect.
        self.createOrUpdate(self.schemaTable)
    }

    // Creates a table and writes its table info into the table-table database.
    private func createTable(conn: SQLiteDBConnection, table: SectionCreator) -> TableResult {
        log.debug("Try create \(table.name) version \(table.version)")
        if !table.create(conn) {
            // If creating failed, we'll bail without storing the table info
            log.debug("Creation failed.")
            return .Failed
        }

        var err: NSError? = nil
        return schemaTable.insert(conn, item: table, err: &err) > -1 ? .Created : .Failed
    }

    // Updates a table and writes its table into the table-table database.
    // Exposed internally for testing.
    func updateTable(conn: SQLiteDBConnection, table: SectionUpdater) -> TableResult {
        log.debug("Trying update \(table.name) version \(table.version)")
        var from = 0
        // Try to find the stored version of the table
        let cursor = schemaTable.query(conn, options: QueryOptions(filter: table.name))
        if cursor.count > 0 {
            if let info = cursor[0] as? TableInfoWrapper {
                from = info.version
            }
        }

        // If the versions match, no need to update
        if from == table.version {
            return .Exists
        }

        if !table.updateTable(conn, from: from) {
            // If the update failed, we'll bail without writing the change to the table-table.
            log.debug("Updating failed.")
            return .Failed
        }

        var err: NSError? = nil

        // Yes, we UPDATE OR INSERT… because we might be transferring ownership of a database table
        // to a different Table. It'll trigger exists, and thus take the update path, but we won't
        // necessarily have an existing schema entry -- i.e., we'll be updating from 0.
        if schemaTable.update(conn, item: table, err: &err) > 0 ||
           schemaTable.insert(conn, item: table, err: &err) > 0 {
            return .Updated
        }
        return .Failed
    }

    // Utility for table classes. They should call this when they're initialized to force
    // creation of the table in the database.
    func createOrUpdate(tables: Table...) -> Bool {
        var success = true
        let doCreate = { (table: Table, connection: SQLiteDBConnection) -> () in
            switch self.createTable(connection, table: table) {
            case .Created:
                success = true
                connection.checkpoint()
                return
            case .Exists:
                log.debug("Table already exists.")
                success = true
                return
            default:
                success = false
            }
        }

        if let _ = self.db.transaction({ connection -> Bool in
            let thread = NSThread.currentThread().description
            // If the table doesn't exist, we'll create it.
            for table in tables {
                log.debug("Create or update \(table.name) version \(table.version) on \(thread).")
                if !table.exists(connection) {
                    log.debug("Doesn't exist. Creating table \(table.name).")
                    doCreate(table, connection)
                } else {
                    // Otherwise, we'll update it
                    switch self.updateTable(connection, table: table) {
                    case .Updated:
                        log.debug("Updated table \(table.name).")
                        success = true
                        connection.checkpoint()
                        break
                    case .Exists:
                        log.debug("Table \(table.name) already exists.")
                        success = true
                        break
                    default:
                        log.error("Update failed for \(table.name). Dropping and recreating.")

                        table.drop(connection)
                        var err: NSError? = nil
                        self.schemaTable.delete(connection, item: table, err: &err)

                        doCreate(table, connection)
                    }
                }

                if !success {
                    log.warning("Failed to configure multiple tables. Aborting.")
                    return false
                }
            }
            return success
        }) {
            // Err getting a transaction
            success = false
        }

        // If we failed, move the file and try again. This will probably break things that are already
        // attached and expecting a working DB, but at least we should be able to restart.
        if !success {
            log.debug("Couldn't create or update \(tables.map { $0.name }).")
            log.debug("Attempting to move \(self.filename) to another location.")

            // Make sure that we don't still have open the files that we want to move!
            db.close()

            // Note that a backup file might already exist! We append a counter to avoid this.
            var bakCounter = 0
            var bak: String
            repeat {
                bak = "\(self.filename).bak.\(++bakCounter)"
            } while self.files.exists(bak)

            do {
                try self.files.move(self.filename, toRelativePath: bak)
                try self.files.move(self.filename + "-shm", toRelativePath: bak + "-shm")
                try self.files.move(self.filename + "-wal", toRelativePath: bak + "-wal")
                success = true
            } catch _ {
                success = false
            }
            assert(success)

            if let _ = db.transaction({ connection -> Bool in
                for table in tables {
                    doCreate(table, connection)
                    if !success {
                        return false
                    }
                }
                return success
            }) {
                success = false;
            }
        }

        return success
    }

    typealias IntCallback = (connection: SQLiteDBConnection, inout err: NSError?) -> Int

    func withConnection<T>(flags flags: SwiftData.Flags, inout err: NSError?, callback: (connection: SQLiteDBConnection, inout err: NSError?) -> T) -> T {
        var res: T!
        err = db.withConnection(flags) { connection in
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

    func transaction(inout err: NSError?, callback: (connection: SQLiteDBConnection, inout err: NSError?) -> Bool) -> NSError? {
        return self.transaction(synchronous: true, err: &err, callback: callback)
    }

    func transaction(synchronous synchronous: Bool=true, inout err: NSError?, callback: (connection: SQLiteDBConnection, inout err: NSError?) -> Bool) -> NSError? {
        return db.transaction(synchronous: synchronous) { connection in
            var err: NSError? = nil
            return callback(connection: connection, err: &err)
        }
    }
}

extension BrowserDB {
    func vacuum() {
        log.debug("Vacuuming a BrowserDB.")
        db.withConnection(SwiftData.Flags.ReadWriteCreate, synchronous: true) { connection in
            return connection.vacuum()
        }
    }

    func checkpoint() {
        log.debug("Checkpointing a BrowserDB.")
        db.transaction(synchronous: true) { connection in
            connection.checkpoint()
            return true
        }
    }
}

extension BrowserDB {
    public class func varlist(count: Int) -> String {
        return "(" + Array(count: count, repeatedValue: "?").joinWithSeparator(", ") + ")"
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

        let cols = columns.joinWithSeparator(", ")
        let queryStart = "\(op.rawValue) INTO \(table) (\(cols)) VALUES "

        let varString = BrowserDB.varlist(variablesPerRow)

        let insertChunk: [Args] -> Success = { vals -> Success in
            let valuesString = Array(count: vals.count, repeatedValue: varString).joinWithSeparator(", ")
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
        return walk(chunks, f: { insertChunk(Array($0)) })
    }

    func runWithConnection<T>(block: (connection: SQLiteDBConnection, inout err: NSError?) -> T) -> Deferred<Maybe<T>> {
        return DeferredDBOperation(db: self.db, block: block).start()
    }

    func write(sql: String, withArgs args: Args? = nil) -> Deferred<Maybe<Int>> {
        return self.runWithConnection() { (connection, err) -> Int in
            err = connection.executeChange(sql, withArgs: args)
            if err == nil {
                let modified = connection.numberOfRowsModified
                log.debug("Modified rows: \(modified).")
                return modified
            }
            return 0
        }
    }

    public func close() {
        db.close()
    }

    func run(sql: String, withArgs args: Args? = nil) -> Success {
        return run([(sql, args)])
    }

    func run(commands: [String]) -> Success {
        return self.run(commands.map { (sql: $0, args: nil) })
    }

    /**
     * Runs an array of sql commands. Note: These will all run in order in a transaction and will block
     * the callers thread until they've finished. If any of them fail the operation will abort (no more
     * commands will be run) and the transaction will rollback, returning a DatabaseError.
     */
    func run(sql: [(sql: String, args: Args?)]) -> Success {
        var err: NSError? = nil
        self.transaction(&err) { (conn, err) -> Bool in
            for (sql, args) in sql {
                err = conn.executeChange(sql, withArgs: args)
                if err != nil {
                    return false
                }
            }
            return true
        }

        if let err = err {
            return deferMaybe(DatabaseError(err: err))
        }

        return succeed()
    }

    func runQuery<T>(sql: String, args: Args?, factory: SDRow -> T) -> Deferred<Maybe<Cursor<T>>> {
        return runWithConnection { (connection, err) -> Cursor<T> in
            return connection.executeQuery(sql, factory: factory, withArgs: args)
        }
    }
}

extension SQLiteDBConnection {
    func tablesExist(names: Args) -> Bool {
        let count = names.count
        let orClause = Array(count: count, repeatedValue: "name = ?").joinWithSeparator(" OR ")
        let tablesSQL = "SELECT name FROM sqlite_master WHERE type = 'table' AND (\(orClause))"

        let res = self.executeQuery(tablesSQL, factory: StringFactory, withArgs: names)
        log.debug("\(res.count) tables exist. Expected \(count)")
        return res.count > 0
    }
}