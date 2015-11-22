/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

/*
 * This is a heavily modified version of SwiftData.swift by Ryan Fowler
 * This has been enhanced to support custom files, correct binding, versioning,
 * and a streaming results via Cursors. The API has also been changed to use NSError, Cursors, and
 * to force callers to request a connection before executing commands. Database creation helpers, savepoint
 * helpers, image support, and other features have been removed.
 */

// SwiftData.swift
//
// Copyright (c) 2014 Ryan Fowler
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit
import Shared
import XCGLogger

private let DatabaseBusyTimeout: Int32 = 3 * 1000
private let log = Logger.syncLogger

/**
 * Handle to a SQLite database.
 * Each instance holds a single connection that is shared across all queries.
 */
public class SwiftData {
    let filename: String

    static var EnableWAL = true
    static var EnableForeignKeys = true

    /// Used for testing.
    static var ReuseConnections = true

    /// For thread-safe access to the shared connection.
    private let sharedConnectionQueue: dispatch_queue_t

    /// Shared connection to this database.
    private var sharedConnection: SQLiteDBConnection?
    private var key: String? = nil
    private var prevKey: String? = nil

    init(filename: String, key: String? = nil, prevKey: String? = nil) {
        self.filename = filename
        self.sharedConnectionQueue = dispatch_queue_create("SwiftData queue: \(filename)", DISPATCH_QUEUE_SERIAL)

        // Ensure that multi-thread mode is enabled by default.
        // See https://www.sqlite.org/threadsafe.html
        assert(sqlite3_threadsafe() == 2)
        self.key = key
        self.prevKey = prevKey
    }

    private func getSharedConnection() -> SQLiteDBConnection? {
        var connection: SQLiteDBConnection?

        dispatch_sync(sharedConnectionQueue) {
            if self.sharedConnection == nil {
                log.debug(">>> Creating shared SQLiteDBConnection for \(self.filename) on thread \(NSThread.currentThread()).")
                self.sharedConnection = SQLiteDBConnection(filename: self.filename, flags: SwiftData.Flags.ReadWriteCreate.toSQL(), key: self.key, prevKey: self.prevKey)
            }
            connection = self.sharedConnection
        }

        return connection
    }

    /**
     * The real meat of all the execute methods. This is used internally to open and
     * close a database connection and run a block of code inside it.
     */
    public func withConnection(flags: SwiftData.Flags, synchronous: Bool=true, cb: (db: SQLiteDBConnection) -> NSError?) -> NSError? {
        let conn: SQLiteDBConnection?

        if SwiftData.ReuseConnections {
            conn = getSharedConnection()
        } else {
            log.debug(">>> Creating non-shared SQLiteDBConnection for \(self.filename) on thread \(NSThread.currentThread()).")
            conn = SQLiteDBConnection(filename: filename, flags: flags.toSQL(), key: self.key, prevKey: self.prevKey)
        }

        guard let connection = conn else {
            return NSError(domain: "mozilla", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create a connection"])
        }

        if synchronous {
            var error: NSError? = nil
            dispatch_sync(connection.queue) {
                error = cb(db: connection)
            }
            return error
        }

        dispatch_async(connection.queue) {
            cb(db: connection)
        }
        return nil
    }

    public func transaction(transactionClosure: (db: SQLiteDBConnection) -> Bool) -> NSError? {
        return self.transaction(synchronous: true, transactionClosure: transactionClosure)
    }

    /**
     * Helper for opening a connection, starting a transaction, and then running a block of code inside it.
     * The code block can return true if the transaction should be committed. False if we should roll back.
     */
    public func transaction(synchronous synchronous: Bool=true, transactionClosure: (db: SQLiteDBConnection) -> Bool) -> NSError? {
        return withConnection(SwiftData.Flags.ReadWriteCreate, synchronous: synchronous) { db in
            if let err = db.executeChange("BEGIN EXCLUSIVE") {
                log.warning("BEGIN EXCLUSIVE failed.")
                return err
            }

            if transactionClosure(db: db) {
                log.verbose("Op in transaction succeeded. Committing.")
                if let err = db.executeChange("COMMIT") {
                    log.error("COMMIT failed. Rolling back.")
                    db.executeChange("ROLLBACK")
                    return err
                }
            } else {
                log.debug("Op in transaction failed. Rolling back.")
                if let err = db.executeChange("ROLLBACK") {
                    return err
                }
            }

            return nil
        }
    }

    func close() {
        dispatch_sync(sharedConnectionQueue) {
            if self.sharedConnection != nil {
                self.sharedConnection?.closeCustomConnection()
            }
            self.sharedConnection = nil
        }
    }

    public enum Flags {
        case ReadOnly
        case ReadWrite
        case ReadWriteCreate

        private func toSQL() -> Int32 {
            switch self {
            case .ReadOnly:
                return SQLITE_OPEN_READONLY
            case .ReadWrite:
                return SQLITE_OPEN_READWRITE
            case .ReadWriteCreate:
                return SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
            }
        }
    }
}

/**
 * Wrapper class for a SQLite statement.
 * This class helps manage the statement lifecycle. By holding a reference to the SQL connection, we ensure
 * the connection is never deinitialized while the statement is active. This class is responsible for
 * finalizing the SQL statement once it goes out of scope.
 */
private class SQLiteDBStatement {
    var pointer: COpaquePointer = nil
    private let connection: SQLiteDBConnection

    init(connection: SQLiteDBConnection, query: String, args: [AnyObject?]?) throws {
        self.connection = connection

        let status = sqlite3_prepare_v2(connection.sqliteDB, query, -1, &pointer, nil)
        if status != SQLITE_OK {
            throw connection.createErr("During: SQL Prepare \(query)", status: Int(status))
        }

        if let args = args,
            let bindError = bind(args) {
            throw bindError
        }
    }

    /// Binds arguments to the statement.
    private func bind(objects: [AnyObject?]) -> NSError? {
        let count = Int(sqlite3_bind_parameter_count(pointer))
        if (count < objects.count) {
            return connection.createErr("During: Bind", status: 202)
        }
        if (count > objects.count) {
            return connection.createErr("During: Bind", status: 201)
        }

        for (index, obj) in objects.enumerate() {
            var status: Int32 = SQLITE_OK

            // Doubles also pass obj as Int, so order is important here.
            if obj is Double {
                status = sqlite3_bind_double(pointer, Int32(index+1), obj as! Double)
            } else if obj is Int {
                status = sqlite3_bind_int(pointer, Int32(index+1), Int32(obj as! Int))
            } else if obj is Bool {
                status = sqlite3_bind_int(pointer, Int32(index+1), (obj as! Bool) ? 1 : 0)
            } else if obj is String {
                typealias CFunction = @convention(c) (UnsafeMutablePointer<()>) -> Void
                let transient = unsafeBitCast(-1, CFunction.self)
                status = sqlite3_bind_text(pointer, Int32(index+1), (obj as! String).cStringUsingEncoding(NSUTF8StringEncoding)!, -1, transient)
            } else if obj is NSData {
                status = sqlite3_bind_blob(pointer, Int32(index+1), (obj as! NSData).bytes, -1, nil)
            } else if obj is NSDate {
                let timestamp = (obj as! NSDate).timeIntervalSince1970
                status = sqlite3_bind_double(pointer, Int32(index+1), timestamp)
            } else if obj === nil {
                status = sqlite3_bind_null(pointer, Int32(index+1))
            }

            if status != SQLITE_OK {
                return connection.createErr("During: Bind", status: Int(status))
            }
        }

        return nil
    }

    func close() {
        if nil != self.pointer {
            sqlite3_finalize(self.pointer)
            self.pointer = nil
        }
    }

    deinit {
        if nil != self.pointer {
            sqlite3_finalize(self.pointer)
        }
    }
}

public class SQLiteDBConnection {
    private var sqliteDB: COpaquePointer = nil
    private let filename: String
    private let debug_enabled = false
    private let queue: dispatch_queue_t

    public var version: Int {
        get {
            let res = executeQueryUnsafe("PRAGMA user_version", factory: IntFactory)
            return res[0] ?? 0
        }

        set {
            executeChange("PRAGMA user_version = \(newValue)")
        }
    }

    private func setKey(key: String?) -> NSError? {
        sqlite3_key(sqliteDB, key ?? "", Int32((key ?? "").characters.count))
        let cursor = executeQuery("SELECT count(*) FROM sqlite_master;", factory: IntFactory, withArgs: nil)
        if cursor.status != .Success {
            return NSError(domain: "mozilla", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid key"])
        }
        return nil
    }

    private func reKey(oldKey: String?, newKey: String?) -> NSError? {
        sqlite3_key(sqliteDB, oldKey ?? "", Int32((oldKey ?? "").characters.count))
        sqlite3_rekey(sqliteDB, newKey ?? "", Int32((newKey ?? "").characters.count))
        // Check that the new key actually works
        sqlite3_key(sqliteDB, newKey ?? "", Int32((newKey ?? "").characters.count))
        let cursor = executeQuery("SELECT count(*) FROM sqlite_master;", factory: IntFactory, withArgs: nil)
        if cursor.status != .Success {
            return NSError(domain: "mozilla", code: 0, userInfo: [NSLocalizedDescriptionKey: "Rekey failed"])
        }

        return nil
    }

    func interrupt() {
        log.debug("Interrupt")
        sqlite3_interrupt(sqliteDB)
    }

    private func pragma<T: Equatable>(pragma: String, expected: T?, factory: SDRow -> T, message: String) {
        let cursor = executeQueryUnsafe("PRAGMA \(pragma)", factory: factory)
        assert(cursor[0] == expected, message)
    }

    init?(filename: String, flags: Int32, key: String? = nil, prevKey: String? = nil) {
        log.debug("Opening connection to \(filename).")
        self.filename = filename
        self.queue = dispatch_queue_create("SQLite connection: \(filename)", DISPATCH_QUEUE_SERIAL)
        if let failure = openWithFlags(flags) {
            log.warning("Opening connection to \(filename) failed: \(failure).")
            return nil
        }

        // Setting the key need to be the first thing done with the database.
        if let _ = setKey(key) {
            closeCustomConnection()
            if let _ = openWithFlags(flags) {
                return nil
            }
            if let _ = reKey(prevKey, newKey: key) {
                log.error("Unable to encrypt database")
                return nil
            }
        }

        //
        // For where these values come from, see Bug 1213623.
        //

        let currentPageSize = executeQueryUnsafe("PRAGMA page_size", factory: IntFactory)[0]
        let desiredPageSize = 32 * 1024

        // This has to be done without WAL, so we always hop into rollback/delete journal mode.
        if currentPageSize != desiredPageSize {
            pragma("journal_mode=DELETE", expected: "delete",
                   factory: StringFactory, message: "delete journal mode set")

            pragma("page_size=\(desiredPageSize)", expected: nil, factory: IntFactory, message: "Page size set")

            log.info("Vacuuming to alter database page size from \(currentPageSize) to \(desiredPageSize).")
            if let err = self.vacuum() {
                log.error("Vacuuming failed: \(err).")
            } else {
                log.debug("Vacuuming succeeded.")
            }
        }

        if SwiftData.EnableWAL {
            log.info("Enabling WAL mode.")

            let desiredPagesPerJournal = 16
            let desiredCheckpointSize = desiredPagesPerJournal * desiredPageSize
            let desiredJournalSizeLimit = 3 * desiredCheckpointSize

            pragma("journal_mode=WAL", expected: "wal",
                   factory: StringFactory, message: "WAL journal mode set")
            pragma("wal_autocheckpoint=\(desiredPagesPerJournal)", expected: desiredPagesPerJournal,
                   factory: IntFactory, message: "WAL autocheckpoint set")
            pragma("journal_size_limit=\(desiredJournalSizeLimit)", expected: desiredJournalSizeLimit,
                   factory: IntFactory, message: "WAL journal size limit set")
        }

        if SwiftData.EnableForeignKeys {
            executeQueryUnsafe("PRAGMA foreign_keys=ON", factory: IntFactory)
        }

        // Retry queries before returning locked errors.
        sqlite3_busy_timeout(sqliteDB, DatabaseBusyTimeout)
    }

    deinit {
        log.debug("deinit: closing connection on thread \(NSThread.currentThread()).")
        closeCustomConnection()
    }

    var lastInsertedRowID: Int {
        return Int(sqlite3_last_insert_rowid(sqliteDB))
    }

    var numberOfRowsModified: Int {
        return Int(sqlite3_changes(sqliteDB))
    }

    /**
     * Blindly attempts a WAL checkpoint on all attached databases.
     */
    func checkpoint(mode: Int32 = SQLITE_CHECKPOINT_PASSIVE) {
        guard sqliteDB != nil else {
            log.warning("Trying to checkpoint a nil DB!")
            return
        }

        log.debug("Running WAL checkpoint on \(self.filename) on thread \(NSThread.currentThread()).")
        sqlite3_wal_checkpoint_v2(sqliteDB, nil, mode, nil, nil)
        log.debug("WAL checkpoint done on \(self.filename).")
    }

    func vacuum() -> NSError? {
        return self.executeChange("VACUUM")
    }

    /// Creates an error from a sqlite status. Will print to the console if debug_enabled is set.
    /// Do not call this unless you're going to return this error.
    private func createErr(description: String, status: Int) -> NSError {
        var msg = SDError.errorMessageFromCode(status)

        if (debug_enabled) {
            log.debug("SwiftData Error -> \(description)")
            log.debug("                -> Code: \(status) - \(msg)")
        }

        if let errMsg = String.fromCString(sqlite3_errmsg(sqliteDB)) {
            msg += " " + errMsg
            if (debug_enabled) {
                log.debug("                -> Details: \(errMsg)")
            }
        }

        return NSError(domain: "org.mozilla", code: status, userInfo: [NSLocalizedDescriptionKey: msg])
    }

    /// Open the connection. This is called when the db is created. You should not call it yourself.
    private func openWithFlags(flags: Int32) -> NSError? {
        let status = sqlite3_open_v2(filename.cStringUsingEncoding(NSUTF8StringEncoding)!, &sqliteDB, flags, nil)
        if status != SQLITE_OK {
            return createErr("During: Opening Database with Flags", status: Int(status))
        }
        return nil
    }

    /// Closes a connection. This is called via deinit. Do not call this yourself.
    private func closeCustomConnection() -> NSError? {
        log.debug("Closing custom connection for \(self.filename) on \(NSThread.currentThread()).")
        // Make sure we don't try to call sqlite3_close multiple times.
        // TODO: add a lock here?
        guard self.sqliteDB != nil else {
            log.warning("Connection was nil.")
            return nil
        }

        let status = sqlite3_close(self.sqliteDB)
        log.debug("Closed \(self.filename).")
        self.sqliteDB = nil

        if status != SQLITE_OK {
            log.error("Got \(status) while closing.")
            return createErr("During: closing database with flags", status: Int(status))
        }

        return nil
    }

    /// Executes a change on the database.
    func executeChange(sqlStr: String, withArgs args: [AnyObject?]? = nil) -> NSError? {
        var error: NSError?
        let statement: SQLiteDBStatement?
        do {
            statement = try SQLiteDBStatement(connection: self, query: sqlStr, args: args)
        } catch let error1 as NSError {
            error = error1
            statement = nil
        }
        if let error = error {
            log.error("SQL error: \(error.localizedDescription) for SQL \(sqlStr).")
            statement?.close()
            return error
        }

        let status = sqlite3_step(statement!.pointer)

        if status != SQLITE_DONE && status != SQLITE_OK {
            error = createErr("During: SQL Step \(sqlStr)", status: Int(status))
        }

        statement?.close()
        return error
    }

    /// Queries the database.
    /// Returns a cursor pre-filled with the complete result set.
    func executeQuery<T>(sqlStr: String, factory: ((SDRow) -> T), withArgs args: [AnyObject?]? = nil) -> Cursor<T> {
        var error: NSError?
        let statement: SQLiteDBStatement?
        do {
            statement = try SQLiteDBStatement(connection: self, query: sqlStr, args: args)
        } catch let error1 as NSError {
            error = error1
            statement = nil
        }
        if let error = error {
            log.error("SQL error: \(error.localizedDescription).")
            return Cursor<T>(err: error)
        }

        let cursor = FilledSQLiteCursor<T>(statement: statement!, factory: factory)

        // Close, not reset -- this isn't going to be reused, and the cursor has
        // consumed everything.
        statement?.close()

        return cursor
    }

    /**
     * Queries the database.
     * Returns a live cursor that holds the query statement and database connection.
     * Instances of this class *must not* leak outside of the connection queue!
     */
    func executeQueryUnsafe<T>(sqlStr: String, factory: ((SDRow) -> T), withArgs args: [AnyObject?]? = nil) -> Cursor<T> {
        var error: NSError?
        let statement: SQLiteDBStatement?
        do {
            statement = try SQLiteDBStatement(connection: self, query: sqlStr, args: args)
        } catch let error1 as NSError {
            error = error1
            statement = nil
        }
        if let error = error {
            return Cursor(err: error)
        }

        return LiveSQLiteCursor(statement: statement!, factory: factory)
    }
}

/// Helper for queries that return a single integer result.
func IntFactory(row: SDRow) -> Int {
    return row[0] as! Int
}

/// Helper for queries that return a single String result.
func StringFactory(row: SDRow) -> String {
    return row[0] as! String
}

/// Wrapper around a statement for getting data from a row. This provides accessors for subscript indexing
/// and a generator for iterating over columns.
class SDRow: SequenceType {
    // The sqlite statement this row came from.
    private let statement: SQLiteDBStatement

    // The columns of this database. The indices of these are assumed to match the indices
    // of the statement.
    private let columnNames: [String]

    private init(statement: SQLiteDBStatement, columns: [String]) {
        self.statement = statement
        self.columnNames = columns
    }

    // Return the value at this index in the row
    private func getValue(index: Int) -> AnyObject? {
        let i = Int32(index)

        let type = sqlite3_column_type(statement.pointer, i)
        var ret: AnyObject? = nil

        switch type {
        case SQLITE_NULL, SQLITE_INTEGER:
            ret = NSNumber(longLong: sqlite3_column_int64(statement.pointer, i))
        case SQLITE_TEXT:
            let text = UnsafePointer<Int8>(sqlite3_column_text(statement.pointer, i))
            ret = String.fromCString(text)
        case SQLITE_BLOB:
            let blob = sqlite3_column_blob(statement.pointer, i)
            if blob != nil {
                let size = sqlite3_column_bytes(statement.pointer, i)
                ret = NSData(bytes: blob, length: Int(size))
            }
        case SQLITE_FLOAT:
            ret = Double(sqlite3_column_double(statement.pointer, i))
        default:
            log.warning("SwiftData Warning -> Column: \(index) is of an unrecognized type, returning nil")
        }

        return ret
    }

    // Accessor getting column 'key' in the row
    subscript(key: Int) -> AnyObject? {
        return getValue(key)
    }

    // Accessor getting a named column in the row. This (currently) depends on
    // the columns array passed into this Row to find the correct index.
    subscript(key: String) -> AnyObject? {
        get {
            if let index = columnNames.indexOf(key) {
                return getValue(index)
            }
            return nil
        }
    }

    // Allow iterating through the row. This is currently broken.
    func generate() -> AnyGenerator<Any> {
        let nextIndex = 0
        return anyGenerator() {
            // This crashes the compiler. Yay!
            if (nextIndex < self.columnNames.count) {
                return nil // self.getValue(nextIndex)
            }
            return nil
        }
    }
}

/// Helper for pretty printing SQL (and other custom) error codes.
private struct SDError {
    private static func errorMessageFromCode(errorCode: Int) -> String {
        switch errorCode {
        case -1:
            return "No error"
            // SQLite error codes and descriptions as per: http://www.sqlite.org/c3ref/c_abort.html
        case 0:
            return "Successful result"
        case 1:
            return "SQL error or missing database"
        case 2:
            return "Internal logic error in SQLite"
        case 3:
            return "Access permission denied"
        case 4:
            return "Callback routine requested an abort"
        case 5:
            return "The database file is busy"
        case 6:
            return "A table in the database is locked"
        case 7:
            return "A malloc() failed"
        case 8:
            return "Attempt to write a readonly database"
        case 9:
            return "Operation terminated by sqlite3_interrupt()"
        case 10:
            return "Some kind of disk I/O error occurred"
        case 11:
            return "The database disk image is malformed"
        case 12:
            return "Unknown opcode in sqlite3_file_control()"
        case 13:
            return "Insertion failed because database is full"
        case 14:
            return "Unable to open the database file"
        case 15:
            return "Database lock protocol error"
        case 16:
            return "Database is empty"
        case 17:
            return "The database schema changed"
        case 18:
            return "String or BLOB exceeds size limit"
        case 19:
            return "Abort due to constraint violation"
        case 20:
            return "Data type mismatch"
        case 21:
            return "Library used incorrectly"
        case 22:
            return "Uses OS features not supported on host"
        case 23:
            return "Authorization denied"
        case 24:
            return "Auxiliary database format error"
        case 25:
            return "2nd parameter to sqlite3_bind out of range"
        case 26:
            return "File opened that is not a database file"
        case 27:
            return "Notifications from sqlite3_log()"
        case 28:
            return "Warnings from sqlite3_log()"
        case 100:
            return "sqlite3_step() has another row ready"
        case 101:
            return "sqlite3_step() has finished executing"

            // Custom SwiftData errors
            // Binding errors
        case 201:
            return "Not enough objects to bind provided"
        case 202:
            return "Too many objects to bind provided"

            // Custom connection errors
        case 301:
            return "A custom connection is already open"
        case 302:
            return "Cannot open a custom connection inside a transaction"
        case 303:
            return "Cannot open a custom connection inside a savepoint"
        case 304:
            return "A custom connection is not currently open"
        case 305:
            return "Cannot close a custom connection inside a transaction"
        case 306:
            return "Cannot close a custom connection inside a savepoint"

            // Index and table errors
        case 401:
            return "At least one column name must be provided"
        case 402:
            return "Error extracting index names from sqlite_master"
        case 403:
            return "Error extracting table names from sqlite_master"

            // Transaction and savepoint errors
        case 501:
            return "Cannot begin a transaction within a savepoint"
        case 502:
            return "Cannot begin a transaction within another transaction"

            // Unknown error
        default:
            return "Unknown error"
        }
    }
}

/// Provides access to the result set returned by a database query.
/// The entire result set is cached, so this does not retain a reference
/// to the statement or the database connection.
private class FilledSQLiteCursor<T>: ArrayCursor<T> {
    private init(statement: SQLiteDBStatement, factory: (SDRow) -> T) {
        var status = CursorStatus.Success
        var statusMessage = ""
        let data = FilledSQLiteCursor.getValues(statement, factory: factory, status: &status, statusMessage: &statusMessage)
        super.init(data: data, status: status, statusMessage: statusMessage)
    }

    /// Return an array with the set of results and release the statement.
    private class func getValues(statement: SQLiteDBStatement, factory: (SDRow) -> T, inout status: CursorStatus, inout statusMessage: String) -> [T] {
        var rows = [T]()
        var count = 0
        status = CursorStatus.Success
        statusMessage = "Success"

        var columns = [String]()
        let columnCount = sqlite3_column_count(statement.pointer)
        for i in 0..<columnCount {
            let columnName = String.fromCString(sqlite3_column_name(statement.pointer, i))!
            columns.append(columnName)
        }

        while true {
            let sqlStatus = sqlite3_step(statement.pointer)

            if sqlStatus != SQLITE_ROW {
                if sqlStatus != SQLITE_DONE {
                    // NOTE: By setting our status to failure here, we'll report our count as zero,
                    // regardless of how far we've read at this point.
                    status = CursorStatus.Failure
                    statusMessage = SDError.errorMessageFromCode(Int(sqlStatus))
                }
                break
            }

            count++

            let row = SDRow(statement: statement, columns: columns)
            let result = factory(row)
            rows.append(result)
        }

        return rows
    }
}

/// Wrapper around a statement to help with iterating through the results.
private class LiveSQLiteCursor<T>: Cursor<T> {
    private var statement: SQLiteDBStatement!

    // Function for generating objects of type T from a row.
    private let factory: (SDRow) -> T

    // Status of the previous fetch request.
    private var sqlStatus: Int32 = 0

    // Number of rows in the database
    // XXX - When Cursor becomes an interface, this should be a normal property, but right now
    //       we can't override the Cursor getter for count with a stored property.
    private var _count: Int = 0
    override var count: Int {
        get {
            if status != .Success {
                return 0
            }
            return _count
        }
    }

    private var position: Int = -1 {
        didSet {
            // If we're already there, shortcut out.
            if (oldValue == position) {
                return
            }

            var stepStart = oldValue

            // If we're currently somewhere in the list after this position
            // we'll have to jump back to the start.
            if (position < oldValue) {
                sqlite3_reset(self.statement.pointer)
                stepStart = -1
            }

            // Now step up through the list to the requested position
            for _ in stepStart..<position {
                sqlStatus = sqlite3_step(self.statement.pointer)
            }
        }
    }

    init(statement: SQLiteDBStatement, factory: (SDRow) -> T) {
        self.factory = factory
        self.statement = statement

        // The only way I know to get a count. Walk through the entire statement to see how many rows there are.
        var count = 0
        self.sqlStatus = sqlite3_step(statement.pointer)
        while self.sqlStatus != SQLITE_DONE {
            count++
            self.sqlStatus = sqlite3_step(statement.pointer)
        }

        sqlite3_reset(statement.pointer)
        self._count = count

        super.init(status: .Success, msg: "success")
    }

    // Helper for finding all the column names in this statement.
    private lazy var columns: [String] = {
        // This untangles all of the columns and values for this row when its created
        let columnCount = sqlite3_column_count(self.statement.pointer)
        var columns = [String]()
        for var i: Int32 = 0; i < columnCount; ++i {
            let columnName = String.fromCString(sqlite3_column_name(self.statement.pointer, i))!
            columns.append(columnName)
        }
        return columns
    }()

    override subscript(index: Int) -> T? {
        get {
            if status != .Success {
                return nil
            }

            self.position = index
            if self.sqlStatus != SQLITE_ROW {
                return nil
            }

            let row = SDRow(statement: statement, columns: self.columns)
            return self.factory(row)
        }
    }

    override func close() {
        statement = nil
        super.close()
    }
}
