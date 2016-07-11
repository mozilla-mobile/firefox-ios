/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

let TableSyncCommands = "commands"

class SyncCommandsTable<T>: GenericTable<SyncCommand> {
    override var name: String { return TableSyncCommands }
    override var version: Int { return 1 }

    override var rows: String { return [
        "id INTEGER PRIMARY KEY AUTOINCREMENT",
        "client_guid TEXT NOT NULL",
        "value TEXT NOT NULL",
        ].joined(separator: ",")
    }


    override func getInsertAndArgs(_ item: inout SyncCommand) -> (String, [AnyObject?])? {
        let args: [AnyObject?] = [item.clientGUID!, item.value]
        return ("INSERT INTO \(name) (client_guid, value) VALUES (?, ?)", args)
    }

    override func getDeleteAndArgs(_ item: inout SyncCommand?) -> (String, [AnyObject?])? {
        if let item = item {
            return ("DELETE FROM \(name) WHERE client_guid = ?", [item.clientGUID!])
        }
        return ("DELETE FROM \(name)", [])
    }

    override var factory: ((row: SDRow) -> SyncCommand)? {
        return { row -> SyncCommand in
            return SyncCommand(
                id: row["command_id"] as? Int,
                value: row["value"] as! String,
                clientGUID: row["client_guid"] as? GUID)
        }
    }

    override func getQueryAndArgs(_ options: QueryOptions?) -> (String, [AnyObject?])? {
        let sql = "SELECT * FROM \(name)"
        if let opts = options,
            let filter: AnyObject = options?.filter {
                let args: [AnyObject?] = ["\(filter)"]
                switch opts.filterType {
                case .guid :
                    return (sql + " WHERE client_guid = ?", args)
                case .id:
                    return (sql + " WHERE id = ?", args)
                default:
                    break
            }
        }
        return (sql, [])
    }
}
