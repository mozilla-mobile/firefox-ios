/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

import SQLite
import Shared

class ReadingListSQLStorage: ReadingListStorage {
    var db: Database!

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
        db = Database(path)

        let items = db["items"]
        db.create(table: items, ifNotExists: true) { t in
            // Client Metadata
            t.column(ItemColumns.ClientId, primaryKey: .Autoincrement)
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
        }
    }

    func getAllRecords() -> Result<[ReadingListClientRecord]> {
        return Result(success: Array(db["items"]).map {ReadingListClientRecord(row: self.rowToDictionary($0))!})
    }

    func getNewRecords() -> Result<[ReadingListClientRecord]> {
        return Result(success: Array(db["items"].filter(ItemColumns.Id == nil)).map {ReadingListClientRecord(row: self.rowToDictionary($0))!})
    }

    func getUnreadRecords() -> Result<[ReadingListClientRecord]> {
        return Result(success: Array(db["items"].filter(ItemColumns.Unread == true)).map {ReadingListClientRecord(row: self.rowToDictionary($0))!})
    }

    func getAvailableRecords() -> Result<[ReadingListClientRecord]> {
        return Result(success: Array(db["items"].order(ItemColumns.ClientLastModified.desc)).map {ReadingListClientRecord(row: self.rowToDictionary($0))!})
    }

    func deleteRecord(record: ReadingListClientRecord) -> Result<Void> {
        let items = db["items"]
        println("Trying to delete record with id \(record.clientMetadata.id)")
        let query = items.filter(ItemColumns.ClientId == record.clientMetadata.id)
        if query.delete() > 0 {
            return Result(success: Void())
        }
        return Result(failure: ReadingListStorageError("Failed to delete"))
    }

    func deleteAllRecords() -> Result<Void> {
        let items = db["items"]
        if items.delete() >= 0 {
            return Result(success: Void())
        }
        return Result(failure: ReadingListStorageError("Failed to delete"))
    }

    func createRecordWithURL(url: String, title: String, addedBy: String) -> Result<ReadingListClientRecord> {
        let items = db["items"]
        if let id = items.insert(ItemColumns.ClientLastModified <- ReadingListNow(), ItemColumns.Url <- url, ItemColumns.Title <- title, ItemColumns.AddedBy <- addedBy) {
            if let item = items.filter(ItemColumns.ClientId == id).first {
                if let record = ReadingListClientRecord(row: rowToDictionary(item)) {
                    return Result(success: record)
                } else {
                    return Result(failure: ReadingListStorageError("Can't create RLCR from row"))
                }
            } else {
                return Result(failure: ReadingListStorageError("Can't get first item from results"))
            }
        } else {
            return Result(failure: ReadingListStorageError("Can't insert"))
        }
    }

    func getRecordWithURL(url: String) -> Result<ReadingListClientRecord?> {
        let items = db["items"]
        if let item = items.filter(ItemColumns.Url == url).first {
            if let record = ReadingListClientRecord(row: rowToDictionary(item)) {
                return Result(success: record)
            } else {
                return Result(failure: ReadingListStorageError("Can't create RLCR from row"))
            }
        } else {
            return Result(success: nil)
        }
    }

    func updateRecord(record: ReadingListClientRecord, unread: Bool) -> Result<ReadingListClientRecord?> {
        let items = db["items"]
        let query = items.filter(ItemColumns.ClientId == record.clientMetadata.id)
        if query.update(ItemColumns.Unread <- unread) > 0 {
            if let item = items.filter(ItemColumns.ClientId == record.clientMetadata.id).first {
                if let record = ReadingListClientRecord(row: rowToDictionary(item)) {
                    return Result(success: record)
                } else {
                    return Result(failure: ReadingListStorageError("Can't create RLCR from row"))
                }
            } else {
                return Result(success: nil)
            }
        }
        return Result(success: nil)
    }

    private func rowToDictionary(row: Row) -> AnyObject {
        var result = [String:AnyObject]()
        result["client_id"] = NSNumber(longLong: row.get(ItemColumns.ClientId))
        result["client_last_modified"] = NSNumber(longLong: row.get(ItemColumns.ClientLastModified))
        result["id"] = row.get(ItemColumns.Id)
        result["last_modified"] = NSNumber(longLong: row.get(ItemColumns.LastModified) ?? 0)
        result["url"] = row.get(ItemColumns.Url)
        result["title"] = row.get(ItemColumns.Title)
        result["added_by"] = row.get(ItemColumns.AddedBy)
        result["archived"] = row.get(ItemColumns.Archived)
        result["favorite"] = row.get(ItemColumns.Favorite)
        result["unread"] = row.get(ItemColumns.Unread)
        return result as NSDictionary
    }
}