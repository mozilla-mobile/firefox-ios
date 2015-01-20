/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class GenericTable: Table {
    // Implementors need override these methods
    let debug_enabled = false
    var name: String { return "" }
    var rows: String { return "" }

    func getInsertAndArgs<T>(item: T) -> (String?, [AnyObject?]) {
        return (nil, [String]())
    }

    func getUpdateAndArgs<T>(item: T) -> (String?, [AnyObject?]) {
        return (nil, [String]())
    }

    func getDeleteAndArgs<T>(item: T?) -> (String?, [AnyObject?]) {
        return (nil, [String]())
    }

    func factory(result: SDRow) -> AnyObject? {
        return nil
    }

    func getQueryAndArgs(filter: String?) -> (String?, [AnyObject?]) {
        return (nil, [String]())
    }

    // Here's the real implementation
    func debug(msg: String) {
        if debug_enabled {
            println("GenericTable: \(msg)")
        }
    }

    func create(db: SQLiteDBConnection, version: Int) -> Bool {
        db.executeChange("CREATE TABLE IF NOT EXISTS \(name) (\(rows))")
        return true
    }

    func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool {
        debug("Update table \(name) from \(from) to \(to)")
        return false
    }

    func insert<T>(db: SQLiteDBConnection, item: T?, inout err: NSError?) -> Int {
        debug("Insert into \(name) \(item)")
        if let site = item {
            let (query, args) = getInsertAndArgs(site)
            if let query = query {
                if let error = db.executeChange(query, withArgs: args) {
                    err = error
                    return -1
                }

                return db.lastInsertedRowID
            }
        }

        err = NSError(domain: "mozilla.org", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "Tried to save something that isn't a site"
        ])
        return -1
    }

    func update<T>(db: SQLiteDBConnection, item: T?, inout err: NSError?) -> Int {
        debug("Update into \(name) \(item)")
        if let site = item {
            let (query, args) = getUpdateAndArgs(site)
            if let query = query {
                if let error = db.executeChange(query, withArgs: args) {
                    println(error.description)
                    err = error
                    return 0
                }

                return db.numberOfRowsModified
            }
        }

        err = NSError(domain: "mozilla.org", code: 0, userInfo: [
            NSLocalizedDescriptionKey: "Tried to save something that isn't a site"
            ])
        return 0
    }

    func delete<T>(db: SQLiteDBConnection, item: T?, inout err: NSError?) -> Int {
        debug("Delete from \(name) \(item)")
        var numDeleted: Int = 0

        let (query, args) = getDeleteAndArgs(item);
        if let query = query {
            if let error = db.executeChange(query, withArgs: args) {
                println(error.description)
                err = error
                return 0
            }

            return db.numberOfRowsModified
        }
        return 0
    }

    func query(db: SQLiteDBConnection, filter: String? = nil) -> Cursor {
        debug("Query \(name)")
        let (query, args) = getQueryAndArgs(filter)
        if let query = query {
            return db.executeQuery(query, factory: self.factory, withArgs: args)
        }
        return Cursor(status: CursorStatus.Failure, msg: "Invalid query: \(filter)")
    }
}
