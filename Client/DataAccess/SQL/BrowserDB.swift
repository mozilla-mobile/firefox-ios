/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* A table in our database. Note this doesn't have to be a real table. It might be backed by a join or something else interesting. */
protocol Table {
    func getName() -> String
    func create(db: FMDatabase, version: UInt32) -> Bool
    func updateTable(db: FMDatabase, currentVersion: UInt32) -> Bool

    func insert<T>(db: FMDatabase, item: T?, inout err: NSError?) -> Int64
    func update<T>(db: FMDatabase, item: T?, inout err: NSError?) -> Int32
    func delete<T>(db: FMDatabase, item: T?, inout err: NSError?) -> Int32
    func query(db: FMDatabase) -> Cursor
}

let DBCouldNotOpenErrorCode = 200

/* This is a base interface into our browser db. It holds arrays of tables and handles basic creation/updating of them. */
class BrowserDB {
    private let db: FMDatabase
    private let Version: UInt32 = 1
    private let FileName = "browser.db"
    private let tables: [String: Table] = [String: Table]()
        // HISTORY_TABLE: HistoryTable(),
    // ]

    private func exists(table: Table) -> Bool {
        let res = db.executeQuery("SELECT name FROM sqlite_master WHERE type=? AND name=?", withArgumentsInArray: [ table.getName(), "table" ])

        if res.next() {
            return true
        }

        return false
    }

    init?(profile: Profile) {
        db = FMDatabase(path: FileName) // profile.getFile("browser.db"))
        if (!db.open()) {
            debug("Could not open database (\(db.lastErrorMessage()))")
            return nil
        }

        if !createDB(profile) {
            if !deleteAndRecreate(profile) {
                return nil
            }
        }

    }

    private func createDB(profile: Profile) -> Bool {
        let version = db.userVersion() // - Crashes...
        if Version != version {
            db.beginTransaction()
            for table in tables {
                // If it doesn't exist create it
                if !exists(table.1) {
                    if !table.1.create(db, version: Version) {
                        db.rollback()
                        return false
                    }
                } else {
                    if !table.1.updateTable(db, currentVersion: version) {
                        // Update failed, give up!
                        db.rollback()
                        return false
                    }
                }
            }

            db.setUserVersion(Version)
            db.commit()
        }
        return true
    }

    deinit {
        db.close()
    }

    private func deleteAndRecreate(profile: Profile) -> Bool {
        // No op for now
        return false
    }

    func insert<T>(name: String, item: T, inout err: NSError?) -> Int64 {
        if let table = tables[name] {
            let res = table.insert(db, item: item, err: &err)
            if err != nil {
                debug(err!)
            }
            return res
        }
        return 0
    }

    func update<T>(name: String, item: T, inout err: NSError?) -> Int32 {
        if let table = tables[name] {
            let res = table.update(db, item: item, err: &err)
            if err != nil {
                debug(err!)
            }
            return res
        }
        return 0
    }

    func delete<T>(name: String, item: T?, inout err: NSError?) -> Int32 {
        if let table = tables[name] {
            let res = table.delete(db, item: item, err: &err)
            if err != nil {
                debug(err!)
            }
            return res
        }
        return 0
    }

    func query(name: String) -> Cursor {
        if let table = tables[name] {
            return table.query(db)
        }
        return Cursor(status: .Failure, msg: "Invalid table name")
    }

    private let debug_enabled = false
    private func debug(err: NSError) {
        debug("\(err.code): \(err.localizedDescription)")
    }

    private func debug(msg: String) {
        if debug_enabled {
            println("BrowserDB: " + msg)
        }
    }
}
