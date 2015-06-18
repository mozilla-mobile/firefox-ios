/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = XCGLogger.defaultInstance()

private class LoginsTable: Table {
    var name: String { return "logins" }
    var version: Int { return 1 }

    func create(db: SQLiteDBConnection, version: Int) -> Bool {
        // We ignore the version.
        let sql = "CREATE TABLE IF NOT EXISTS \(name) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "hostname TEXT NOT NULL, " +
            "httpRealm TEXT, " +
            "formSubmitUrl TEXT, " +
            "usernameField TEXT, " +
            "passwordField TEXT, " +
            "guid TEXT NOT NULL UNIQUE, " +
            "timeCreated INTEGER NOT NULL, " +
            "timeLastUsed INTEGER, " +
            "timePasswordChanged INTEGER NOT NULL, " +
            "username TEXT, " +
            "password TEXT NOT NULL" +
        ")"
        let err = db.executeChange(sql, withArgs: nil)
        return err == nil
    }

    func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool {
        if from == to {
            log.debug("Skipping update from \(from) to \(to).")
            return true
        }

        if from == 0 {
            // This is likely an upgrade from before Bug 1160399.
            log.debug("Updating logins tables from zero. Assuming drop and recreate.")
            return drop(db) && create(db, version: to)
        }

        // TODO: real update!
        log.debug("Updating logins table from \(from) to \(to).")
        return drop(db) && create(db, version: to)
    }

    func exists(db: SQLiteDBConnection) -> Bool {
        let tablesSQL = "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?"
        let res = db.executeQuery(tablesSQL, factory: StringFactory, withArgs: [name])
        log.debug("\(res.count) logins tables exist.")
        return res.count > 0
    }

    func drop(db: SQLiteDBConnection) -> Bool {
        log.debug("Dropping logins table.")
        let err = db.executeChange("DROP TABLE IF EXISTS \(name)", withArgs: nil)
        return err == nil
    }

}

private var secretKey: String? {
#if MOZ_CHANNEL_DEBUG
    return nil
#else
    let key = "sqlcipher.key.logins.db"
    if KeychainWrapper.hasValueForKey(key) {
    return KeychainWrapper.stringForKey(key)
    }

    let Length: UInt = 256
    let secret = Bytes.generateRandomBytes(Length).base64EncodedString
    KeychainWrapper.setString(secret, forKey: key)
    return secret
#endif
}

public class SQLiteLogins: Logins {
    private let table = LoginsTable()
    private let db: BrowserDB

    public init(files: FileAccessor) {
        self.db = BrowserDB(filename: "logins.sqlite", secretKey: secretKey, files: files)
        db.createOrUpdate(table)
    }

    private class func LoginFactory(row: SDRow) -> Login {
        let c = NSURLCredential(user: row["username"] as? String ?? "",
            password: row["password"] as! String,
            persistence: NSURLCredentialPersistence.None)
        let protectionSpace = NSURLProtectionSpace(host: row["hostname"] as! String,
            port: 0,
            `protocol`: nil,
            realm: row["httpRealm"] as? String,
            authenticationMethod: nil)

        let login = Login(credential: c, protectionSpace: protectionSpace)
        login.formSubmitUrl = row["formSubmitUrl"] as? String
        login.usernameField = row["usernameField"] as? String
        login.passwordField = row["passwordField"] as? String

        if let timeCreated = row.getTimestamp("timeCreated"),
            let timeLastUsed = row.getTimestamp("timeLastUsed"),
            let timePasswordChanged = row.getTimestamp("timePasswordChanged") {
                login.timeCreated = timeCreated
                login.timeLastUsed = timeLastUsed
                login.timePasswordChanged = timePasswordChanged
        }

        return login
    }

    private class func LoginDataFactory(row: SDRow) -> LoginData {
        return LoginFactory(row) as LoginData
    }

    private class func LoginUsageDataFactory(row: SDRow) -> LoginUsageData {
        return LoginFactory(row) as LoginUsageData
    }

    public func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace) -> Deferred<Result<Cursor<LoginData>>> {
        let sql = "SELECT username, password, hostname, httpRealm, formSubmitUrl, usernameField, passwordField FROM \(table.name) WHERE hostname = ? ORDER BY timeLastUsed DESC"
        let args: [AnyObject?] = [protectionSpace.host]
        return db.runQuery(sql, args: args, factory: SQLiteLogins.LoginDataFactory)
    }

    public func getUsageDataForLogin(login: LoginData) -> Deferred<Result<LoginUsageData>> {
        let sql = "SELECT * FROM \(table.name) WHERE hostname = ? AND username IS ? LIMIT 1"
        let args: [AnyObject?] = [login.hostname, login.username]
        return db.runQuery(sql, args: args, factory: SQLiteLogins.LoginUsageDataFactory) >>== { value in
            return deferResult(value[0]!)
        }
    }

    public func addLogin(login: LoginData) -> Success {
        var args = [AnyObject?]()
        args.append(login.hostname)
        args.append(login.httpRealm)
        args.append(login.formSubmitUrl)
        args.append(login.usernameField)
        args.append(login.passwordField)

        if var login = login as? SyncableLoginData {
            if login.guid == nil {
                login.guid = Bytes.generateGUID()
            }
            args.append(login.guid)
        } else {
            args.append(Bytes.generateGUID())
        }

        let date = NSNumber(unsignedLongLong: NSDate.nowMicroseconds())
        args.append(date) // timeCreated
        args.append(date) // timeLastUsed
        args.append(date) // timePasswordChanged
        args.append(login.username)
        args.append(login.password)

        return db.run("INSERT INTO \(table.name) (hostname, httpRealm, formSubmitUrl, usernameField, passwordField, guid, timeCreated, timeLastUsed, timePasswordChanged, username, password) VALUES (?,?,?,?,?,?,?,?,?,?,?)", withArgs: args)
    }

    public func addUseOf(login: LoginData) -> Success {
        let date = NSNumber(unsignedLongLong: NSDate.nowMicroseconds())
        return db.run("UPDATE \(table.name) SET timeLastUsed = ? WHERE hostname = ? AND username IS ?", withArgs: [date, login.hostname, login.username])
    }

    public func updateLogin(login: LoginData) -> Success {
        let date = NSNumber(unsignedLongLong: NSDate.nowMicroseconds())
        var args: Args = [
            login.httpRealm,
            login.formSubmitUrl,
            login.usernameField,
            login.passwordField,
            date, // timePasswordChanged
            login.password,
            login.hostname,
            login.username]

        return db.run("UPDATE \(table.name) SET httpRealm = ?, formSubmitUrl = ?, usernameField = ?, passwordField = ?, timePasswordChanged = ?, password = ? WHERE hostname = ? AND username IS ?", withArgs: args)
    }

    public func removeLogin(login: LoginData) -> Success {
        var args: Args = [login.hostname, login.username]
        return db.run("DELETE FROM \(table.name) WHERE hostname = ? AND username IS ?", withArgs: args)
    }

    public func removeAll() -> Success {
        return db.run("DELETE FROM \(table.name)")
    }
}
