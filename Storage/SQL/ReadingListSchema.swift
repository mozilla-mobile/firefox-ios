// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

private let AllTables: [String] = ["items"]

open class ReadingListSchema: Schema {
    static let DefaultVersion = 1
    private var logger: Logger

    public var name: String { return "READINGLIST" }
    public var version: Int { return ReadingListSchema.DefaultVersion }

    public init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    let itemsTableCreate = """
        CREATE TABLE IF NOT EXISTS items (
            client_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            client_last_modified INTEGER NOT NULL,
            id TEXT,
            last_modified INTEGER,
            url TEXT NOT NULL UNIQUE,
            title TEXT NOT NULL,
            added_by TEXT NOT NULL,
            archived INTEGER NOT NULL DEFAULT (0),
            favorite INTEGER NOT NULL DEFAULT (0),
            unread INTEGER NOT NULL DEFAULT (1)
        )
        """

    public func create(_ db: SQLiteDBConnection) -> Bool {
        return self.run(db, queries: [itemsTableCreate])
    }

    public func update(_ db: SQLiteDBConnection, from: Int) -> Bool {
        let to = self.version
        if from == to {
            logger.log("Skipping ReadingList schema update from \(from) to \(to).",
                       level: .debug,
                       category: .storage)
            return true
        }

        if from < 1 && to >= 1 {
            logger.log("Updating ReadingList database schema from \(from) to \(to).",
                       level: .debug,
                       category: .storage)
            return self.run(db, queries: [itemsTableCreate])
        }

        logger.log("Dropping and re-creating ReadingList database schema from \(from) to \(to).",
                   level: .debug,
                   category: .storage)
        return drop(db) && create(db)
    }

    public func drop(_ db: SQLiteDBConnection) -> Bool {
        logger.log("Dropping ReadingList database.",
                   level: .debug,
                   category: .storage)
        let tables = AllTables.map { "DROP TABLE IF EXISTS \($0)" }
        let queries = Array([tables].joined())
        return self.run(db, queries: queries)
    }

    func run(_ db: SQLiteDBConnection, sql: String, args: Args? = nil) -> Bool {
        do {
            try db.executeChange(sql, withArgs: args)
        } catch let err as NSError {
            logger.log("Error running SQL in ReadingListSchema: \(err.localizedDescription) with \(sql)",
                       level: .warning,
                       category: .storage)
            return false
        }
        return true
    }

    func run(_ db: SQLiteDBConnection, queries: [String]) -> Bool {
        for sql in queries where !run(db, sql: sql, args: nil) {
            return false
        }
        return true
    }
}
