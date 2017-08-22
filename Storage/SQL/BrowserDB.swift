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

public enum DatabaseOpResult {
    case success
    case failure
    case closed
}

open class BrowserDB {
    fileprivate let db: SwiftData
    fileprivate let files: FileAccessor
    fileprivate let filename: String
    fileprivate let secretKey: String?

    // SQLITE_MAX_VARIABLE_NUMBER = 999 by default. This controls how many ?s can
    // appear in a query string.
    open static let MaxVariableNumber = 999

    // SQLite standard error codes when the DB file is locked, busy or the disk is
    // full. These error codes indicate that any issues with writing to the database
    // are temporary and we should not wipe out and re-create the database file when
    // we encounter them.
    enum SQLiteRecoverableError: Int {
        case Busy = 5
        case Locked = 6
        case ReadOnly = 8
        case IOErr = 10
        case Full = 13
    }

    public init(filename: String, secretKey: String? = nil, files: FileAccessor) {
        log.debug("Initializing BrowserDB: \(filename).")
        self.files = files
        self.filename = filename
        self.secretKey = secretKey

        let file = URL(fileURLWithPath: (try! files.getAndEnsureDirectory())).appendingPathComponent(filename).path
        self.db = SwiftData(filename: file, key: secretKey, prevKey: nil)

        if AppConstants.BuildChannel == .developer && secretKey != nil {
            log.debug("Will attempt to use encrypted DB: \(file) with secret = \(secretKey ?? "nil")")
        }
    }

    // Creates the specified database schema in a new database.
    fileprivate func createSchema(_ conn: SQLiteDBConnection, schema: Schema) -> Bool {
        log.debug("Try create \(schema.name) version \(schema.version)")
        if !schema.create(conn) {
            // If schema couldn't be created, we'll bail without setting the `PRAGMA user_version`.
            log.debug("Creation failed.")
            return false
        }

        if let error = conn.setVersion(schema.version) {
            log.error("Unable to update the schema version; \(error.localizedDescription)")
        }
        
        return true
    }

    // Updates the specified database schema in an existing database.
    fileprivate func updateSchema(_ conn: SQLiteDBConnection, schema: Schema) -> Bool {
        log.debug("Trying to update table '\(schema.name)' from version \(conn.version) to \(schema.version)")
        if !schema.update(conn, from: conn.version) {
            // If schema couldn't be updated, we'll bail without setting the `PRAGMA user_version`.
            log.debug("Updating failed.")
            return false
        }

        if let error = conn.setVersion(schema.version) {
            log.error("Unable to update the schema version; \(error.localizedDescription)")
        }

        return true
    }

    // Checks if the database schema needs created or updated and acts accordingly.
    // Calls to this function will be serialized to prevent race conditions when
    // creating or updating the schema.
    func prepareSchema(_ schema: Schema) -> DatabaseOpResult {
        // Ensure the database has not already been closed before attempting to
        // create or update the schema.
        guard !db.closed else {
            log.info("Database is closed; Skipping schema create or update.")
            return .closed
        }

        // Get the current schema version for the database.
        var currentVersion = 0
        _ = self.db.withConnection(.readOnly, cb: { connection -> NSError? in
            currentVersion = connection.version
            return nil
        })
        
        // If the current schema version for the database matches the specified
        // `Schema` version, no further action is necessary and we can bail out.
        // NOTE: This assumes that we always use *ONE* `Schema` per database file
        // since SQLite can only track a single value in `PRAGMA user_version`.
        if currentVersion == schema.version {
            log.debug("Schema \(schema.name) already exists at version \(schema.version). Skipping additional schema preparation.")
            return .success
        }
        
        // This should not ever happen since the schema version should always be
        // increasing whenever a structural change is made in an app update.
        guard currentVersion <= schema.version else {
            log.error("Schema \(schema.name) cannot be downgraded from version \(currentVersion) to \(schema.version).")
            SentryIntegration.shared.sendWithStacktrace(message: "Schema \(schema.name) cannot be downgraded from version \(currentVersion) to \(schema.version).", tag: "BrowserDB", severity: .error)
            return .failure
        }

        log.debug("Schema \(schema.name) needs created or updated from version \(currentVersion) to \(schema.version).")

        var success = true

        if let error = self.db.transaction({ connection -> Bool in
            log.debug("Create or update \(schema.name) version \(schema.version) on \(Thread.current.description).")

            // In the event that `prepareSchema()` is called a second time before the schema
            // update is complete, we can check if we're *now* up-to-date and bail out early.
            if connection.version == schema.version {
                success = true
                return success
            }

            // If `PRAGMA user_version` is zero, check if we can safely create the
            // database schema from scratch.
            if connection.version == 0 {
                // Query for the existence of the `tableList` table to determine if we are
                // migrating from an older DB version.
                let sqliteMasterCursor = connection.executeQueryUnsafe("SELECT COUNT(*) AS number FROM sqlite_master WHERE type = 'table' AND name = 'tableList'", factory: IntFactory, withArgs: [] as Args)
                
                let tableListTableExists = sqliteMasterCursor[0] == 1
                sqliteMasterCursor.close()
                
                // If the `tableList` table doesn't exist, we can simply invoke
                // `createSchema()` to create a brand new DB from scratch.
                if !tableListTableExists {
                    log.debug("Schema \(schema.name) doesn't exist. Creating.")
                    success = self.createSchema(connection, schema: schema)
                    return success
                }
            }

            // If we can't create a brand new schema from scratch, we must
            // call `updateSchema()` to go through the update process.
            if self.updateSchema(connection, schema: schema) {
                log.debug("Updated schema \(schema.name).")
                success = true
                return success
            }

            // If we failed to update the schema, we'll drop everything from the DB
            // and create everything again from scratch. Assuming our schema upgrade
            // code is correct, this *shouldn't* happen. If it does, log it to Sentry.
            log.error("Update failed for schema \(schema.name) from version \(currentVersion) to \(schema.version). Dropping and re-creating.")
            SentryIntegration.shared.sendWithStacktrace(message: "Update failed for schema \(schema.name) from version \(currentVersion) to \(schema.version). Dropping and re-creating.", tag: "BrowserDB", severity: .error)

            let _ = schema.drop(connection)
            success = self.createSchema(connection, schema: schema)
            return success
        }) {
            guard !db.closed else {
                log.info("Database is closed; Skipping schema create or update.")
                return .closed
            }

            // If we got an error, move the file and try again. This will probably break things that are
            // already attached and expecting a working DB, but at least we should be able to restart.
            log.error("Unable to get a transaction: \(error.localizedDescription)")
            SentryIntegration.shared.sendWithStacktrace(message: "Unable to get a transaction: \(error.localizedDescription)", tag: "BrowserDB", severity: .error)

            // Check if the error we got is recoverable (e.g. SQLITE_BUSY, SQLITE_LOCK, SQLITE_FULL).
            // If so, we *shouldn't* move the database file to a backup location and re-create it.
            // Instead, just crash so that we don't lose any data.
            if let _ = SQLiteRecoverableError.init(rawValue: error.code) {
                fatalError(error.localizedDescription)
            }

            success = false
        }

        guard success else {
            return moveDatabaseToBackupLocation(schema)
        }

        return .success
    }

    func moveDatabaseToBackupLocation(_ schema: Schema) -> DatabaseOpResult {
        // Make sure that we don't still have open the files that we want to move!
        // Note that we use sqlite3_close_v2, which might actually _not_ close the
        // database file yet. For this reason we move the -shm and -wal files, too.
        db.forceClose()

        // Attempt to make a backup as long as the DB file still exists
        if self.files.exists(self.filename) {
            log.warning("Couldn't create or update schema \(schema.name). Attempting to move \(self.filename) to another location.")
            SentryIntegration.shared.sendWithStacktrace(message: "Couldn't create or update schema \(schema.name). Attempting to move \(self.filename) to another location.", tag: "BrowserDB", severity: .warning)

            // Note that a backup file might already exist! We append a counter to avoid this.
            var bakCounter = 0
            var bak: String
            repeat {
                bakCounter += 1
                bak = "\(self.filename).bak.\(bakCounter)"
            } while self.files.exists(bak)

            do {
                try self.files.move(self.filename, toRelativePath: bak)

                let shm = self.filename + "-shm"
                let wal = self.filename + "-wal"
                log.debug("Moving \(shm) and \(wal)…")
                if self.files.exists(shm) {
                    log.debug("\(shm) exists.")
                    try self.files.move(shm, toRelativePath: bak + "-shm")
                }
                if self.files.exists(wal) {
                    log.debug("\(wal) exists.")
                    try self.files.move(wal, toRelativePath: bak + "-wal")
                }

                log.debug("Finished moving \(self.filename) successfully.")
            } catch let error as NSError {
                log.error("Unable to move \(self.filename) to another location. \(error)")
                SentryIntegration.shared.sendWithStacktrace(message: "Unable to move \(self.filename) to another location. \(error)", tag: "BrowserDB", severity: .error)
            }
        } else {
            // No backup was attempted since the DB file did not exist
            log.error("The DB \(self.filename) has been deleted while previously in use.")
            SentryIntegration.shared.sendWithStacktrace(message: "The DB \(self.filename) has been deleted while previously in use.", tag: "BrowserDB", severity: .info)
        }

        // Re-open the connection to the new database file.
        self.reopenIfClosed()

        // Notify the world that we moved the database after the schema has been
        // created. This allows us to reset Sync and start over in the case of
        // corruption.
        defer {
            NotificationCenter.default.post(name: NotificationDatabaseWasRecreated, object: self.filename)
        }

        var success = true

        // Attempt to re-create the schema in the new database file.
        if let error = self.db.transaction({ connection -> Bool in
            success = self.createSchema(connection, schema: schema)
            return success
        }) {
            log.error("Unable to get a transaction while re-creating the database: \(error.localizedDescription)")
            SentryIntegration.shared.sendWithStacktrace(message: "Unable to get a transaction while re-creating the database: \(error.localizedDescription)", tag: "BrowserDB", severity: .error)
            return .failure
        }

        return success ? .success : .failure
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
}

extension BrowserDB {
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
}

extension BrowserDB {
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
