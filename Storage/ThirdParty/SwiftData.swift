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
import Deferred
import Shared
import XCGLogger

private let DatabaseBusyTimeout: Int32 = 3 * 1000
private let log = Logger.syncLogger

enum SQLiteDBConnectionCreatedResult {
    case success
    case failure
    case needsRecovery
}

// SQLite standard error codes when the DB file is locked, busy or the disk is
// full. These error codes indicate that any issues with writing to the database
// are temporary and we should not wipe out and re-create the database file when
// we encounter them.
enum SQLiteDBRecoverableError: Int {
    case Busy = 5
    case Locked = 6
    case ReadOnly = 8
    case IOErr = 10
    case Full = 13
}

/**
 * Handle to a SQLite database.
 * Each instance holds a single connection that is shared across all queries.
 */
open class SwiftData {
    let filename: String
    let schema: Schema
    let files: FileAccessor

    static var EnableWAL = true
    static var EnableForeignKeys = true

    /// Used to keep track of the corrupted databases we've logged.
    static var corruptionLogsWritten = Set<String>()

    /// Used for testing.
    static var ReuseConnections = true

    /// For thread-safe access to the shared connection.
    fileprivate let sharedConnectionQueue: DispatchQueue

    /// Shared connection to this database.
    fileprivate var sharedConnection: ConcreteSQLiteDBConnection?
    fileprivate var key: String?
    fileprivate var prevKey: String?

    /// A simple state flag to track whether we should accept new connection requests.
    /// If a connection request is made while the database is closed, a
    /// FailedSQLiteDBConnection will be returned.
    fileprivate(set) var closed = false

    init(filename: String, key: String? = nil, prevKey: String? = nil, schema: Schema, files: FileAccessor) {
        self.filename = filename
        self.key = key
        self.prevKey = prevKey
        self.schema = schema
        self.files = files

        self.sharedConnectionQueue = DispatchQueue(label: "SwiftData queue: \(filename)", attributes: [])

        // Ensure that multi-thread mode is enabled by default.
        // See https://www.sqlite.org/threadsafe.html
        assert(sqlite3_threadsafe() == 2)
    }

    fileprivate func getSharedConnection() -> ConcreteSQLiteDBConnection? {
        var connection: ConcreteSQLiteDBConnection?

        sharedConnectionQueue.sync {
            if self.closed {
                log.warning(">>> Database is closed for \(self.filename)")
                return
            }

            if self.sharedConnection == nil {
                log.debug(">>> Creating shared SQLiteDBConnection for \(self.filename) on thread \(Thread.current).")
                self.sharedConnection = ConcreteSQLiteDBConnection(filename: self.filename, flags: SwiftData.Flags.readWriteCreate.toSQL(), key: self.key, prevKey: self.prevKey, schema: self.schema, files: self.files)
            }
            connection = self.sharedConnection
        }

        return connection
    }

    /**
     * The real meat of all the execute methods. This is used internally to open and
     * close a database connection and run a block of code inside it.
     */
    func withConnection<T>(_ flags: SwiftData.Flags, synchronous: Bool = false, _ callback: @escaping (_ connection: SQLiteDBConnection) throws -> T) -> Deferred<Maybe<T>> {
        let deferred = Deferred<Maybe<T>>()

        /**
         * We use a weak reference here instead of strongly retaining the connection because we don't want
         * any control over when the connection deallocs. If the only owner of the connection (SwiftData)
         * decides to dealloc it, we should respect that since the deinit method of the connection is tied
         * to the app lifecycle. This is to prevent background disk access causing springboard crashes.
         */
        weak var conn = getSharedConnection()
        let queue = self.sharedConnectionQueue
        
        func doWork() {
            // By the time this dispatch block runs, it is possible the user has backgrounded the
            // app and the connection has been dealloc'ed since we last grabbed the reference
            guard let connection = SwiftData.ReuseConnections ? conn :
                ConcreteSQLiteDBConnection(filename: filename, flags: flags.toSQL(), key: self.key, prevKey: self.prevKey, schema: self.schema, files: self.files) else {
                    do {
                        _ = try callback(FailedSQLiteDBConnection())
                        
                        deferred.fill(Maybe(failure: NSError(domain: "mozilla", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create a connection"])))
                    } catch let err as NSError {
                        deferred.fill(Maybe(failure: DatabaseError(err: err)))
                    }
                    return
            }
            
            do {
                let result = try callback(connection)
                deferred.fill(Maybe(success: result))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: DatabaseError(err: err)))
            }
        }
        
        if synchronous {
            queue.sync {
                doWork()
            }
        } else {
            queue.async {
                doWork()
            }
        }
        
        return deferred
    }

    /**
     * Helper for opening a connection, starting a transaction, and then running a block of code inside it.
     * The code block can return true if the transaction should be committed. False if we should roll back.
     */
    func transaction<T>(synchronous: Bool = false, _ transactionClosure: @escaping (_ connection: SQLiteDBConnection) throws -> T) -> Deferred<Maybe<T>> {
        return withConnection(SwiftData.Flags.readWriteCreate, synchronous: synchronous) { connection in
            try connection.transaction(transactionClosure)
        }
    }

    /// Don't use this unless you know what you're doing. The deinitializer
    /// should be used to achieve refcounting semantics.
    func forceClose() {
        sharedConnectionQueue.sync {
            self.closed = true
            self.sharedConnection = nil
        }
    }

    /// Reopens a database that had previously been force-closed.
    /// Does nothing if this database is already open.
    func reopenIfClosed() {
        sharedConnectionQueue.sync {
            self.closed = false
        }
    }

    public enum Flags {
        case readOnly
        case readWrite
        case readWriteCreate

        fileprivate func toSQL() -> Int32 {
            switch self {
            case .readOnly:
                return SQLITE_OPEN_READONLY
            case .readWrite:
                return SQLITE_OPEN_READWRITE
            case .readWriteCreate:
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
    var pointer: OpaquePointer?
    fileprivate let connection: ConcreteSQLiteDBConnection

    init(connection: ConcreteSQLiteDBConnection, query: String, args: [Any?]?) throws {
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
    fileprivate func bind(_ objects: [Any?]) -> NSError? {
        let count = Int(sqlite3_bind_parameter_count(pointer))
        if count < objects.count {
            return connection.createErr("During: Bind", status: 202)
        }
        if count > objects.count {
            return connection.createErr("During: Bind", status: 201)
        }

        for (index, obj) in objects.enumerated() {
            var status: Int32 = SQLITE_OK

            // Doubles also pass obj as Int, so order is important here.
            if obj is Double {
                status = sqlite3_bind_double(pointer, Int32(index+1), obj as! Double)
            } else if obj is Int {
                status = sqlite3_bind_int(pointer, Int32(index+1), Int32(obj as! Int))
            } else if obj is Bool {
                status = sqlite3_bind_int(pointer, Int32(index+1), (obj as! Bool) ? 1 : 0)
            } else if obj is String {
                typealias CFunction = @convention(c) (UnsafeMutableRawPointer?) -> Void
                let transient = unsafeBitCast(-1, to: CFunction.self)
                status = sqlite3_bind_text(pointer, Int32(index+1), (obj as! String).cString(using: String.Encoding.utf8)!, -1, transient)
            } else if obj is Data {
                status = sqlite3_bind_blob(pointer, Int32(index+1), ((obj as! Data) as NSData).bytes, -1, nil)
            } else if obj is Date {
                let timestamp = (obj as! Date).timeIntervalSince1970
                status = sqlite3_bind_double(pointer, Int32(index+1), timestamp)
            } else if obj is UInt64 {
                status = sqlite3_bind_double(pointer, Int32(index+1), Double(obj as! UInt64))
            } else if obj == nil {
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

public protocol SQLiteDBConnection {
    var lastInsertedRowID: Int { get }
    var numberOfRowsModified: Int { get }
    var version: Int { get }

    func executeChange(_ sqlStr: String) throws -> Void
    func executeChange(_ sqlStr: String, withArgs args: Args?) throws -> Void

    func executeQuery<T>(_ sqlStr: String, factory: @escaping ((SDRow) -> T)) -> Cursor<T>
    func executeQuery<T>(_ sqlStr: String, factory: @escaping ((SDRow) -> T), withArgs args: Args?) -> Cursor<T>
    func executeQueryUnsafe<T>(_ sqlStr: String, factory: @escaping ((SDRow) -> T), withArgs args: Args?) -> Cursor<T>

    func transaction<T>(_ transactionClosure: @escaping (_ connection: SQLiteDBConnection) throws -> T) throws -> T

    func interrupt()
    func checkpoint()
    func checkpoint(_ mode: Int32)
    func vacuum() throws -> Void
    func setVersion(_ version: Int) throws -> Void
}

// Represents a failure to open.
class FailedSQLiteDBConnection: SQLiteDBConnection {
    var lastInsertedRowID: Int = 0
    var numberOfRowsModified: Int = 0
    var version: Int = 0

    fileprivate func fail(_ str: String) -> NSError {
        return NSError(domain: "mozilla", code: 0, userInfo: [NSLocalizedDescriptionKey: str])
    }

    func executeChange(_ sqlStr: String, withArgs args: Args?) throws -> Void {
        throw fail("Non-open connection; can't execute change.")
    }
    func executeChange(_ sqlStr: String) throws -> Void {
        throw fail("Non-open connection; can't execute change.")
    }

    func executeQuery<T>(_ sqlStr: String, factory: @escaping ((SDRow) -> T)) -> Cursor<T> {
        return Cursor<T>(err: fail("Non-open connection; can't execute query."))
    }
    func executeQuery<T>(_ sqlStr: String, factory: @escaping ((SDRow) -> T), withArgs args: Args?) -> Cursor<T> {
        return Cursor<T>(err: fail("Non-open connection; can't execute query."))
    }
    func executeQueryUnsafe<T>(_ sqlStr: String, factory: @escaping ((SDRow) -> T), withArgs args: Args?) -> Cursor<T> {
        return Cursor<T>(err: fail("Non-open connection; can't execute query."))
    }

    func transaction<T>(_ transactionClosure: @escaping (_ connection: SQLiteDBConnection) throws -> T) throws -> T {
        throw fail("Non-open connection; can't start transaction.")
    }

    func interrupt() {}
    func checkpoint() {}
    func checkpoint(_ mode: Int32) {}
    func vacuum() throws -> Void {
        throw fail("Non-open connection; can't vacuum.")
    }
    func setVersion(_ version: Int) throws -> Void {
        throw fail("Non-open connection; can't set user_version.")
    }
}

open class ConcreteSQLiteDBConnection: SQLiteDBConnection {
    open var lastInsertedRowID: Int {
        return Int(sqlite3_last_insert_rowid(sqliteDB))
    }

    open var numberOfRowsModified: Int {
        return Int(sqlite3_changes(sqliteDB))
    }

    open var version: Int {
        return pragma("user_version", factory: IntFactory) ?? 0
    }

    fileprivate var sqliteDB: OpaquePointer?
    fileprivate let filename: String
    fileprivate let schema: Schema
    fileprivate let files: FileAccessor
    
    fileprivate let debug_enabled = false

    init?(filename: String, flags: Int32, key: String? = nil, prevKey: String? = nil, schema: Schema, files: FileAccessor) {
        log.debug("Opening connection to \(filename).")

        self.filename = filename
        self.schema = schema
        self.files = files
        
        func doOpen() -> Bool {
            if let failure = openWithFlags(flags) {
                log.warning("Opening connection to \(filename) failed: \(failure).")
                return false
            }

            if key == nil && prevKey == nil {
                do {
                    try self.prepareCleartext()
                } catch {
                    return false
                }
            } else {
                do {
                    try self.prepareEncrypted(flags, key: key, prevKey: prevKey)
                } catch {
                    return false
                }
            }

            return true
        }

        // If we cannot even open the database file, return `nil` to force SwiftData
        // into using a `FailedSQLiteDBConnection` so we can retry opening again later.
        if !doOpen() {
            let extra = ["filename" : filename]
            Sentry.shared.sendWithStacktrace(message: "Cannot open a database connection.", tag: SentryTag.swiftData, severity: .error, extra: extra)
            return nil
        }

        // Now that we've successfully opened a connection to the database file, call
        // `prepareSchema()`. If it succeeds, our work here is done. If it returns
        // `.failure`, this means there was a temporary error preventing us from initing
        // the schema (e.g. SQLITE_BUSY, SQLITE_LOCK, SQLITE_FULL); so we return `nil` to
        // force SwiftData into using a `FailedSQLiteDBConnection` to retry preparing the
        // schema again later. However, if it returns `.needsRecovery`, this means there
        // was a permanent error preparing the schema and we need to move the current
        // database file to a backup location and start over with a brand new one.
        switch self.prepareSchema() {
        case .success:
            log.debug("Database successfully created or updated.")
        case .failure:
            Sentry.shared.sendWithStacktrace(message: "Failed to create or update the database schema.", tag: SentryTag.swiftData, severity: .error)
            return nil
        case .needsRecovery:
            Sentry.shared.sendWithStacktrace(message: "Database schema cannot be created or updated due to an unrecoverable error.", tag: SentryTag.swiftData, severity: .error)

            // We need to close this new connection before we can move the database file to
            // its backup location. If we cannot even close the connection, something has
            // gone really wrong. In that case, bail out and return `nil` to force SwiftData
            // into using a `FailedSQLiteDBConnection` so we can retry again later.
            if let error = self.closeCustomConnection(immediately: true) {
                Sentry.shared.sendWithStacktrace(message: "Cannot close the database connection to begin recovery.", tag: SentryTag.swiftData, severity: .error, description: error.localizedDescription)
                return nil
            }

            // Move the current database file to its backup location.
            self.moveDatabaseFileToBackupLocation()

            // If we cannot open the *new* database file (which shouldn't happen), return
            // `nil` to force SwiftData into using a `FailedSQLiteDBConnection` so we can
            // retry opening again later.
            if !doOpen() {
                log.error("Cannot re-open a database connection to the new database file to begin recovery.")
                Sentry.shared.sendWithStacktrace(message: "Cannot re-open a database connection to the new database file to begin recovery.", tag: SentryTag.swiftData, severity: .error)
                return nil
            }

            // Notify the world that we re-created the database schema. This allows us to
            // reset Sync and start over in the case of corruption.
            defer {
                let baseFilename = URL(fileURLWithPath: self.filename).lastPathComponent
                NotificationCenter.default.post(name: NotificationDatabaseWasRecreated, object: baseFilename)
            }

            // Now that we've got a brand new database file, let's call `prepareSchema()` on
            // it to re-create the schema. Again, if this fails (it shouldn't), return `nil`
            // to force SwiftData into using a `FailedSQLiteDBConnection` so we can retry
            // again later.
            if self.prepareSchema() != .success {
                log.error("Cannot re-create the schema in the new database file to complete recovery.")
                Sentry.shared.sendWithStacktrace(message: "Cannot re-create the schema in the new database file to complete recovery.", tag: SentryTag.swiftData, severity: .error)
                return nil
            }
        }
    }

    deinit {
        log.debug("deinit: closing connection on thread \(Thread.current).")
        self.closeCustomConnection()
    }

    fileprivate func setKey(_ key: String?) -> NSError? {
        sqlite3_key(sqliteDB, key ?? "", Int32((key ?? "").characters.count))
        let cursor = executeQuery("SELECT count(*) FROM sqlite_master;", factory: IntFactory, withArgs: nil as Args?)
        if cursor.status != .success {
            return NSError(domain: "mozilla", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid key"])
        }
        return nil
    }

    fileprivate func reKey(_ oldKey: String?, newKey: String?) -> NSError? {
        sqlite3_key(sqliteDB, oldKey ?? "", Int32((oldKey ?? "").characters.count))
        sqlite3_rekey(sqliteDB, newKey ?? "", Int32((newKey ?? "").characters.count))
        // Check that the new key actually works
        sqlite3_key(sqliteDB, newKey ?? "", Int32((newKey ?? "").characters.count))
        let cursor = executeQuery("SELECT count(*) FROM sqlite_master;", factory: IntFactory, withArgs: nil as Args?)
        if cursor.status != .success {
            return NSError(domain: "mozilla", code: 0, userInfo: [NSLocalizedDescriptionKey: "Rekey failed"])
        }

        return nil
    }

    public func setVersion(_ version: Int) throws -> Void {
        try executeChange("PRAGMA user_version = \(version)")
    }
    
    public func interrupt() {
        log.debug("Interrupt")
        sqlite3_interrupt(sqliteDB)
    }

    fileprivate func pragma<T: Equatable>(_ pragma: String, expected: T?, factory: @escaping (SDRow) -> T, message: String) throws {
        let cursorResult = self.pragma(pragma, factory: factory)
        if cursorResult != expected {
            log.error("\(message): \(cursorResult.debugDescription), \(expected.debugDescription)")
            throw NSError(domain: "mozilla", code: 0, userInfo: [NSLocalizedDescriptionKey: "PRAGMA didn't return expected output: \(message)."])
        }
    }

    fileprivate func pragma<T>(_ pragma: String, factory: @escaping (SDRow) -> T) -> T? {
        let cursor = executeQueryUnsafe("PRAGMA \(pragma)", factory: factory, withArgs: [] as Args)
        defer { cursor.close() }
        return cursor[0]
    }

    fileprivate func prepareShared() {
        if SwiftData.EnableForeignKeys {
            let _ = pragma("foreign_keys=ON", factory: IntFactory)
        }

        // Retry queries before returning locked errors.
        sqlite3_busy_timeout(self.sqliteDB, DatabaseBusyTimeout)
    }

    fileprivate func prepareEncrypted(_ flags: Int32, key: String?, prevKey: String? = nil) throws {
        // Setting the key needs to be the first thing done with the database.
        if let _ = setKey(key) {
            if let err = closeCustomConnection(immediately: true) {
                log.error("Couldn't close connection: \(err). Failing to open.")
                throw err
            }
            if let err = openWithFlags(flags) {
                Sentry.shared.sendWithStacktrace(message: "Error opening database with flags.", tag: SentryTag.swiftData, severity: .error, description: "\(err.code), \(err)")
                throw err
            }
            if let err = reKey(prevKey, newKey: key) {
                // Note: Don't log the error here as it may contain sensitive data.
                Sentry.shared.sendWithStacktrace(message: "Unable to encrypt database.", tag: SentryTag.swiftData, severity: .error)
                throw err
            }
        }

        if SwiftData.EnableWAL {
            log.info("Enabling WAL mode.")
            try pragma("journal_mode=WAL", expected: "wal",
                       factory: StringFactory, message: "WAL journal mode set")
        }

        self.prepareShared()
    }

    fileprivate func prepareCleartext() throws {
        // If we just created the DB -- i.e., no tables have been created yet -- then
        // we can set the page size right now and save a vacuum.
        //
        // For where these values come from, see Bug 1213623.
        //
        // Note that sqlcipher uses cipher_page_size instead, but we don't set that
        // because it needs to be set from day one.

        let desiredPageSize = 32 * 1024
        let _ = pragma("page_size=\(desiredPageSize)", factory: IntFactory)

        let currentPageSize = pragma("page_size", factory: IntFactory)

        // This has to be done without WAL, so we always hop into rollback/delete journal mode.
        if currentPageSize != desiredPageSize {
            try pragma("journal_mode=DELETE", expected: "delete",
                       factory: StringFactory, message: "delete journal mode set")

            try pragma("page_size=\(desiredPageSize)", expected: nil,
                       factory: IntFactory, message: "Page size set")

            log.info("Vacuuming to alter database page size from \(currentPageSize ?? 0) to \(desiredPageSize).")

            do {
                try vacuum()
                log.debug("Vacuuming succeeded.")
            } catch let err as NSError {
                log.error("Vacuuming failed: \(err.localizedDescription).")
            }
        }

        if SwiftData.EnableWAL {
            log.info("Enabling WAL mode.")

            let desiredPagesPerJournal = 16
            let desiredCheckpointSize = desiredPagesPerJournal * desiredPageSize
            let desiredJournalSizeLimit = 3 * desiredCheckpointSize

            /*
             * With whole-module-optimization enabled in Xcode 7.2 and 7.2.1, the
             * compiler seems to eagerly discard these queries if they're simply
             * inlined, causing a crash in `pragma`.
             *
             * Hackily hold on to them.
             */
            let journalModeQuery = "journal_mode=WAL"
            let autoCheckpointQuery = "wal_autocheckpoint=\(desiredPagesPerJournal)"
            let journalSizeQuery = "journal_size_limit=\(desiredJournalSizeLimit)"

            try withExtendedLifetime(journalModeQuery, {
                try pragma(journalModeQuery, expected: "wal",
                           factory: StringFactory, message: "WAL journal mode set")
            })
            try withExtendedLifetime(autoCheckpointQuery, {
                try pragma(autoCheckpointQuery, expected: desiredPagesPerJournal,
                           factory: IntFactory, message: "WAL autocheckpoint set")
            })
            try withExtendedLifetime(journalSizeQuery, {
                try pragma(journalSizeQuery, expected: desiredJournalSizeLimit,
                           factory: IntFactory, message: "WAL journal size limit set")
            })
        }

        self.prepareShared()
    }
    
    // Creates the database schema in a new database.
    fileprivate func createSchema() -> Bool {
        log.debug("Trying to create schema \(self.schema.name) at version \(self.schema.version)")
        if !schema.create(self) {
            // If schema couldn't be created, we'll bail without setting the `PRAGMA user_version`.
            log.debug("Creation failed.")
            return false
        }
        
        do {
            try setVersion(schema.version)
        } catch let error as NSError {
            log.error("Unable to set the schema version; \(error.localizedDescription)")
        }
        
        return true
    }
    
    // Updates the database schema in an existing database.
    fileprivate func updateSchema() -> Bool {
        log.debug("Trying to update schema \(self.schema.name) from version \(self.version) to \(self.schema.version)")
        if !schema.update(self, from: self.version) {
            // If schema couldn't be updated, we'll bail without setting the `PRAGMA user_version`.
            log.debug("Updating failed.")
            return false
        }
        
        do {
            try setVersion(schema.version)
        } catch let error as NSError {
            log.error("Unable to set the schema version; \(error.localizedDescription)")
        }
        
        return true
    }

    // Drops the database schema from an existing database.
    fileprivate func dropSchema() -> Bool {
        log.debug("Trying to drop schema \(self.schema.name)")
        if !self.schema.drop(self) {
            // If schema couldn't be dropped, we'll bail without setting the `PRAGMA user_version`.
            log.debug("Dropping failed.")
            return false
        }

        do {
            try setVersion(0)
        } catch let error as NSError {
            log.error("Unable to reset the schema version; \(error.localizedDescription)")
        }

        return true
    }

    // Checks if the database schema needs created or updated and acts accordingly.
    // Calls to this function will be serialized to prevent race conditions when
    // creating or updating the schema.
    fileprivate func prepareSchema() -> SQLiteDBConnectionCreatedResult {
        Sentry.shared.addAttributes(["dbSchema.\(schema.name).version": schema.version])
        
        // Get the current schema version for the database.
        let currentVersion = self.version
        
        // If the current schema version for the database matches the specified
        // `Schema` version, no further action is necessary and we can bail out.
        // NOTE: This assumes that we always use *ONE* `Schema` per database file
        // since SQLite can only track a single value in `PRAGMA user_version`.
        if currentVersion == schema.version {
            log.debug("Schema \(self.schema.name) already exists at version \(self.schema.version). Skipping additional schema preparation.")
            return .success
        }
        
        // Set an attribute for Sentry to include with any future error/crash
        // logs to indicate what schema version we're coming from and going to.
        Sentry.shared.addAttributes(["dbUpgrade.\(self.schema.name).from": currentVersion, "dbUpgrade.\(self.schema.name).to": self.schema.version])
        
        // This should not ever happen since the schema version should always be
        // increasing whenever a structural change is made in an app update.
        guard currentVersion <= schema.version else {
            let errorString = "\(self.schema.name) cannot be downgraded from version \(currentVersion) to \(self.schema.version)."
            Sentry.shared.sendWithStacktrace(message: "Schema cannot be downgraded.", tag: SentryTag.swiftData, severity: .error, description: errorString)
            return .failure
        }
        
        log.debug("Schema \(self.schema.name) needs created or updated from version \(currentVersion) to \(self.schema.version).")

        var success = true
        
        do {
            success = try transaction { connection -> Bool in
                log.debug("Create or update \(self.schema.name) version \(self.schema.version) on \(Thread.current.description).")
                
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
                        log.debug("Schema \(self.schema.name) doesn't exist. Creating.")
                        success = self.createSchema()
                        return success
                    }
                }

                Sentry.shared.send(message: "Attempting to update schema", tag: SentryTag.swiftData, severity: .info, description: "\(currentVersion) to \(self.schema.version).")

                // If we can't create a brand new schema from scratch, we must
                // call `updateSchema()` to go through the update process.
                if self.updateSchema() {
                    log.debug("Updated schema \(self.schema.name).")
                    success = true
                    return success
                }

                // If we failed to update the schema, we'll drop everything from the DB
                // and create everything again from scratch. Assuming our schema upgrade
                // code is correct, this *shouldn't* happen. If it does, log it to Sentry.
                Sentry.shared.sendWithStacktrace(message: "Update failed for schema. Dropping and re-creating.", tag: SentryTag.swiftData, severity: .error, description: "\(self.schema.name) from version \(currentVersion) to \(self.schema.version)")

                // If we can't even drop the schema here, something has gone really wrong, so
                // return `false` which should force us into recovery.
                if !self.dropSchema() {
                    Sentry.shared.sendWithStacktrace(message: "Unable to drop schema.", tag: SentryTag.swiftData, severity: .error, description: "\(self.schema.name) from version \(currentVersion).")
                    success = false
                    return success
                }

                // Try to re-create the schema. If this fails, we are out of options and we'll
                // return `false` which should force us into recovery.
                success = self.createSchema()
                return success
            }
        } catch let error as NSError {
            // If we got an error trying to get a transaction, then we either bail out early and return
            // `.failure` if we think we can retry later or return `.needsRecovery` if the error is not
            // recoverable.
            Sentry.shared.sendWithStacktrace(message: "Unable to get a transaction", tag: SentryTag.swiftData, severity: .error, description: "\(error.localizedDescription)")

            // Check if the error we got is recoverable (e.g. SQLITE_BUSY, SQLITE_LOCK, SQLITE_FULL).
            // If so, just return `.failure` so we can retry preparing the schema again later.
            if let _ = SQLiteDBRecoverableError(rawValue: error.code) {
                return .failure
            }

            // Otherwise, this is a non-recoverable error and we return `.needsRecovery` so the database
            // file can be backed up and a new one will be created.
            return .needsRecovery
        }

        // If any of our operations inside the transaction failed, this also means we need to go through
        // the recovery process to re-create the database from scratch.
        if !success {
            return .needsRecovery
        }

        // No error means we're all good! \o/
        return .success
    }

    fileprivate func moveDatabaseFileToBackupLocation() {
        let baseFilename = URL(fileURLWithPath: filename).lastPathComponent

        // Attempt to make a backup as long as the database file still exists.
        if files.exists(baseFilename) {
            Sentry.shared.sendWithStacktrace(message: "Couldn't create or update schema. Attempted to move db to another location.", tag: SentryTag.swiftData, severity: .warning, description: "Attempting to move '\(baseFilename)' for schema '\(self.schema.name)'")
            
            // Note that a backup file might already exist! We append a counter to avoid this.
            var bakCounter = 0
            var bak: String
            repeat {
                bakCounter += 1
                bak = "\(baseFilename).bak.\(bakCounter)"
            } while files.exists(bak)
            
            do {
                try files.move(baseFilename, toRelativePath: bak)
                
                let shm = baseFilename + "-shm"
                let wal = baseFilename + "-wal"
                log.debug("Moving \(shm) and \(wal)…")
                if files.exists(shm) {
                    log.debug("\(shm) exists.")
                    try files.move(shm, toRelativePath: bak + "-shm")
                }
                if files.exists(wal) {
                    log.debug("\(wal) exists.")
                    try files.move(wal, toRelativePath: bak + "-wal")
                }
                
                log.debug("Finished moving database \(baseFilename) successfully.")
            } catch let error as NSError {
                Sentry.shared.sendWithStacktrace(message: "Unable to move db to another location", tag: SentryTag.swiftData, severity: .error, description: "DB file '\(baseFilename)'. \(error.localizedDescription)")
            }
        } else {
            // No backup was attempted since the database file did not exist.
            Sentry.shared.sendWithStacktrace(message: "The database file has been deleted while previously in use.", tag: SentryTag.swiftData, description: "DB file '\(baseFilename)'")
        }
    }
    
    public func checkpoint() {
        self.checkpoint(SQLITE_CHECKPOINT_FULL)
    }

    /**
     * Blindly attempts a WAL checkpoint on all attached databases.
     */
    public func checkpoint(_ mode: Int32) {
        guard sqliteDB != nil else {
            log.warning("Trying to checkpoint a nil DB!")
            return
        }

        log.debug("Running WAL checkpoint on \(self.filename) on thread \(Thread.current).")
        sqlite3_wal_checkpoint_v2(sqliteDB, nil, mode, nil, nil)
        log.debug("WAL checkpoint done on \(self.filename).")
    }

    public func vacuum() throws -> Void {
        try executeChange("VACUUM")
    }

    /// Creates an error from a sqlite status. Will print to the console if debug_enabled is set.
    /// Do not call this unless you're going to return this error.
    fileprivate func createErr(_ description: String, status: Int) -> NSError {
        var msg = SDError.errorMessageFromCode(status)

        if debug_enabled {
            log.debug("SwiftData Error -> \(description)")
            log.debug("                -> Code: \(status) - \(msg)")
        }

        if let errMsg = String(validatingUTF8: sqlite3_errmsg(sqliteDB)) {
            msg += " " + errMsg
            if debug_enabled {
                log.debug("                -> Details: \(errMsg)")
            }
        }

        return NSError(domain: "org.mozilla", code: status, userInfo: [NSLocalizedDescriptionKey: msg])
    }

    /// Open the connection. This is called when the db is created. You should not call it yourself.
    fileprivate func openWithFlags(_ flags: Int32) -> NSError? {
        let status = sqlite3_open_v2(filename.cString(using: String.Encoding.utf8)!, &sqliteDB, flags, nil)
        if status != SQLITE_OK {
            return createErr("During: Opening Database with Flags", status: Int(status))
        }
        return nil
    }

    /// Closes a connection. This is called via deinit. Do not call this yourself.
    @discardableResult fileprivate func closeCustomConnection(immediately: Bool = false) -> NSError? {
        log.debug("Closing custom connection for \(self.filename) on \(Thread.current).")
        // TODO: add a lock here?
        let db = self.sqliteDB
        self.sqliteDB = nil

        // Don't bother trying to call sqlite3_close multiple times.
        guard db != nil else {
            log.warning("Connection was nil.")
            return nil
        }

        var status = sqlite3_close(db)

        if status != SQLITE_OK {
            Sentry.shared.sendWithStacktrace(message: "Got error status while attempting to close.", tag: SentryTag.swiftData, severity: .error, description: "SQLite status: \(status)")

            if immediately {
                return createErr("During: closing database with flags", status: Int(status))
            }
            
            // Note that if we use sqlite3_close_v2, this will still return SQLITE_OK even if
            // there are outstanding prepared statements
            status = sqlite3_close_v2(db)
            
            if status != SQLITE_OK {
                
                // Based on the above comment regarding sqlite3_close_v2, this shouldn't happen.
                Sentry.shared.sendWithStacktrace(message: "Got error status while attempting to close_v2.", tag: SentryTag.swiftData, severity: .error, description: "SQLite status: \(status)")
                return createErr("During: closing database with flags", status: Int(status))
            }
        }

        log.debug("Closed \(self.filename).")
        return nil
    }

    open func executeChange(_ sqlStr: String) throws -> Void {
        try executeChange(sqlStr, withArgs: nil)
    }

    /// Executes a change on the database.
    open func executeChange(_ sqlStr: String, withArgs args: Args?) throws -> Void {
        var error: NSError?
        let statement: SQLiteDBStatement?
        do {
            statement = try SQLiteDBStatement(connection: self, query: sqlStr, args: args)
        } catch let error1 as NSError {
            error = error1
            statement = nil
        }

        // Close, not reset -- this isn't going to be reused.
        defer { statement?.close() }

        if let error = error {
            // Special case: Write additional info to the database log in the case of a database corruption.
            if error.code == Int(SQLITE_CORRUPT) {
                writeCorruptionInfoForDBNamed(filename, toLogger: Logger.corruptLogger)
                Sentry.shared.sendWithStacktrace(message: "SQLITE_CORRUPT", tag: SentryTag.swiftData, severity: .error, description: "DB file '\(filename)'. \(error.localizedDescription)")
            }

            let message = "Error code: \(error.code), \(error) for SQL \(String(sqlStr.characters.prefix(500)))."
            Sentry.shared.sendWithStacktrace(message: "SQL error", tag: SentryTag.swiftData, severity: .error, description: message)

            throw error
        }

        let status = sqlite3_step(statement!.pointer)

        if status != SQLITE_DONE && status != SQLITE_OK {
            throw createErr("During: SQL Step \(sqlStr)", status: Int(status))
        }
    }

    public func executeQuery<T>(_ sqlStr: String, factory: @escaping ((SDRow) -> T)) -> Cursor<T> {
        return self.executeQuery(sqlStr, factory: factory, withArgs: nil)
    }

    /// Queries the database.
    /// Returns a cursor pre-filled with the complete result set.
    public func executeQuery<T>(_ sqlStr: String, factory: @escaping ((SDRow) -> T), withArgs args: Args?) -> Cursor<T> {
        var error: NSError?
        let statement: SQLiteDBStatement?
        do {
            statement = try SQLiteDBStatement(connection: self, query: sqlStr, args: args)
        } catch let error1 as NSError {
            error = error1
            statement = nil
        }

        // Close, not reset -- this isn't going to be reused, and the FilledSQLiteCursor
        // consumes everything.
        defer { statement?.close() }

        if let error = error {
            // Special case: Write additional info to the database log in the case of a database corruption.
            if error.code == Int(SQLITE_CORRUPT) {
                writeCorruptionInfoForDBNamed(filename, toLogger: Logger.corruptLogger)
                Sentry.shared.sendWithStacktrace(message: "SQLITE_CORRUPT", tag: SentryTag.swiftData, severity: .error, description: "DB file '\(filename)'. \(error.localizedDescription)")
            }
            Sentry.shared.sendWithStacktrace(message: "SQL error", tag: SentryTag.swiftData, severity: .error, description: "Error code: \(error.code), \(error) for SQL \(String(sqlStr.characters.prefix(500))).")

            return Cursor<T>(err: error)
        }

        return FilledSQLiteCursor<T>(statement: statement!, factory: factory)
    }

    func writeCorruptionInfoForDBNamed(_ dbFilename: String, toLogger logger: XCGLogger) {
        DispatchQueue.global(qos: DispatchQoS.default.qosClass).sync {
            guard !SwiftData.corruptionLogsWritten.contains(dbFilename) else { return }

            logger.error("Corrupt DB detected! DB filename: \(dbFilename)")

            let dbFileSize = ("file://\(dbFilename)".asURL)?.allocatedFileSize() ?? 0
            logger.error("DB file size: \(dbFileSize) bytes")

            logger.error("Integrity check:")

            let args: [Any?]? = nil
            let messages = self.executeQueryUnsafe("PRAGMA integrity_check", factory: StringFactory, withArgs: args)
            defer { messages.close() }

            if messages.status == CursorStatus.success {
                for message in messages {
                    logger.error(message)
                }
                logger.error("----")
            } else {
                logger.error("Couldn't run integrity check: \(messages.statusMessage).")
            }

            // Write call stack.
            logger.error("Call stack: ")
            for message in Thread.callStackSymbols {
                logger.error(" >> \(message)")
            }
            logger.error("----")

            // Write open file handles.
            let openDescriptors = FSUtils.openFileDescriptors()
            logger.error("Open file descriptors: ")
            for (k, v) in openDescriptors {
                logger.error("  \(k): \(v)")
            }
            logger.error("----")

            SwiftData.corruptionLogsWritten.insert(dbFilename)
        }
    }

    /**
     * Queries the database.
     * Returns a live cursor that holds the query statement and database connection.
     * Instances of this class *must not* leak outside of the connection queue!
     */
    public func executeQueryUnsafe<T>(_ sqlStr: String, factory: @escaping ((SDRow) -> T), withArgs args: Args?) -> Cursor<T> {
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

    public func transaction<T>(_ transactionClosure: @escaping (_ connection: SQLiteDBConnection) throws -> T) throws -> T {
        do {
            try executeChange("BEGIN EXCLUSIVE")
        } catch let err as NSError {
            Sentry.shared.sendWithStacktrace(message: "BEGIN EXCLUSIVE failed.", tag: SentryTag.swiftData, severity: .error, description: "\(err.code), \(err)")
            throw err
        }

        var result: T

        do {
            result = try transactionClosure(self)
        } catch let err as NSError {
            log.error("Op in transaction threw an error. Rolling back.")
            Sentry.shared.sendWithStacktrace(message: "Op in transaction threw an error. Rolling back.", tag: SentryTag.swiftData, severity: .error)

            do {
                try executeChange("ROLLBACK")
            } catch let err as NSError {
                Sentry.shared.sendWithStacktrace(message: "ROLLBACK after errored op in transaction failed", tag: SentryTag.swiftData, severity: .error, description: "\(err.code), \(err)")
                throw err
            }

            throw err
        }

        log.verbose("Op in transaction succeeded. Committing.")

        do {
            try executeChange("COMMIT")
        } catch let err as NSError {
            Sentry.shared.sendWithStacktrace(message: "COMMIT failed. Rolling back.", tag: SentryTag.swiftData, severity: .error, description: "\(err.code), \(err)")

            do {
                try executeChange("ROLLBACK")
            } catch let err as NSError {
                Sentry.shared.sendWithStacktrace(message: "ROLLBACK after failed COMMIT failed.", tag: SentryTag.swiftData, severity: .error, description: "\(err.code), \(err)")
                throw err
            }

            throw err
        }

        return result
    }
}

/// Helper for queries that return a single integer result.
func IntFactory(_ row: SDRow) -> Int {
    return row[0] as! Int
}

/// Helper for queries that return a single String result.
func StringFactory(_ row: SDRow) -> String {
    return row[0] as! String
}

/// Wrapper around a statement for getting data from a row. This provides accessors for subscript indexing
/// and a generator for iterating over columns.
open class SDRow: Sequence {
    // The sqlite statement this row came from.
    fileprivate let statement: SQLiteDBStatement

    // The columns of this database. The indices of these are assumed to match the indices
    // of the statement.
    fileprivate let columnNames: [String]

    fileprivate init(statement: SQLiteDBStatement, columns: [String]) {
        self.statement = statement
        self.columnNames = columns
    }

    // Return the value at this index in the row
    fileprivate func getValue(_ index: Int) -> Any? {
        let i = Int32(index)

        let type = sqlite3_column_type(statement.pointer, i)
        var ret: Any? = nil

        switch type {
        case SQLITE_NULL:
            return nil
        case SQLITE_INTEGER:
            //Everyone expects this to be an Int. On Ints larger than 2^31 this will lose information.
            ret = Int(truncatingBitPattern: sqlite3_column_int64(statement.pointer, i))
        case SQLITE_TEXT:
            if let text = sqlite3_column_text(statement.pointer, i) {
                return String(cString: text)
            }
        case SQLITE_BLOB:
            if let blob = sqlite3_column_blob(statement.pointer, i) {
                let size = sqlite3_column_bytes(statement.pointer, i)
                ret = Data(bytes: blob, count: Int(size))
            }
        case SQLITE_FLOAT:
            ret = Double(sqlite3_column_double(statement.pointer, i))
        default:
            log.warning("SwiftData Warning -> Column: \(index) is of an unrecognized type, returning nil")
        }

        return ret
    }

    // Accessor getting column 'key' in the row
    subscript(key: Int) -> Any? {
        return getValue(key)
    }

    // Accessor getting a named column in the row. This (currently) depends on
    // the columns array passed into this Row to find the correct index.
    subscript(key: String) -> Any? {
        get {
            if let index = columnNames.index(of: key) {
                return getValue(index)
            }
            return nil
        }
    }

    // Allow iterating through the row.
    public func makeIterator() -> AnyIterator<Any> {
        let nextIndex = 0
        return AnyIterator() {
            if nextIndex < self.columnNames.count {
                return self.getValue(nextIndex)
            }
            return nil
        }
    }
}

/// Helper for pretty printing SQL (and other custom) error codes.
private struct SDError {
    fileprivate static func errorMessageFromCode(_ errorCode: Int) -> String {
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
    fileprivate init(statement: SQLiteDBStatement, factory: (SDRow) -> T) {
        let (data, status, statusMessage) = FilledSQLiteCursor.getValues(statement, factory: factory)
        super.init(data: data, status: status, statusMessage: statusMessage)
    }

    /// Return an array with the set of results and release the statement.
    fileprivate class func getValues(_ statement: SQLiteDBStatement, factory: (SDRow) -> T) -> ([T], CursorStatus, String) {
        var rows = [T]()
        var status = CursorStatus.success
        var statusMessage = "Success"
        var count = 0

        var columns = [String]()
        let columnCount = sqlite3_column_count(statement.pointer)
        for i in 0..<columnCount {
            let columnName = String(cString: sqlite3_column_name(statement.pointer, i))
            columns.append(columnName)
        }

        while true {
            let sqlStatus = sqlite3_step(statement.pointer)

            if sqlStatus != SQLITE_ROW {
                if sqlStatus != SQLITE_DONE {
                    // NOTE: By setting our status to failure here, we'll report our count as zero,
                    // regardless of how far we've read at this point.
                    status = CursorStatus.failure
                    statusMessage = SDError.errorMessageFromCode(Int(sqlStatus))
                }
                break
            }

            count += 1

            let row = SDRow(statement: statement, columns: columns)
            let result = factory(row)
            rows.append(result)
        }

        return (rows, status, statusMessage)
    }
}

/// Wrapper around a statement to help with iterating through the results.
private class LiveSQLiteCursor<T>: Cursor<T> {
    fileprivate var statement: SQLiteDBStatement!

    // Function for generating objects of type T from a row.
    fileprivate let factory: (SDRow) -> T

    // Status of the previous fetch request.
    fileprivate var sqlStatus: Int32 = 0

    // Number of rows in the database
    // XXX - When Cursor becomes an interface, this should be a normal property, but right now
    //       we can't override the Cursor getter for count with a stored property.
    fileprivate var _count: Int = 0
    override var count: Int {
        get {
            if status != .success {
                return 0
            }
            return _count
        }
    }

    fileprivate var position: Int = -1 {
        didSet {
            // If we're already there, shortcut out.
            if oldValue == position {
                return
            }

            var stepStart = oldValue

            // If we're currently somewhere in the list after this position
            // we'll have to jump back to the start.
            if position < oldValue {
                sqlite3_reset(self.statement.pointer)
                stepStart = -1
            }

            // Now step up through the list to the requested position
            for _ in stepStart..<position {
                sqlStatus = sqlite3_step(self.statement.pointer)
            }
        }
    }

    init(statement: SQLiteDBStatement, factory: @escaping (SDRow) -> T) {
        self.factory = factory
        self.statement = statement

        // The only way I know to get a count. Walk through the entire statement to see how many rows there are.
        var count = 0
        self.sqlStatus = sqlite3_step(statement.pointer)
        while self.sqlStatus != SQLITE_DONE {
            count += 1
            self.sqlStatus = sqlite3_step(statement.pointer)
        }

        sqlite3_reset(statement.pointer)
        self._count = count

        super.init(status: .success, msg: "success")
    }

    // Helper for finding all the column names in this statement.
    fileprivate lazy var columns: [String] = {
        // This untangles all of the columns and values for this row when its created
        let columnCount = sqlite3_column_count(self.statement.pointer)
        var columns = [String]()
        for i: Int32 in 0 ..< columnCount {
            let columnName = String(cString: sqlite3_column_name(self.statement.pointer, i))
            columns.append(columnName)
        }
        return columns
    }()

    override subscript(index: Int) -> T? {
        get {
            if status != .success {
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
