// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

public typealias Args = [Any?]

open class BrowserDB {
    fileprivate let db: SwiftData
    private var logger: Logger

    public let databasePath: String

    // SQLITE_MAX_VARIABLE_NUMBER = 999 by default. This controls how many ?s can
    // appear in a query string.
    public static let MaxVariableNumber = 999

    public init(filename: String,
                schema: Schema,
                files: FileAccessor,
                logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        logger.log("Initializing BrowserDB: \(filename).",
                   level: .debug,
                   category: .storage)

        do {
            let directory = try files.getAndEnsureDirectory()
            self.databasePath = URL(fileURLWithPath: directory).appendingPathComponent(filename).path

            self.db = SwiftData(filename: self.databasePath, schema: schema, files: files)
        } catch {
            logger.log("Could not create directory at root path: \(error)",
                       level: .fatal,
                       category: .storage)
            fatalError("Could not create directory at root path: \(error)")
        }
    }

    /*
     * Opening a WAL-using database with a hot journal cannot complete in read-only mode.
     * The supported mechanism for a read-only query against a WAL-using SQLite database is to use PRAGMA query_only,
     * but this isn't all that useful for us, because we have a mixed read/write workload.
     */
    @discardableResult
    func withConnection<T>(
        flags: SwiftData.Flags = .readWriteCreate,
        _ callback: @escaping (_ connection: SQLiteDBConnection) throws -> T
    ) -> Deferred<Maybe<T>> {
        return db.withConnection(flags, callback)
    }

    func transaction<T>(_ callback: @escaping (_ connection: SQLiteDBConnection) throws -> T) -> Deferred<Maybe<T>> {
        return db.transaction(callback)
    }

    public class func varlist(_ count: Int) -> String {
        return "(" + Array(repeating: "?", count: count).joined(separator: ", ") + ")"
    }

    public func forceClose() {
        db.forceClose()
    }

    public func reopenIfClosed() {
        db.reopenIfClosed()
    }

    public func run(_ sql: String, withArgs args: Args? = nil) -> Success {
        return run([(sql, args)])
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

        return transaction { connection in
            for (sql, args) in commands {
                try connection.executeChange(sql, withArgs: args)
            }
        }
    }

    public func runQuery<T>(_ sql: String, args: Args?, factory: @escaping (SDRow) -> T) -> Deferred<Maybe<Cursor<T>>> {
        return withConnection { connection -> Cursor<T> in
            connection.executeQuery(sql, factory: factory, withArgs: args)
        }
    }

    public func runQueryConcurrently<T>(
        _ sql: String,
        args: Args?,
        factory: @escaping (SDRow) -> T
    ) -> Deferred<Maybe<Cursor<T>>> {
        return withConnection(flags: .readOnly) { connection -> Cursor<T> in
            connection.executeQuery(sql, factory: factory, withArgs: args)
        }
    }

    func queryReturnsResults(_ sql: String, args: Args? = nil) -> Deferred<Maybe<Bool>> {
        return runQuery(sql, args: args, factory: { _ in true })
         >>== { deferMaybe($0[0] ?? false) }
    }
}

/// The sqlite-backed implementation of the history protocol.
/// Currently only supports pinned sites and favicons
open class BrowserDBSQLite {
    let database: BrowserDB
    let prefs: Prefs
    let notificationCenter: NotificationCenter

    public required init(database: BrowserDB,
                         prefs: Prefs,
                         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.database = database
        self.prefs = prefs
        self.notificationCenter = notificationCenter
    }
}
