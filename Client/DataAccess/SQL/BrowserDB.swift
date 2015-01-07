/* This Source Code Form is subject to the terms of the Mozilla Public
<<<<<<< HEAD
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* A table in our database. Note this doesn't have to be a real table. It might be backed by a join or something else interesting. */
protocol Table {
    func getName() -> String
    func create(db: FMDatabase, version: UInt32) -> Bool
    func updateTable(db: FMDatabase, from: UInt32, to: UInt32) -> Bool

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
        //HISTORY_TABLE: HistoryTable(),
    //]

    private func exists(table: Table) -> Bool {
        let res = db.executeQuery("SELECT name FROM sqlite_master WHERE type=? AND name=?", withArgumentsInArray: [ table.getName(), "table" ])

        if res.next() {
            return true
        }

        return false
    }

    init?(profile: Profile) {
        db = FMDatabase(path: profile.files.get(FileName))
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
                    if !table.1.updateTable(db, from: version, to: Version) {
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
=======
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* A table in our database. Note this doesn't have to be a real table. It might be backed by a join or something else interesting. */
protocol Table {
    func updateTable(db: FMDatabase, current: UInt32) -> Bool
    func create(db: FMDatabase)
    func insert<T>(db: FMDatabase, item: T?) -> Cursor
    func update<T>(db: FMDatabase, item: T?) -> Cursor
    func delete<T>(db: FMDatabase, item: T?) -> Cursor
    func query(db: FMDatabase) -> Cursor
}

/* This is a base interface into our browser db. It holds arrays of tables and handles basic creation/updating of them. */
class BrowserDB {
    private let db: FMDatabase
    private let VERSION: UInt32 = 1
    private let tables: [String: Table] = [String: Table]()
        // HISTORY_TABLE: HistoryTable(),

    init?(profile: Profile) {
        db = FMDatabase(path: profile.getFile("browser.db"))
        if (!db.open()) {
            return nil
        }

        for table in tables {
            table.1.create(db)
        }

        let version = db.userVersion() // - Crashes...
        if VERSION != version {
            db.beginTransaction()
            for table in tables {
                if !table.1.updateTable(db, current: version) {
                    // Update failed, give up!
                    db.rollback()
                    return nil
                }
            }

            db.setUserVersion(VERSION)
            db.commit()
        }
>>>>>>> 9b26069... Add a sqlite interface
    }

    deinit {
        db.close()
    }

<<<<<<< HEAD
    private func deleteAndRecreate(profile: Profile) -> Bool {
        let date = NSDate()
        let newFilename = "\(FileName).bak"

        if let file = profile.files.get(newFilename) {
            if let attrs = NSFileManager.defaultManager().attributesOfItemAtPath(file, error: nil) {
                if let creationDate = attrs[NSFileCreationDate] as? NSDate {
                    // If the old backup is less than an hour old, we just give up
                    let interval = date.timeIntervalSinceDate(creationDate)
                    if interval < 60*60 {
                        return false
                    }
                }
            }
        }

        profile.files.move(FileName, dest: newFilename)
        return createDB(profile)
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
=======
    func insert<T>(name: String, item: T) -> Cursor {
        if let table = tables[name] {
            return table.insert(db, item: item)
        }
        return Cursor(status: .Failure, msg: "Invalid table name \(name)")
    }

    func update<T>(name: String, item: T) -> Cursor {
        if let table = tables[name] {
            return table.update(db, item: item)
        }
        return Cursor(status: .Failure, msg: "Invalid table name \(name)")
    }

    func delete<T>(name: String, item: T?) -> Cursor {
        if let table = tables[name] {
            return table.delete(db, item: item)
        }
        return Cursor(status: .Failure, msg: "Invalid table name \(name)")
>>>>>>> 9b26069... Add a sqlite interface
    }

    func query(name: String) -> Cursor {
        if let table = tables[name] {
            return table.query(db)
        }
        return Cursor(status: .Failure, msg: "Invalid table name")
    }

    private let debug_enabled = false
<<<<<<< HEAD
    private func debug(err: NSError) {
        debug("\(err.code): \(err.localizedDescription)")
    }

=======
>>>>>>> 9b26069... Add a sqlite interface
    private func debug(msg: String) {
        if debug_enabled {
            println("BrowserDB: " + msg)
        }
    }
}
