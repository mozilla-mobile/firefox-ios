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
            "last_modified INTEGER NOT NULL",
            "device_type TEXT",
            "form_factor TEXT",
            "os TEXT",
        ])
    }

    override func getInsertAndArgs(inout item: RemoteClient) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.GUID)
        args.append(item.name)
        args.append(NSNumber(longLong: item.lastModified))
        args.append(item.type)
        args.append(item.formFactor)
        args.append(item.operatingSystem)
        return ("INSERT INTO \(name) (guid, name, last_modified, device_type, form_factor, os) VALUES (?, ?, ?, ?, ?, ?)", args)
    }

    override func getUpdateAndArgs(inout item: RemoteClient) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.name)
        args.append(NSNumber(longLong: item.lastModified))
        args.append(item.type)
        args.append(item.formFactor)
        args.append(item.operatingSystem)
        args.append(item.GUID)
        return ("UPDATE \(name) SET name = ?, last_modified = ?, device_type = ?, form_factor = ?, os = ? WHERE guid = ?", args)
    }

    override func getDeleteAndArgs(inout item: RemoteClient?) -> (String, [AnyObject?])? {
        if let item = item {
            return ("DELETE FROM \(name) WHERE guid = ?", [item.GUID])
        } else {
            return ("DELETE FROM \(name)", [])
        }
    }

    override var factory: ((row: SDRow) -> RemoteClient)? {
        return { row -> RemoteClient in
            let item = RemoteClient(GUID: row["guid"] as String,
                name: row["name"] as String,
                lastModified: (row["last_modified"] as NSNumber).longLongValue,
                type: row["device_type"] as? String,
                formFactor: row["form_factor"] as? String,
                operatingSystem: row["os"] as? String,
                tabs: [])
            return item
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        return ("SELECT * FROM \(name) ORDER BY last_modified DESC", [])
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
            "position INTEGER",
        ])
    }

    override func getInsertAndArgs(inout item: RemoteTab) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.clientGUID)
        args.append(item.URL.absoluteString!)
        args.append(item.title)
        args.append(nil) // TODO: persist history.
        args.append(NSNumber(longLong: item.lastUsed))
        args.append(NSNumber(int: item.position))
        return ("INSERT INTO \(name) (client_guid, url, title, history, last_used, position) VALUES (?, ?, ?, ?, ?, ?)", args)
    }

    override func getUpdateAndArgs(inout item: RemoteTab) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.title)
        args.append(nil) // TODO: persist history.
        args.append(NSNumber(longLong: item.lastUsed))
        args.append(NSNumber(int: item.position))
        // Key by (client_guid, url) rather than (transient) id.
        args.append(item.clientGUID)
        args.append(item.URL.absoluteString!)
        return ("UPDATE \(name) SET title = ?, history = ?, last_used = ?, position = ? WHERE client_guid = ? AND url = ?", args)
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
            let item = RemoteTab(
                clientGUID: row["client_guid"] as String,
                URL: NSURL(string: row["url"] as String)!, // TODO: find a way to make this less dangerous.
                title: row["title"] as? String,
                history: [], // TODO: extract history.
                lastUsed: Int64((row["last_used"] as NSNumber).longLongValue),
                position: Int32((row["position"] as NSNumber).intValue)
            )
            return item
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        // Per-client chunks, each chunk in client-order.
        return ("SELECT * FROM \(name) ORDER BY client_guid DESC, position ASC", [])
    }
}
