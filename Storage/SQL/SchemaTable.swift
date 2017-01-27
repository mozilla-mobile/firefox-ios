/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// A table for holding info about other tables (also holds info about itself :)). This is used
// to let us handle table upgrades when the table is first accessed, rather than when the database
// itself is created.
class SchemaTable: GenericTable<TableInfo> {
    override var name: String { return "tableList" }
    override var version: Int { return 1 }

    override var rows: String { return "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "name TEXT NOT NULL UNIQUE, " +
        "version INTEGER NOT NULL" }

    override func getInsertAndArgs(_ item: inout TableInfo) -> (String, Args)? {
        var args = Args()
        args.append(item.name as String )
        args.append(item.version  )
        return ("INSERT INTO \(name) (name, version) VALUES (?,?)", args)
    }

    override func getUpdateAndArgs(_ item: inout TableInfo) -> (String, Args)? {
        var args = Args()
        args.append(item.version  )
        args.append(item.name  as String )
        return ("UPDATE \(name) SET version = ? WHERE name = ?", args)
    }

    override func getDeleteAndArgs(_ item: inout TableInfo?) -> (String, Args)? {
        var args = Args()
        var sql = "DELETE FROM \(name)"
        if let table = item {
            args.append(table.name as String )
            sql += " WHERE name = ?"
        }
        return (sql, args)
    }

    override var factory: ((_ row: SDRow) -> TableInfo)? {
        return { row -> TableInfo in
            return TableInfoWrapper(name: row["name"] as! String, version: row["version"] as! Int)
        }
    }

    override func getQueryAndArgs(_ options: QueryOptions?) -> (String, Args)? {
        var args = Args()
        if let filter: Any = options?.filter {
            args.append(filter)
            return ("SELECT name, version FROM \(name) WHERE name = ?", args)
        }
        return ("SELECT name, version FROM \(name)", args)
    }
}
