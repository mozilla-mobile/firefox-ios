/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class PasswordsTable<T>: GenericTable<Password> {
    override var name: String { return "logins" }
    override var version: Int { return 2 }
    var encryption: EncryptionType = EncryptionType.AES256

    override var rows: String { return "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "hostname TEXT NOT NULL, " +
        "httpRealm TEXT NOT NULL, " +
        "formSubmitUrl TEXT NOT NULL, " +
        "usernameField TEXT NOT NULL, " +
        "passwordField TEXT NOT NULL, " +
        "encryptionType INTEGER NOT NULL, " +
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

        switch (encryption) {
        case EncryptionType.AES256:
            let secret = SQLitePasswords.secretKey!
            args.append((item.username as NSString).AES128EncryptWithKey(secret))
            args.append((item.password as NSString).AES128EncryptWithKey(secret))
            args.append(EncryptionType.AES256.rawValue)
        default:
            args.append(item.username)
            args.append(item.password)
            args.append(EncryptionType.NONE.rawValue)
        }
        println("Insert \(args)")

        return ("INSERT INTO \(name) (hostname, httpRealm, formSubmitUrl, usernameField, passwordField, guid, timeCreated, timeLastUsed, timePasswordChanged, username, password, encryptionType) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", args)
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

        switch (encryption) {
        case EncryptionType.AES256:
            let secret = SQLitePasswords.secretKey!
            args.append((item.password as NSString).AES128EncryptWithKey(secret))
            args.append(EncryptionType.AES256.rawValue)
            args.append((item.username as NSString).AES128EncryptWithKey(secret))
        default:
            args.append(item.password)
            args.append(EncryptionType.NONE.rawValue)
            args.append(item.username)
        }
        args.append(item.hostname)

        return ("UPDATE \(name) SET httpRealm = ?, formSubmitUrl = ?, usernameField = ?, passwordField = ?, timeCreated = ?, timeLastUsed = ?, timePasswordChanged = ?, password = ?, encryptionType = ? WHERE username = ? AND hostname = ?", args)
    }

    override func getDeleteAndArgs(inout item: Password?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let pw = item {
            args.append(pw.hostname)
            // Unfortunately, this will fail if the password is encrypted and encryption is turned off...
            switch (encryption) {
            case EncryptionType.AES256:
                let secret = SQLitePasswords.secretKey!
                args.append((pw.username as NSString).AES128EncryptWithKey(secret))
            default:
                args.append(pw.username)
            }
            return ("DELETE FROM \(name) WHERE hostname = ? AND username = ?", args)
        }
        return ("DELETE FROM \(name)", args)
    }

    override var factory: ((row: SDRow) -> Password)? {
        return { row -> Password in
            var user = row["username"] as? String ?? ""
            var pass = row["password"] as? String ?? ""

            let encType = EncryptionType(rawValue: row["encryptionType"] as? Int ?? EncryptionType.NONE.rawValue)
            if encType == EncryptionType.AES256 {
                let secret = SQLitePasswords.secretKey!
                user = user.AES128DecryptWithKey(secret)! as String
                pass = pass.AES128DecryptWithKey(secret)! as String
            }

            let pw = Password(hostname: row["hostname"] as! String, username: user, password: pass)

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

enum EncryptionType: Int {
    case NONE = 0
    case AES256 = 1
}

public class SQLitePasswords : Passwords {
    private let table = PasswordsTable<Password>()
    private let db: BrowserDB

    public init(db: BrowserDB) {
        self.db = db
        db.createOrUpdate(table)
    }

    static private var secretKey: String? {
        let key = "PasswordManager"
        if KeychainWrapper.hasValueForKey(key) {
            return KeychainWrapper.stringForKey(key)
        }

        let Length = 24
        if let secret = NSMutableData(length: Length) {
            // XXX - I really wanted to use SecKeyGenerateSymmetric but it doesn't seem defined...
            let err  = SecRandomCopyBytes(kSecRandomDefault, Length, UnsafeMutablePointer(secret.mutableBytes))
            if err == 0 {
                let secret = secret.base64EncodedString
                KeychainWrapper.setString(secret, forKey: key)
                return secret
            }
        }
        return nil
    }

    public func get(options: QueryOptions, complete: (cursor: Cursor<Password>) -> Void) {
        var err: NSError? = nil
        let cursor = db.withReadableConnection(&err, callback: { (connection, err) -> Cursor<Password> in
            return self.table.query(connection, options: options)

        })

        dispatch_async(dispatch_get_main_queue()) { _ in
            complete(cursor: cursor)
        }
    }

    public func add(password: Password, complete: (success: Bool) -> Void) {
        var err: NSError? = nil
        var success = false
        let updated = db.withWritableConnection(&err) { (connection, inout err: NSError?) -> Int in
            return self.table.update(connection, item: password, err: &err)
        }

        if updated == 0 {
            let inserted = db.withWritableConnection(&err) { (connection, inout err: NSError?) -> Int in
                return self.table.insert(connection, item: password, err: &err)
            }

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
        let deleted = db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            return self.table.delete(conn, item: password, err: &err)
        }

        dispatch_async(dispatch_get_main_queue()) { _ in
            complete(success: deleted > -1)
        }
    }

    public func removeAll(complete: (success: Bool) -> Void) {
        var err: NSError? = nil
        let deleted = db.withWritableConnection(&err) { (conn, inout err: NSError?) -> Int in
            return self.table.delete(conn, item: nil, err: &err)
        }

        dispatch_async(dispatch_get_main_queue()) { _ in
            complete(success: deleted > -1)
        }
    }
}
