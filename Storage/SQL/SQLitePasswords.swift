/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private class PasswordsTable<T>: GenericTable<Password> {
    override var name: String { return "logins" }
    override var version: Int { return 1 }
    override var rows: String { return "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "hostname TEXT NOT NULL, " +
        "httpRealm TEXT NOT NULL, " +
        "formSubmitUrl TEXT NOT NULL, " +
        "usernameField TEXT NOT NULL, " +
        "passwordField TEXT NOT NULL, " +
        "guid TEXT NOT NULL UNIQUE, " +
        "timeCreated REAL NOT NULL, " +
        "timeLastUsed REAL NOT NULL, " +
        "timePasswordChanged REAL NOT NULL, " +
        "username TEXT NOT NULL, " +
        "password TEXT NOT NULL" }

    override func getInsertAndArgs(inout item: Password) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if item.guid == nil {
            item.guid = NSUUID().UUIDString
        }
        args.append(item.hostname)
        args.append(item.httpRealm)
        args.append(item.formSubmitUrl)
        args.append(item.usernameField)
        args.append(item.passwordField)
        args.append(item.guid)
        args.append(item.timeCreated)
        args.append(item.timeLastUsed)
        args.append(item.timePasswordChanged)
        args.append(item.username)
        args.append(item.password)
        return ("INSERT INTO \(name) (hostname, httpRealm, formSubmitUrl, usernameField, passwordField, guid, timeCreated, timeLastUsed, timePasswordChanged, username, password) VALUES (?,?,?,?,?,?,?,?,?,?,?)", args)
    }

    override func getUpdateAndArgs(inout item: Password) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        args.append(item.httpRealm)
        args.append(item.formSubmitUrl)
        args.append(item.usernameField)
        args.append(item.passwordField)
        args.append(item.timeCreated)
        args.append(item.timeLastUsed)
        args.append(item.timePasswordChanged)
        args.append(item.password)
        args.append(item.hostname)
        args.append(item.username)

        return ("UPDATE \(name) SET httpRealm = ?, formSubmitUrl = ?, usernameField = ?, passwordField = ?, timeCreated = ?, timeLastUsed = ?, timePasswordChanged = ?, password = ? WHERE hostname = ? AND username = ?", args)
    }

    override func getDeleteAndArgs(inout item: Password?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let pw = item {
            args.append(pw.hostname)
            args.append(pw.username)
            return ("DELETE FROM \(name) WHERE hostname = ? AND username = ?", args)
        }
        return ("DELETE FROM \(name)", args)
    }

    override var factory: ((row: SDRow) -> Password)? {
        return { row -> Password in
            let site = Site(url: row["hostname"] as String ?? "", title: "")
            let pw = Password(site: site, username: row["username"] as? String ?? "", password: row["password"] as? String ?? "")

            pw.httpRealm = row["httpRealm"] as? String ?? ""
            pw.formSubmitUrl = row["formSubmitUrl"] as? String ?? ""
            pw.usernameField = row["usernameField"] as? String ?? ""
            pw.passwordField = row["passwordField"] as? String ?? ""
            pw.guid = row["guid"] as? String
            pw.timeCreated = NSDate(timeIntervalSince1970: row["timeCreated"] as? Double ?? 0)
            pw.timeLastUsed = NSDate(timeIntervalSince1970: row["timeLastUsed"] as? Double ?? 0)
            pw.timePasswordChanged = NSDate(timeIntervalSince1970: row["timePasswordChanged"] as? Double ?? 0)

            return pw
        }
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let filter: AnyObject = options?.filter {
            args.append(filter)
            return ("SELECT * FROM \(name) WHERE hostname = ?", args)
        }
        return ("SELECT * FROM \(name)", args)
    }
}

public class SQLitePasswords : Passwords {
    private let table = PasswordsTable<Password>()
    private let db: BrowserDB

    public init(files: FileAccessor) {
        self.db = BrowserDB(files: files)!
        db.createOrUpdate(table)
    }

    public func get(options: QueryOptions, complete: (cursor: Cursor) -> Void) {
        var err: NSError? = nil
        let cursor = db.query(&err, callback: { (connection, err) -> Cursor in
            return self.table.query(connection, options: options)

        })

        dispatch_async(dispatch_get_main_queue()) { _ in
            complete(cursor: cursor)
        }
    }

    public func add(password: Password, complete: (success: Bool) -> Void) {
        var err: NSError? = nil
        var success = false
        let updated = db.update(&err) { (connection, inout err: NSError?) -> Int in
            return self.table.update(connection, item: password, err: &err)
        }
        println("Updated \(updated)")

        if updated == 0 {
            let inserted = db.insert(&err) { (connection, inout err: NSError?) -> Int in
                return self.table.insert(connection, item: password, err: &err)
            }
            println("Inserted \(inserted)")

            if inserted > -1 {
                success = true
            }
        } else {
            success = true
        }

        dispatch_async(dispatch_get_main_queue()) { _ in
            complete(success: success)
            return
        }
    }

    public func remove(password: Password, complete: (success: Bool) -> Void) {
        var err: NSError? = nil
        let deleted = db.delete(&err) { (conn, inout err: NSError?) -> Int in
            return self.table.delete(conn, item: password, err: &err)
        }

        dispatch_async(dispatch_get_main_queue()) { _ in
            complete(success: deleted > -1)
        }
    }

    public func removeAll(complete: (success: Bool) -> Void) {
        var err: NSError? = nil
        let deleted = db.delete(&err) { (conn, inout err: NSError?) -> Int in
            return self.table.delete(conn, item: nil, err: &err)
        }

        dispatch_async(dispatch_get_main_queue()) { _ in
            complete(success: deleted > -1)
        }
    }
}
