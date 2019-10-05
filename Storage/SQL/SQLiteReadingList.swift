/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.syncLogger

class ReadingListStorageError: MaybeErrorType {
    var message: String
    init(_ message: String) {
        self.message = message
    }
    var description: String {
        return message
    }
}

open class SQLiteReadingList {
    let db: BrowserDB

    let allColumns = ["client_id", "client_last_modified", "id", "last_modified", "url", "title", "added_by", "archived", "favorite", "unread"].joined(separator: ",")

    required public init(db: BrowserDB) {
        self.db = db
    }
}

extension SQLiteReadingList: ReadingList {
    public func getAvailableRecords() -> Deferred<Maybe<[ReadingListItem]>> {
        let sql = "SELECT \(allColumns) FROM items ORDER BY client_last_modified DESC"
        return db.runQuery(sql, args: nil, factory: SQLiteReadingList.ReadingListItemFactory) >>== { cursor in
            return deferMaybe(cursor.asArray())
        }
    }

    public func deleteRecord(_ record: ReadingListItem) -> Success {
        let sql = "DELETE FROM items WHERE client_id = ?"
        let args: Args = [record.id]
        return db.run(sql, withArgs: args)
    }

    public func deleteAllRecords() -> Success {
        let sql = "DELETE FROM items"
        return db.run(sql)
    }

    public func createRecordWithURL(_ url: String, title: String, addedBy: String) -> Deferred<Maybe<ReadingListItem>> {
        return db.transaction { connection -> ReadingListItem in
            let insertSQL = "INSERT OR REPLACE INTO items (client_last_modified, url, title, added_by) VALUES (?, ?, ?, ?)"
            let insertArgs: Args = [ReadingListNow(), url, title, addedBy]
            let lastInsertedRowID = connection.lastInsertedRowID

            try connection.executeChange(insertSQL, withArgs: insertArgs)

            if connection.lastInsertedRowID == lastInsertedRowID {
                throw ReadingListStorageError("Unable to insert ReadingListItem")
            }

            let querySQL = "SELECT \(self.allColumns) FROM items WHERE client_id = ? LIMIT 1"
            let queryArgs: Args = [connection.lastInsertedRowID]

            let cursor = connection.executeQuery(querySQL, factory: SQLiteReadingList.ReadingListItemFactory, withArgs: queryArgs)

            let items = cursor.asArray()
            if let item = items.first {
                return item
            } else {
                throw ReadingListStorageError("Unable to get inserted ReadingListItem")
            }
        }
    }

    public func getRecordWithURL(_ url: String) -> Deferred<Maybe<ReadingListItem>> {
        let sql = "SELECT \(allColumns) FROM items WHERE url = ? LIMIT 1"
        let args: Args = [url]
        return db.runQuery(sql, args: args, factory: SQLiteReadingList.ReadingListItemFactory) >>== { cursor in
            let items = cursor.asArray()
            if let item = items.first {
                return deferMaybe(item)
            } else {
                return deferMaybe(ReadingListStorageError("Can't create RLCR from row"))
            }
        }
    }

    public func updateRecord(_ record: ReadingListItem, unread: Bool) -> Deferred<Maybe<ReadingListItem>> {
        return db.transaction { connection -> ReadingListItem in
            let updateSQL = "UPDATE items SET unread = ? WHERE client_id = ?"
            let updateArgs: Args = [unread, record.id]

            try connection.executeChange(updateSQL, withArgs: updateArgs)

            let querySQL = "SELECT \(self.allColumns) FROM items WHERE client_id = ? LIMIT 1"
            let queryArgs: Args = [record.id]

            let cursor = connection.executeQuery(querySQL, factory: SQLiteReadingList.ReadingListItemFactory, withArgs: queryArgs)

            let items = cursor.asArray()
            if let item = items.first {
                return item
            } else {
                throw ReadingListStorageError("Unable to get updated ReadingListItem")
            }
        }
    }

    fileprivate class func ReadingListItemFactory(_ row: SDRow) -> ReadingListItem {
        let id = row["client_id"] as! Int
        let lastModified = row.getTimestamp("client_last_modified")!
        let url = row["url"] as! String
        let title = row["title"] as! String
        let addedBy = row["added_by"] as! String
        let archived = row.getBoolean("archived")
        let unread = row.getBoolean("unread")
        let favorite = row.getBoolean("favorite")
        return ReadingListItem(id: id, lastModified: lastModified, url: url, title: title, addedBy: addedBy, unread: unread, archived: archived, favorite: favorite)
    }
}
