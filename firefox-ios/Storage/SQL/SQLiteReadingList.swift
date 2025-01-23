// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

public class ReadingListStorageError: MaybeErrorType {
    var message: String
    public init(_ message: String) {
        self.message = message
    }
    public var description: String {
        return message
    }
}

open class SQLiteReadingList {
    let db: BrowserDB

    let allColumns = [
        "client_id",
        "client_last_modified",
        "id",
        "last_modified",
        "url",
        "title",
        "added_by",
        "archived",
        "favorite",
        "unread"
    ].joined(separator: ",")
    let notificationCenter: NotificationCenter

    public required init(db: BrowserDB,
                         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.db = db
        self.notificationCenter = notificationCenter
    }
}

extension SQLiteReadingList: ReadingList {
    public func getAvailableRecords(completion: @escaping ([ReadingListItem]) -> Void) {
        let sql = "SELECT \(allColumns) FROM items ORDER BY client_last_modified DESC"
        let deferredResponse = db.runQuery(
            sql,
            args: nil,
            factory: SQLiteReadingList.ReadingListItemFactory
        ) >>== { cursor in
            return deferMaybe(cursor.asArray())
        }

        deferredResponse.upon { result in
            completion(result.successValue ?? [])
        }
    }

    public func getAvailableRecords() -> Deferred<Maybe<[ReadingListItem]>> {
        let sql = "SELECT \(allColumns) FROM items ORDER BY client_last_modified DESC"
        return db.runQuery(sql, args: nil, factory: SQLiteReadingList.ReadingListItemFactory) >>== { cursor in
            return deferMaybe(cursor.asArray())
        }
    }

    public func deleteRecord(_ record: ReadingListItem, completion: ((Bool) -> Void)? = nil) {
        let sql = "DELETE FROM items WHERE client_id = ?"
        let args: Args = [record.id]
        let deferredResponse = db.run(sql, withArgs: args)

        deferredResponse.upon { result in
            self.notificationCenter.post(name: .ReadingListUpdated, object: self)
            completion?(result.isSuccess)
        }
    }

    public func createRecordWithURL(_ url: String, title: String, addedBy: String) -> Deferred<Maybe<ReadingListItem>> {
        return db.transaction { connection -> ReadingListItem in
            // swiftlint:disable line_length
            let insertSQL = "INSERT OR REPLACE INTO items (client_last_modified, url, title, added_by) VALUES (?, ?, ?, ?)"
            // swiftlint:enable line_length
            let insertArgs: Args = [ReadingListNow(), url, title, addedBy]
            let lastInsertedRowID = connection.lastInsertedRowID

            try connection.executeChange(insertSQL, withArgs: insertArgs)

            if connection.lastInsertedRowID == lastInsertedRowID {
                throw ReadingListStorageError("Unable to insert ReadingListItem")
            }

            let querySQL = "SELECT \(self.allColumns) FROM items WHERE client_id = ? LIMIT 1"
            let queryArgs: Args = [connection.lastInsertedRowID]

            let cursor = connection.executeQuery(
                querySQL,
                factory: SQLiteReadingList.ReadingListItemFactory,
                withArgs: queryArgs
            )

            let items = cursor.asArray()
            if let item = items.first {
                self.notificationCenter.post(name: .ReadingListUpdated, object: self)
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

            let cursor = connection.executeQuery(
                querySQL,
                factory: SQLiteReadingList.ReadingListItemFactory,
                withArgs: queryArgs
            )

            let items = cursor.asArray()
            if let item = items.first {
                self.notificationCenter.post(name: .ReadingListUpdated, object: self)
                return item
            } else {
                throw ReadingListStorageError("Unable to get updated ReadingListItem")
            }
        }
    }

    fileprivate class func ReadingListItemFactory(_ row: SDRow) -> ReadingListItem {
        guard let id = row["client_id"] as? Int,
              let url = row["url"] as? String,
              let title = row["title"] as? String,
              let addedBy = row["added_by"] as? String else {
            return ReadingListItem(
                id: 0,
                lastModified: 0,
                url: "",
                title: "",
                addedBy: "",
                unread: false,
                archived: false,
                favorite: false
            )
        }
        let lastModified = row.getTimestamp("client_last_modified")!
        let archived = row.getBoolean("archived")
        let unread = row.getBoolean("unread")
        let favorite = row.getBoolean("favorite")
        return ReadingListItem(
            id: id,
            lastModified: lastModified,
            url: url,
            title: title,
            addedBy: addedBy,
            unread: unread,
            archived: archived,
            favorite: favorite
        )
    }
}
