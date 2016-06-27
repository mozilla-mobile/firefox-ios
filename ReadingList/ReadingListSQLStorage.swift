/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

import SQLite
import Shared

class ReadingListSQLStorage: ReadingListStorage {
    var db: Connection!
    let items: Table!
    struct ItemColumns {
        // Client Metadata
        static let ClientId = Expression<Int64>("client_id")
        static let ClientLastModified = Expression<Int64>("client_last_modified")
        // Server Metadata
        static let Id = Expression<String?>("id")
        static let LastModified = Expression<Int64?>("last_modified")
        // Properties
        static let Url = Expression<String>("url")
        static let Title = Expression<String>("title")
        static let AddedBy = Expression<String>("added_by")
        static let Archived = Expression<Bool>("archived")
        static let Favorite = Expression<Bool>("favorite")
        static let Unread = Expression<Bool>("unread")
    }

    init(path: String) {
        db = try! Connection(path)

        items = Table("items")
        do {
            try db.run(items.create(temporary: false, ifNotExists: true, block: { t in
                // Client Metadata
                t.column(ItemColumns.ClientId, primaryKey: .autoincrement)
                t.column(ItemColumns.ClientLastModified)
                // Server Metadata
                t.column(ItemColumns.Id) // TODO Unique but may be null?
                t.column(ItemColumns.LastModified)
                // Properties
                t.column(ItemColumns.Url, unique: true)
                t.column(ItemColumns.Title)
                t.column(ItemColumns.AddedBy)
                t.column(ItemColumns.Archived, defaultValue: false)
                t.column(ItemColumns.Favorite, defaultValue: false)
                t.column(ItemColumns.Unread, defaultValue: true)
            }))
        } catch {
            print("Unable to create items database '\(error)")
        }
    }

    func getAllRecords() -> Maybe<[ReadingListClientRecord]> {
        return Maybe(success: Array(db.prepare(items)).map {ReadingListClientRecord(row: self.rowToDictionary($0))!})
    }

    func getNewRecords() -> Maybe<[ReadingListClientRecord]> {
        return Maybe(success: Array(db.prepare(items.filter(ItemColumns.Id == nil))).map {ReadingListClientRecord(row: self.rowToDictionary($0))!})
    }

    func getUnreadRecords() -> Maybe<[ReadingListClientRecord]> {
        return Maybe(success: Array(db.prepare(items.filter(ItemColumns.Unread == true))).map {ReadingListClientRecord(row: self.rowToDictionary($0))!})
    }

    func getAvailableRecords() -> Maybe<[ReadingListClientRecord]> {
        return Maybe(success: Array(db.prepare(items.order(ItemColumns.ClientLastModified.desc))).map {ReadingListClientRecord(row: self.rowToDictionary($0))!})
    }

    func deleteRecord(_ record: ReadingListClientRecord) -> Maybe<Void> {
        print("Trying to delete record with id \(record.clientMetadata.id)\n")
        let query = items.filter(ItemColumns.ClientId == record.clientMetadata.id)
        do {
            try db.run(query.delete())
            return Maybe(success: Void())
        } catch {
            return Maybe(failure: ReadingListStorageError("Failed to delete"))
        }
    }

    func deleteAllRecords() -> Maybe<Void> {
        do {
            try db.run(self.items.delete())
            return Maybe(success: Void())
        } catch {
            return Maybe(failure: ReadingListStorageError("Failed to delete"))
        }
    }

    func createRecordWithURL(_ url: String, title: String, addedBy: String) -> Maybe<ReadingListClientRecord> {
        let insert = items.insert(ItemColumns.ClientLastModified <- ReadingListNow(), ItemColumns.Url <- url, ItemColumns.Title <- title, ItemColumns.AddedBy <- addedBy)

        do {
            let id = try db.run(insert)
            if let item = Array(db.prepare(items.filter(ItemColumns.ClientId == id))).first {
                if let record = ReadingListClientRecord(row: rowToDictionary(item)) {
                    return Maybe(success: record)
                } else {
                    return Maybe(failure: ReadingListStorageError("Can't create RLCR from row"))
                }
            } else {
                return Maybe(failure: ReadingListStorageError("Can't get first item from results"))
            }
        } catch {
            return Maybe(failure: ReadingListStorageError("Can't insert: \(error)"))
        }
    }

    func getRecordWithURL(_ url: String) -> Maybe<ReadingListClientRecord?> {
        if let item = Array(db.prepare(items.filter(ItemColumns.Url == url))).first {
            if let record = ReadingListClientRecord(row: rowToDictionary(item)) {
                return Maybe(success: record)
            } else {
                return Maybe(failure: ReadingListStorageError("Can't create RLCR from row"))
            }
        } else {
            return Maybe(success: nil)
        }
    }

    func updateRecord(_ record: ReadingListClientRecord, unread: Bool) -> Maybe<ReadingListClientRecord?> {
        let query = items.filter(ItemColumns.ClientId == record.clientMetadata.id).update(ItemColumns.Unread <- unread)
        do {
            try db.run(query)
            if let item = Array(db.prepare(items.filter(ItemColumns.ClientId == record.clientMetadata.id))).first {
                if let record = ReadingListClientRecord(row: rowToDictionary(item)) {
                    return Maybe(success: record)
                } else {
                    return Maybe(failure: ReadingListStorageError("Can't create RLCR from row"))
                }
            } else {
                return Maybe(success: nil)
            }
        } catch {
            return Maybe(success: nil)
        }
    }

    private func rowToDictionary(_ row: Row) -> AnyObject {
        var result = [String:AnyObject]()
        result["client_id"] = NSNumber(value: row.get(ItemColumns.ClientId))
        result["client_last_modified"] = NSNumber(value: row.get(ItemColumns.ClientLastModified))
        result["id"] = row.get(ItemColumns.Id)
        result["last_modified"] = NSNumber(value: row.get(ItemColumns.LastModified) ?? 0)
        result["url"] = row.get(ItemColumns.Url)
        result["title"] = row.get(ItemColumns.Title)
        result["added_by"] = row.get(ItemColumns.AddedBy)
        result["archived"] = row.get(ItemColumns.Archived)
        result["favorite"] = row.get(ItemColumns.Favorite)
        result["unread"] = row.get(ItemColumns.Unread)
        return result as NSDictionary
    }
}
