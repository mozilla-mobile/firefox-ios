/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// A protocol for informationa about a particular table. This is used as a type to be stored by TableTable.
protocol TableInfo {
    var name: String { get }
    var version: Int { get }
}

// A wrapper class for table info coming from the TableTable. This should ever only be used internally.
class TableInfoWrapper: TableInfo {
    let name: String
    let version: Int
    init(name: String, version: Int) {
        self.name = name
        self.version = version
    }
}

/* A table in our database. Note this doesn't have to be a real table. It might be backed by a join
 * or something else interesting. */
protocol Table : TableInfo {
    typealias Type
    func create(db: SQLiteDBConnection, version: Int) -> Bool
    func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool
    func exists(db: SQLiteDBConnection) -> Bool
    func drop(db: SQLiteDBConnection) -> Bool

    func insert(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int
    func update(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int
    func delete(db: SQLiteDBConnection, item: Type?, inout err: NSError?) -> Int
    func query(db: SQLiteDBConnection, options: QueryOptions?) -> Cursor
}

// A table for holding info about other tables (also holds info about itself :)). This is used
// to let us handle table upgrades when the table is first accessed, rather than when the database
// itself is created.
class SchemaTable<T>: GenericTable<TableInfo> {
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
            return TableInfoWrapper(name: row["name"] as String, version: row["version"] as Int)
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
