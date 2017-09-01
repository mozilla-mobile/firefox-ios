/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger
import Deferred
import Shared

public let NotificationDatabaseWasRecreated = Notification.Name("NotificationDatabaseWasRecreated")

private let log = Logger.syncLogger

public typealias Args = [Any?]

protocol Changeable {
    func run(_ sql: String, withArgs args: Args?) -> Success
    func run(_ commands: [String]) -> Success
    func run(_ commands: [(sql: String, args: Args?)]) -> Success
}

protocol Queryable {
    func runQuery<T>(_ sql: String, args: Args?, factory: @escaping (SDRow) -> T) -> Deferred<Maybe<Cursor<T>>>
}

open class BrowserDB {
    fileprivate let db: SwiftData

    // SQLITE_MAX_VARIABLE_NUMBER = 999 by default. This controls how many ?s can
    // appear in a query string.
    open static let MaxVariableNumber = 999

    public init(filename: String, secretKey: String? = nil, schema: Schema, files: FileAccessor) {
        log.debug("Initializing BrowserDB: \(filename).")

        let file = URL(fileURLWithPath: (try! files.getAndEnsureDirectory())).appendingPathComponent(filename).path

        if AppConstants.BuildChannel == .developer && secretKey != nil {
            log.debug("Will attempt to use encrypted DB: \(file) with secret = \(secretKey ?? "nil")")
        }

        self.db = SwiftData(filename: file, key: secretKey, prevKey: nil, schema: schema, files: files)
    }

    // For testing purposes or other cases where we want to ensure that this `BrowserDB`
    // instance has been initialized (schema is created/updated).
    public func touch() -> Success {
        let deferred = Success()
        var err: NSError? = nil
        withConnection(&err) { connection, error -> Void in
            guard let _ = connection as? ConcreteSQLiteDBConnection else {
                deferred.fill(Maybe(failure: DatabaseError(description: "Could not establish a database connection")))
                return
            }

            deferred.fill(Maybe(success: ()))
        }

        return deferred
    }

    func withConnection<T>(flags: SwiftData.Flags, err: inout NSError?, callback: @escaping (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> T) -> T {
        var res: T!
        err = db.withConnection(flags) { connection in
            // An error may occur if the internet connection is dropped.
            var err: NSError? = nil
            res = callback(connection, &err)
            return err
        }
        return res
    }

    func withConnection<T>(_ err: inout NSError?, callback: @escaping (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> T) -> T {
        /*
         * Opening a WAL-using database with a hot journal cannot complete in read-only mode.
         * The supported mechanism for a read-only query against a WAL-using SQLite database is to use PRAGMA query_only,
         * but this isn't all that useful for us, because we have a mixed read/write workload.
         */
        
        return withConnection(flags: SwiftData.Flags.readWriteCreate, err: &err, callback: callback)
    }

    func transaction(_ err: inout NSError?, callback: @escaping (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> Bool) -> NSError? {
        return self.transaction(synchronous: true, err: &err, callback: callback)
    }

    func transaction(synchronous: Bool=true, err: inout NSError?, callback: @escaping (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> Bool) -> NSError? {
        return db.transaction(synchronous: synchronous) { connection in
            var err: NSError? = nil
            return callback(connection, &err)
        }
    }

    func vacuum() {
        log.debug("Vacuuming a BrowserDB.")
        _ = db.withConnection(SwiftData.Flags.readWriteCreate, synchronous: true) { connection in
            return connection.vacuum()
        }
    }

    func checkpoint() {
        log.debug("Checkpointing a BrowserDB.")
        _ = db.transaction(synchronous: true) { connection in
            connection.checkpoint()
            return true
        }
    }

    public class func varlist(_ count: Int) -> String {
        return "(" + Array(repeating: "?", count: count).joined(separator: ", ") + ")"
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
    func bulkInsert(_ table: String, op: InsertOperation, columns: [String], values: [Args]) -> Success {
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

        let cols = columns.joined(separator: ", ")
        let queryStart = "\(op.rawValue) INTO \(table) (\(cols)) VALUES "

        let varString = BrowserDB.varlist(variablesPerRow)

        let insertChunk: ([Args]) -> Success = { vals -> Success in
            let valuesString = Array(repeating: varString, count: vals.count).joined(separator: ", ")
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

    func runWithConnection<T>(_ block: @escaping (_ connection: SQLiteDBConnection, _ err: inout NSError?) -> T) -> Deferred<Maybe<T>> {
        return DeferredDBOperation(db: self.db, block: block).start()
    }

    func write(_ sql: String, withArgs args: Args? = nil) -> Deferred<Maybe<Int>> {
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

    public func forceClose() {
        db.forceClose()
    }

    public func reopenIfClosed() {
        db.reopenIfClosed()
    }
}

extension BrowserDB: Changeable {
    func run(_ sql: String, withArgs args: Args? = nil) -> Success {
        return run([(sql, args)])
    }

    func run(_ commands: [String]) -> Success {
        return self.run(commands.map { (sql: $0, args: nil) })
    }

    /**
     * Runs an array of SQL commands. Note: These will all run in order in a transaction and will block
     * the caller's thread until they've finished. If any of them fail the operation will abort (no more
     * commands will be run) and the transaction will roll back, returning a DatabaseError.
     */
    func run(_ commands: [(sql: String, args: Args?)]) -> Success {
        if commands.isEmpty {
            return succeed()
        }

        var err: NSError? = nil
        let errorResult = self.transaction(&err) { (conn, err) -> Bool in
            for (sql, args) in commands {
                err = conn.executeChange(sql, withArgs: args)
                if let err = err {
                    log.warning("SQL operation failed: \(err.localizedDescription)")
                    return false
                }
            }
            return true
        }

        if let err = err ?? errorResult {
            return deferMaybe(DatabaseError(err: err))
        }

        return succeed()
    }
}

extension BrowserDB: Queryable {
    func runQuery<T>(_ sql: String, args: Args?, factory: @escaping (SDRow) -> T) -> Deferred<Maybe<Cursor<T>>> {
        return runWithConnection { (connection, _) -> Cursor<T> in
            return connection.executeQuery(sql, factory: factory, withArgs: args)
        }
    }

    func queryReturnsResults(_ sql: String, args: Args? = nil) -> Deferred<Maybe<Bool>> {
        return self.runQuery(sql, args: args, factory: { _ in true })
         >>== { deferMaybe($0[0] ?? false) }
    }

    func queryReturnsNoResults(_ sql: String, args: Args? = nil) -> Deferred<Maybe<Bool>> {
        return self.runQuery(sql, args: nil, factory: { _ in false })
          >>== { deferMaybe($0[0] ?? true) }
    }
}
