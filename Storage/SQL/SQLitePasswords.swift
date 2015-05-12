/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = XCGLogger.defaultInstance()

class PasswordsTable<T>: GenericTable<Password> {
    override var name: String { return "logins" }
    override var version: Int { return 2 }
    var encryption: EncryptionType = EncryptionType.AES256

    private func secretKeyFor(key: String) -> String? {
        let key = "PasswordManager" + key
        if KeychainWrapper.hasValueForKey(key) {
            return KeychainWrapper.stringForKey(key)
        }

        let Length = 128
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

    var usernameSecret: String? {
        return secretKeyFor("Username")
    }

    var passwordSecret: String? {
        return secretKeyFor("Password")
    }

    var hostnameSecret: String? {
        return secretKeyFor("Hostname")
    }

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
        args.append(item.httpRealm)
        args.append(item.formSubmitUrl)
        args.append(item.usernameField)
        args.append(item.passwordField)
        args.append(item.guid)
        args.append(item.timeCreated)
        args.append(item.timeLastUsed)
        args.append(item.timePasswordChanged)

        if let host = encryptHostname(item.hostname),
           let user = encryptUsername(item.username, host: item.hostname),
           let pass = encryptPassword(item.password) {
            args.append(host)
            args.append(user)
            args.append(pass)
            args.append(EncryptionType.AES256.rawValue)

            return ("INSERT INTO \(name) (httpRealm, formSubmitUrl, usernameField, passwordField, guid, timeCreated, timeLastUsed, timePasswordChanged, hostname, username, password, encryptionType) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", args)
        }

        // If encryption failed, we won't store anything.
        log.error("Could not encrypt for insert operation")
        return nil
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

        if let host = encryptHostname(item.hostname),
           let user = encryptUsername(item.username, host: item.hostname),
           let pass = encryptPassword(item.password) {
            args.append(pass)
            args.append(EncryptionType.AES256.rawValue)
            args.append(user)
            args.append(host)
            return ("UPDATE \(name) SET httpRealm = ?, formSubmitUrl = ?, usernameField = ?, passwordField = ?, timeCreated = ?, timeLastUsed = ?, timePasswordChanged = ?, password = ?, encryptionType = ? WHERE username = ? AND hostname = ?", args)
        }

        // If encryption failed, we won't update anything.
        log.error("Could not encrypt for update operation")
        return nil
    }

    override func getDeleteAndArgs(inout item: Password?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let pw = item {
            if let user = encryptUsername(pw.username, host: pw.hostname),
               let host = encryptHostname(pw.hostname) {
                args.append(host)
                args.append(user)
                return ("DELETE FROM \(name) WHERE hostname = ? AND username = ?", args)
            }
            // If encryption failed, we won't delete anything.
            log.error("Could not encrypt username or hostname for deletion operation")
            return nil
        }
        return ("DELETE FROM \(name)", args)
    }

    override var factory: ((row: SDRow) -> Password?)? {
        return { row -> Password? in
            var user = row["username"] as! String
            var pass = row["password"] as! String
            var host = row["hostname"] as! String

            if let hostnameSecret = self.hostnameSecret, let decryptedHost = host.AES256DecryptWithKey(hostnameSecret),
               let usernameSecret = self.usernameSecret, let decryptedUser = user.AES256DecryptWithKey(usernameSecret),
               let passwordSecret = self.passwordSecret, let decryptedPass = pass.AES256DecryptWithKey(passwordSecret) {
                user = decryptedUser
                pass = decryptedPass
                host = decryptedHost
            } else {
                // If decryption failed, we won't return anything
                log.error("Could not decrypt password data")
                return nil
            }

            let pw = Password(hostname: host, username: user, password: pass)

            pw.httpRealm = row["httpRealm"] as! String
            pw.formSubmitUrl = row["formSubmitUrl"] as! String
            pw.usernameField = row["usernameField"] as! String
            pw.passwordField = row["passwordField"] as! String
            pw.guid = row["guid"] as! String
            pw.timeCreated = NSDate(timeIntervalSince1970: row["timeCreated"] as! Double)
            pw.timeLastUsed = NSDate(timeIntervalSince1970: row["timeLastUsed"] as! Double)
            pw.timePasswordChanged = NSDate(timeIntervalSince1970: row["timePasswordChanged"] as! Double)

            return pw
        }
    }

    // Hostnames are encrypted with just the secret key. Since we do queries on these, its tough to
    // encrypt this column.
    private func encryptHostname(host: String) -> String? {
        if let secret = hostnameSecret {
            let ivString = (secret + host)
            if let hostIv = ivString.dataUsingEncoding(NSUTF8StringEncoding) {
                return host.AES256EncryptWithKey(secret, iv: hostIv)
            }
        }
        return nil
    }

    // Passwords are encrypted with a random IV.
    private func encryptPassword(password: String) -> String? {
        if let secret = passwordSecret {
           return password.AES256EncryptWithKey(secret)
        }
        return nil
    }

    // Usernames are encrypted with the hostname/username as the IV to avoid the same result for sites
    // where the username is reused.
    private func encryptUsername(user: String, host: String) -> String? {
        if let secret = usernameSecret {
            let ivString = (user + secret + host)
            if let userIv = ivString.dataUsingEncoding(NSUTF8StringEncoding) {
                return user.AES256EncryptWithKey(secret, iv: userIv)
            }
        }
        return nil
    }

    override func getQueryAndArgs(options: QueryOptions?) -> (String, [AnyObject?])? {
        var args = [AnyObject?]()
        if let filter = options?.filter as? String {
            if let host = encryptHostname(filter) {
                args.append(host)
                return ("SELECT * FROM \(name) WHERE hostname = ?", args)
            }
            log.error("Could not encrypt hostname for query")
            return nil
        }
        return ("SELECT * FROM \(name)", args)
    }
}

enum EncryptionType: Int {
    case AES256 = 1
}

public class SQLitePasswords : Passwords {
    private let table = PasswordsTable<Password>()
    private let db: BrowserDB

    public init(db: BrowserDB) {
        self.db = db
        db.createOrUpdate(table)
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
