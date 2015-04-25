/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ReadingListTable<T>: GenericTable<ReadingListItem> {
    override var name: String { return "readinglist" }
    override var version: Int { return 1 }
    override var rows: String { return
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "guid TEXT UNIQUE, " +
        "content_status TINYINT DEFAULT 0, " +
        "client_last_modified INTEGER NOT NULL, " +
        "last_modified INTEGER, " +
        "stored_on INTEGER, " +
        "added_on INTEGER, " +
        "marked_read_on INTEGER, " +
        "is_deleted TINYINT DEFAULT 0, " +
        "is_archived TINYINT DEFAULT 0, " +
        "is_unread TINYINT DEFAULT 1, " +
        "is_article TINYINT DEFAULT 0, " +
        "is_favorite TINYINT DEFAULT 0, " +
        "url TEXT NOT NULL, " +
        "title TEXT, " +
        "resolved_url TEXT, " +
        "resolved_title TEXT, " +
        "excerpt TEXT, " +
        "added_by TEXT, " +
        "marked_read_by TEXT, " +
        "word_count INTEGER DEFAULT 0, " +
        "read_position INTEGER DEFAULT 0 "
    }

    override func getInsertAndArgs(inout item: ReadingListItem) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(NSNumber(longLong: item.clientLastModified))
        args.append(item.url)
        args.append(item.title)
        args.append(item.resolvedUrl)
        args.append(item.resolvedTitle)
        // TODO: Later add more fields that the client can set / needs
        return ("INSERT INTO \(name) (client_last_modified, url, title, resolved_url, resolved_title) VALUES (?, ?,?,?,?)", args)
    }

    override func getUpdateAndArgs(inout item: ReadingListItem) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(NSNumber(longLong: Int64(NSDate().timeIntervalSince1970 * 1000.0)))
        args.append(item.url)
        args.append(item.title)
        args.append(item.resolvedUrl)
        args.append(item.resolvedTitle)
        args.append(item.isUnread)
        args.append(item.id)
        // TODO: Later add more fields that the client can set / needs
        return ("UPDATE \(name) SET client_last_modified = ?, url = ?, title = ?, resolved_url = ?, resolved_title = ?, is_unread = ? WHERE id = ?", args)
    }

    override func getDeleteAndArgs(inout item: ReadingListItem?) -> (String, [AnyObject?])? {
        if let item = item {
            return ("DELETE FROM \(name) WHERE id = ?", [item.id])
        }
        // TODO: This is really dangerous .. Accidentally pass in a nil item and *boom* all data gone
        return ("DELETE FROM \(name)", [])
    }

    override var factory: ((row: SDRow) -> ReadingListItem)? {
        return { row -> ReadingListItem in
            let item = ReadingListItem(url: row["url"] as! String, title: row["title"] as? String)
            item.id = row["id"] as? Int
            if let n = row["client_last_modified"] as? NSNumber {
                item.clientLastModified = n.longLongValue
            }
            item.guid = row["guid"] as? String
            item.isDeleted = (row["is_deleted"] as! Int) != 0
            item.isArchived = (row["is_archived"] as! Int) != 0
            item.isUnread = (row["is_unread"] as! Int) != 0
            item.isFavorite = (row["is_favorite"] as! Int) != 0
            // TODO: Later add more fields that the client can set / needs
            return item
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        // We use the filter as a primary key selector to fetch one record
        if let filter: Int = options?.filter as? Int {
            return ("SELECT id, guid, content_status,client_last_modified, last_modified, stored_on, added_on, marked_read_on, is_deleted, is_archived, is_unread, is_article, is_favorite, url, title, resolved_url, resolved_title, excerpt, added_by, marked_read_by, word_count, read_position FROM \(name) where id = ?", [filter])
        }
        // TODO: See bug 1132504
        return ("SELECT id, guid, content_status,client_last_modified, last_modified, stored_on, added_on, marked_read_on, is_deleted, is_archived, is_unread, is_article, is_favorite, url, title, resolved_url, resolved_title, excerpt, added_by, marked_read_by, word_count, read_position FROM \(name) order by id desc", [])
    }
}
