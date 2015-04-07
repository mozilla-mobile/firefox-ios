/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class RemoteClientsTable<T>: GenericTable<RemoteClient> {
    override var name: String { return "clients" }
    override var version: Int { return 1 }

    // TODO: index on guid and last_modified.
    override var rows: String { return join(",", [
            "guid TEXT PRIMARY KEY",
            "name TEXT NOT NULL",
            "modified INTEGER NOT NULL",
            "type TEXT",
            "formfactor TEXT",
            "os TEXT",
        ])
    }

    // TODO: this won't work correctly with NULL fields.
    override func getInsertAndArgs(inout item: RemoteClient) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.guid)
        args.append(item.name)
        args.append(NSNumber(unsignedLongLong: item.modified))
        args.append(item.type)
        args.append(item.formfactor)
        args.append(item.os)
        return ("INSERT INTO \(name) (guid, name, modified, type, formfactor, os) VALUES (?, ?, ?, ?, ?, ?)", args)
    }

    override func getUpdateAndArgs(inout item: RemoteClient) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.name)
        args.append(NSNumber(unsignedLongLong: item.modified))
        args.append(item.type)
        args.append(item.formfactor)
        args.append(item.os)
        args.append(item.guid)
        return ("UPDATE \(name) SET name = ?, modified = ?, type = ?, formfactor = ?, os = ? WHERE guid = ?", args)
    }

    override func getDeleteAndArgs(inout item: RemoteClient?) -> (String, [AnyObject?])? {
        if let item = item {
            return ("DELETE FROM \(name) WHERE guid = ?", [item.guid])
        } else {
            return ("DELETE FROM \(name)", [])
        }
    }

    override var factory: ((row: SDRow) -> RemoteClient)? {
        return { row -> RemoteClient in
            return RemoteClient(guid: row["guid"] as! String,
                                name: row["name"] as! String,
                                modified: (row["modified"] as! NSNumber).unsignedLongLongValue,
                                type: row["type"] as? String,
                                formfactor: row["formfactor"] as? String,
                                os: row["os"] as? String)
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        return ("SELECT * FROM \(name) ORDER BY modified DESC", [])
    }
}

class RemoteTabsTable<T>: GenericTable<RemoteTab> {
    override var name: String { return "tabs" }
    override var version: Int { return 1 }

    // TODO: index on id, client_guid, last_used, and position.
    override var rows: String { return join(",", [
            "id INTEGER PRIMARY KEY AUTOINCREMENT", // An individual tab has no GUID from Sync.
            "client_guid TEXT NOT NULL REFERENCES clients(guid) ON DELETE CASCADE",
            "url TEXT NOT NULL",
            "title TEXT", // TODO: NOT NULL throughout.
            "history TEXT",
            "last_used INTEGER",
        ])
    }

    override func getInsertAndArgs(inout item: RemoteTab) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.clientGUID)
        args.append(item.URL.absoluteString!)
        args.append(item.title)
        args.append(nil) // TODO: persist history.
        args.append(NSNumber(unsignedLongLong: item.lastUsed))
        return ("INSERT INTO \(name) (client_guid, url, title, history, last_used) VALUES (?, ?, ?, ?, ?)", args)
    }

    override func getUpdateAndArgs(inout item: RemoteTab) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.title)
        args.append(nil) // TODO: persist history.
        args.append(NSNumber(unsignedLongLong: item.lastUsed))

        // Key by (client_guid, url) rather than (transient) id.
        args.append(item.clientGUID)
        args.append(item.URL.absoluteString!)
        return ("UPDATE \(name) SET title = ?, history = ?, last_used = ? WHERE client_guid = ? AND url = ?", args)
    }

    override func getDeleteAndArgs(inout item: RemoteTab?) -> (String, [AnyObject?])? {
        if let item = item {
            return ("DELETE FROM \(name) WHERE client_guid = ? AND url = ?", [item.clientGUID, item.URL.absoluteString!])
        } else {
            return ("DELETE FROM \(name)", [])
        }
    }

    override var factory: ((row: SDRow) -> RemoteTab)? {
        return { row -> RemoteTab in
            return RemoteTab(
                clientGUID: row["client_guid"] as! String,
                URL: NSURL(string: row["url"] as! String)!, // TODO: find a way to make this less dangerous.
                title: row["title"] as? String,
                history: [], // TODO: extract history.
                lastUsed: (row["last_used"] as! NSNumber).unsignedLongLongValue
            )
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        // Per-client chunks, each chunk in client-order.
        return ("SELECT * FROM \(name) ORDER BY client_guid DESC, last_used DESC", [])
    }
}
