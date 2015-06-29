//
//  CommandSyncTable.swift
//  Client
//
//  Created by Emily Toop on 6/29/15.
//  Copyright (c) 2015 Mozilla. All rights reserved.
//

import Shared

class CommandSyncTable<T>: GenericTable<SyncCommand> {
    override var name: String { return "commands" }
    override var version: Int { return 1 }

    override var rows: String { return join(",", [
        "guid TEXT PRIMARY KEY",
        "from_client_guid TEXT REFERENCES clients(guid)",
        "to_client_guid TEXT REFERENCES clients(guid)",
        "url TEXT",
        "title TEXT NOT NULL",
        "action TEXT NOT NULL",
        "last_used INTEGER",
        ])
    }


    override func getInsertAndArgs(inout item: SyncCommand) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.guid)
        args.append(item.fromClient)
        args.append(item.toClient)
        args.append(item.url)
        args.append(item.title)
        args.append(item.action)
        args.append(NSNumber(unsignedLongLong: item.modified))
        return ("INSERT INTO \(name) (guid, from_client_guid, to_client_guid, url, title, action, last_used) VALUES (?, ?, ?, ?, ?)", args)
    }

    override func getDeleteAndArgs(inout item: SyncCommand?) -> (String, [AnyObject?])? {
        if let item = item {
            return ("DELETE FROM \(name) WHERE guid = ?", [item.guid])
        } else {
            return ("DELETE FROM \(name)", [])
        }
    }

    override var factory: ((row: SDRow) -> SyncCommand)? {
        return { row -> SyncCommand in
            return SyncCommand(
                guid: row["guid"] as! GUID,
                fromClientGuid: row["from_client_guid"] as! String,
                toClientGuid: row["to_client_guid"] as! String,
                url: row["url"] as? String,
                title: row["title"] as! String,
                action: row["action"] as! String,
                lastUsed: (row["last_used"] as! NSNumber).unsignedLongLongValue)
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        // Per-client chunks, each chunk in client-order.
        return ("SELECT * FROM \(name) ORDER BY client_guid DESC, last_used DESC", [])
    }
}