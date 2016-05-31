/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

let TableClients = "clients"
let TableTabs = "tabs"

class RemoteClientsTable<T>: GenericTable<RemoteClient> {
    override var name: String { return TableClients }
    override var version: Int { return 1 }

    // TODO: index on guid and last_modified.
    override var rows: String { return [
            "guid TEXT PRIMARY KEY",
            "name TEXT NOT NULL",
            "modified INTEGER NOT NULL",
            "type TEXT",
            "formfactor TEXT",
            "os TEXT",
            "fxaDeviceId TEXT",
        ].joinWithSeparator(",")
    }

    // TODO: this won't work correctly with NULL fields.
    override func getInsertAndArgs(inout item: RemoteClient) -> (String, [AnyObject?])? {
        let args: Args = [
            item.guid,
            item.name,
            NSNumber(unsignedLongLong: item.modified),
            item.type,
            item.formfactor,
            item.os,
            item.fxaDeviceId,
        ]
        return ("INSERT INTO \(name) (guid, name, modified, type, formfactor, os, fxaDeviceId) VALUES (?, ?, ?, ?, ?, ?, ?)", args)
    }

    override func getUpdateAndArgs(inout item: RemoteClient) -> (String, [AnyObject?])? {
        let args: Args = [
            item.name,
            NSNumber(unsignedLongLong: item.modified),
            item.type,
            item.formfactor,
            item.os,
            item.fxaDeviceId,
            item.guid,
        ]

        return ("UPDATE \(name) SET name = ?, modified = ?, type = ?, formfactor = ?, os = ?, fxaDeviceId = ? WHERE guid = ?", args)
    }

    override func getDeleteAndArgs(inout item: RemoteClient?) -> (String, [AnyObject?])? {
        if let item = item {
            return ("DELETE FROM \(name) WHERE guid = ?", [item.guid])
        }

        return ("DELETE FROM \(name)", [])
    }

    override var factory: ((row: SDRow) -> RemoteClient)? {
        return { row -> RemoteClient in
            return RemoteClient(guid: row["guid"] as? String,
                                name: row["name"] as! String,
                                modified: (row["modified"] as! NSNumber).unsignedLongLongValue,
                                type: row["type"] as? String,
                                formfactor: row["formfactor"] as? String,
                                os: row["os"] as? String,
                                fxaDeviceId: row["fxaDeviceId"] as? String)
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        return ("SELECT * FROM \(name) ORDER BY modified DESC", [])
    }
}

class RemoteTabsTable<T>: GenericTable<RemoteTab> {
    override var name: String { return TableTabs }
    override var version: Int { return 2 }

    // TODO: index on id, client_guid, last_used, and position.
    override var rows: String { return [
            "id INTEGER PRIMARY KEY AUTOINCREMENT", // An individual tab has no GUID from Sync.
            "client_guid TEXT REFERENCES clients(guid) ON DELETE CASCADE",
            "url TEXT NOT NULL",
            "title TEXT", // TODO: NOT NULL throughout.
            "history TEXT",
            "last_used INTEGER",
        ].joinWithSeparator(",")
    }

    private static func convertHistoryToString(history: [NSURL]) -> String? {
        let historyAsStrings = optFilter(history.map { $0.absoluteString })

        let data = try! NSJSONSerialization.dataWithJSONObject(historyAsStrings, options: [])
        return NSString(data: data, encoding: NSUTF8StringEncoding) as? String
    }

    private func convertStringToHistory(history: String?) -> [NSURL] {
        if let data = history?.dataUsingEncoding(NSUTF8StringEncoding) {
            if let urlStrings = try! NSJSONSerialization.JSONObjectWithData(data, options: [NSJSONReadingOptions.AllowFragments]) as? [String] {
                return optFilter(urlStrings.map { NSURL(string: $0) })
            }
        }
        return []
    }

    override func getInsertAndArgs(inout item: RemoteTab) -> (String, [AnyObject?])? {
        let args: Args = [
            item.clientGUID,
            item.URL.absoluteString,
            item.title,
            RemoteTabsTable.convertHistoryToString(item.history),
            NSNumber(unsignedLongLong: item.lastUsed),
        ]

        return ("INSERT INTO \(name) (client_guid, url, title, history, last_used) VALUES (?, ?, ?, ?, ?)", args)
    }

    override func getUpdateAndArgs(inout item: RemoteTab) -> (String, [AnyObject?])? {
        let args: Args = [
            item.title,
            RemoteTabsTable.convertHistoryToString(item.history),
            NSNumber(unsignedLongLong: item.lastUsed),

            // Key by (client_guid, url) rather than (transient) id.
            item.clientGUID,
            item.URL.absoluteString,
        ]

        return ("UPDATE \(name) SET title = ?, history = ?, last_used = ? WHERE client_guid IS ? AND url = ?", args)
    }

    override func getDeleteAndArgs(inout item: RemoteTab?) -> (String, [AnyObject?])? {
        if let item = item {
            return ("DELETE FROM \(name) WHERE client_guid = IS AND url = ?", [item.clientGUID, item.URL.absoluteString])
        }

        return ("DELETE FROM \(name)", [])
    }

    override var factory: ((row: SDRow) -> RemoteTab)? {
        return { row -> RemoteTab in
            return RemoteTab(
                clientGUID: row["client_guid"] as? String,
                URL: NSURL(string: row["url"] as! String)!, // TODO: find a way to make this less dangerous.
                title: row["title"] as! String,
                history: self.convertStringToHistory(row["history"] as? String),
                lastUsed: row.getTimestamp("last_used")!,
                icon: nil      // TODO
            )
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        // Per-client chunks, each chunk in client-order.
        return ("SELECT * FROM \(name) WHERE client_guid IS NOT NULL ORDER BY client_guid DESC, last_used DESC", [])
    }
}
