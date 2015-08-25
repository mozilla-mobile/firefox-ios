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

    override func getInsertAndArgs(inout item: TableInfo) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.name)
        args.append(item.version)
        return ("INSERT INTO \(name) (name, version) VALUES (?,?)", args)
    }

    override func getUpdateAndArgs(inout item: TableInfo) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.version)
        args.append(item.name)
        return ("UPDATE \(name) SET version = ? WHERE name = ?", args)
    }

    override func getDeleteAndArgs(inout item: TableInfo?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        var sql = "DELETE FROM \(name)"
        if let table = item {
            args.append(table.name)
            sql += " WHERE name = ?"
        }
        return (sql, args)
    }

    override var factory: ((row: SDRow) -> TableInfo)? {
        return { row -> TableInfo in
            return TableInfoWrapper(name: row["name"] as! String, version: row["version"] as! Int)
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let filter: AnyObject = options?.filter {
            args.append(filter)
            return ("SELECT name, version FROM \(name) WHERE name = ?", args)
        }
        return ("SELECT name, version FROM \(name)", args)
    }
}
