/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

@_exported import MozillaAppServices

private let log = Logger.syncLogger

typealias LoginsStoreError = LoginsStorageError
public typealias LoginRecord = Login

public extension Login {
    init(credentials: URLCredential, protectionSpace: URLProtectionSpace) {
        let hostname: String
        if let _ = protectionSpace.protocol {
            hostname = protectionSpace.urlString()
        } else {
            hostname = protectionSpace.host
        }

        let httpRealm = protectionSpace.realm
        let username = credentials.user
        let password = credentials.password

        self.init(
            id: "",
            hostname: hostname,
            password: password ?? "",
            username: username ?? "",
            httpRealm: httpRealm,
            formSubmitUrl: "",
            usernameField: "",
            passwordField: "",
            timesUsed: 0,
            timeCreated: 0,
            timeLastUsed: 0,
            timePasswordChanged: 0
        )
    }

    init(fromJSONDict dict: [String: Any]) {
        self.init(
            id: dict["id"] as? String ?? "",
            hostname: dict["hostname"] as? String ?? "",
            password: dict["password"] as? String ?? "",

            username: dict["username"] as? String ?? "",
            
            httpRealm: dict["httpRealm"] as? String,
            formSubmitUrl: dict["formSubmitUrl"] as? String,
            
            usernameField: dict["usernameField"] as? String ?? "",
            passwordField: dict["passwordField"] as? String ?? "",

            timesUsed: (dict["timesUsed"] as? Int64) ?? 0,
            timeCreated: (dict["timeCreated"] as? Int64) ?? 0,
            timeLastUsed: (dict["timeLastUsed"] as? Int64) ?? 0,
            timePasswordChanged: (dict["timePasswordChanged"] as? Int64) ?? 0
        )
    }

    var credentials: URLCredential {
        return URLCredential(user: username, password: password, persistence: .forSession)
    }

    var protectionSpace: URLProtectionSpace {
        return URLProtectionSpace.fromOrigin(hostname)
    }

    var hasMalformedHostname: Bool {
        let hostnameURL = hostname.asURL
        guard let _ = hostnameURL?.host else {
            return true
        }

        return false
    }

    var isValid: Maybe<Void> {
        // Referenced from https://mxr.mozilla.org/mozilla-central/source/toolkit/components/passwordmgr/nsLoginManager.js?rev=f76692f0fcf8&mark=280-281#271

        // Logins with empty hostnames are not valid.
        if hostname.isEmpty {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with an empty hostname."))
        }

        // Logins with empty passwords are not valid.
        if password.isEmpty {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with an empty password."))
        }

        // Logins with both a formSubmitUrl and httpRealm are not valid.
        if let _ = formSubmitUrl, let _ = httpRealm {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with both a httpRealm and formSubmitUrl."))
        }

        // Login must have at least a formSubmitUrl or httpRealm.
        if formSubmitUrl == nil, httpRealm == nil {
            return Maybe(failure: LoginRecordError(description: "Can't add a login without a httpRealm or formSubmitUrl."))
        }

        // All good.
        return Maybe(success: ())
    }

    func toJSONDict() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "password": password,
            "hostname": hostname,

            "timesUsed": timesUsed,
            "timeCreated": timeCreated,
            "timeLastUsed": timeLastUsed,
            "timePasswordChanged": timePasswordChanged,

            "username": username,
            "passwordField": passwordField,
            "usernameField": usernameField,
        ]

        if let httpRealm = self.httpRealm {
            dict["httpRealm"] = httpRealm
        }

        if let formSubmitUrl = self.formSubmitUrl {
            dict["formSubmitUrl"] = formSubmitUrl
        }

        return dict
    }
}

public class LoginRecordError: MaybeErrorType {
    public let description: String
    public init(description: String) {
        self.description = description
    }
}

public class RustLogins {
    let databasePath: String
    let encryptionKey: String
    let salt: String

    let queue: DispatchQueue
    let storage: LoginsStorage

    private(set) var isOpen = false

    private var didAttemptToMoveToBackup = false

    public init(databasePath: String, encryptionKey: String, salt: String) {
        self.databasePath = databasePath
        self.encryptionKey = encryptionKey
        self.salt = salt

        queue = DispatchQueue(label: "RustLogins queue: \(databasePath)", attributes: [])
        storage = LoginsStorage(databasePath: databasePath)
    }

    // Migrate and return the salt, or create a new salt
    // Also, in the event of an error, returns a new salt.
    public static func setupPlaintextHeaderAndGetSalt(databasePath: String, encryptionKey: String) -> String {
        do {
            if FileManager.default.fileExists(atPath: databasePath) {
                let db = LoginsStorage(databasePath: databasePath)
                let salt = try db.getDbSaltForKey(key: encryptionKey)
                try db.migrateToPlaintextHeader(key: encryptionKey, salt: salt)
                return salt
            }
        } catch {
            print(error)
            Sentry.shared.send(message: "setupPlaintextHeaderAndGetSalt failed", tag: SentryTag.rustLogins, severity: .error, description: error.localizedDescription)
        }
        let saltOf32Chars = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return saltOf32Chars
    }

    // Open the db, and if it fails, it moves the db and creates a new db file and opens it.
    private func open() -> NSError? {
        do {
            try storage.unlockWithKeyAndSalt(key: encryptionKey, salt: salt)
            isOpen = true
            return nil
        } catch let err as NSError {
            if let loginsStoreError = err as? LoginsStoreError {
                switch loginsStoreError {
                // The encryption key is incorrect, or the `databasePath`
                // specified is not a valid database. This is an unrecoverable
                // state unless we can move the existing file to a backup
                // location and start over.
                case let .InvalidKey(message):
                    log.error(message)
                case let .MismatchedLock(message):
                    Sentry.shared.sendWithStacktrace(message: "Panicked when opening Rust Logins database", tag: SentryTag.rustLogins, severity: .error, description: message)
                default:
                    Sentry.shared.sendWithStacktrace(message: "Unspecified or other error when opening Rust Logins database", tag: SentryTag.rustLogins, severity: .error, description: loginsStoreError.localizedDescription)
                }
            } else {
                Sentry.shared.sendWithStacktrace(message: "Unknown error when opening Rust Logins database", tag: SentryTag.rustLogins, severity: .error, description: err.localizedDescription)
            }

            if !didAttemptToMoveToBackup {
                RustShared.moveDatabaseFileToBackupLocation(databasePath: databasePath)
                didAttemptToMoveToBackup = true
                return open()
            }

            return err
        }
    }

    private func close() -> NSError? {
        do {
            try storage.lock()
            isOpen = false
            return nil
        } catch let err as NSError {
            Sentry.shared.sendWithStacktrace(message: "Unknown error when closing Logins database", tag: SentryTag.rustLogins, severity: .error, description: err.localizedDescription)
            return err
        }
    }

    public func reopenIfClosed() -> NSError? {
        var error: NSError?

        queue.sync {
            guard !isOpen else { return }

            error = open()
        }

        return error
    }

    public func forceClose() -> NSError? {
        var error: NSError?

        queue.sync {
            guard isOpen else { return }

            error = close()
        }

        return error
    }

    public func sync(unlockInfo: SyncUnlockInfo) -> Success {
        let deferred = Success()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.MismatchedLock(message: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                try _ = self.storage.sync(unlockInfo: unlockInfo)
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                if let loginsStoreError = err as? LoginsStoreError {
                    switch loginsStoreError {
                    case let .SyncAuthInvalid(message):
                        Sentry.shared.sendWithStacktrace(message: "Panicked when syncing Logins database", tag: SentryTag.rustLogins, severity: .error, description: message)
                    default:
                        Sentry.shared.sendWithStacktrace(message: "Unspecified or other error when syncing Logins database", tag: SentryTag.rustLogins, severity: .error, description: loginsStoreError.localizedDescription)
                    }
                }

                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func get(id: String) -> Deferred<Maybe<Login?>> {
        let deferred = Deferred<Maybe<Login?>>()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.MismatchedLock(message: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                let record = try self.storage.get(id: id)
                deferred.fill(Maybe(success: record))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func searchLoginsWithQuery(_ query: String?) -> Deferred<Maybe<Cursor<Login>>> {
        return list().bind { result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            guard let records = result.successValue else {
                return deferMaybe(ArrayCursor(data: []))
            }

            guard let query = query?.lowercased(), !query.isEmpty else {
                return deferMaybe(ArrayCursor(data: records))
            }

            let filteredRecords = records.filter {
                $0.hostname.lowercased().contains(query) || $0.username.lowercased().contains(query)
            }
            return deferMaybe(ArrayCursor(data: filteredRecords))
        }
    }

    public func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace, withUsername username: String? = nil) -> Deferred<Maybe<Cursor<Login>>> {
        return list().bind { result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            guard let records = result.successValue else {
                return deferMaybe(ArrayCursor(data: []))
            }

            let filteredRecords: [Login]
            if let username = username {
                filteredRecords = records.filter {
                    $0.username == username && (
                        $0.hostname == protectionSpace.urlString() ||
                            $0.hostname == protectionSpace.host
                    )
                }
            } else {
                filteredRecords = records.filter {
                    $0.hostname == protectionSpace.urlString() ||
                        $0.hostname == protectionSpace.host
                }
            }
            return deferMaybe(ArrayCursor(data: filteredRecords))
        }
    }

    public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return list().bind { result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            return deferMaybe((result.successValue?.count ?? 0) > 0)
        }
    }

    public func list() -> Deferred<Maybe<[Login]>> {
        let deferred = Deferred<Maybe<[Login]>>()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.MismatchedLock(message: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                let records = try self.storage.list()
                deferred.fill(Maybe(success: records))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func add(login: Login) -> Deferred<Maybe<String>> {
        let deferred = Deferred<Maybe<String>>()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.MismatchedLock(message: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                let id = try self.storage.add(login: login)
                deferred.fill(Maybe(success: id))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func use(login: Login) -> Success {
        var updatedLogin = login
        updatedLogin.timesUsed += 1
        updatedLogin.timeLastUsed = Int64(Date.nowMicroseconds())

        return update(login: updatedLogin)
    }

    public func update(login: Login) -> Success {
        let deferred = Success()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.MismatchedLock(message: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                try self.storage.update(login: login)
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func delete(ids: [String]) -> Deferred<[Maybe<Bool>]> {
        return all(ids.map { delete(id: $0) })
    }

    public func delete(id: String) -> Deferred<Maybe<Bool>> {
        let deferred = Deferred<Maybe<Bool>>()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.MismatchedLock(message: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                let existed = try self.storage.delete(id: id)
                deferred.fill(Maybe(success: existed))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func reset() -> Success {
        let deferred = Success()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.MismatchedLock(message: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                try self.storage.reset()
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func wipeLocal() -> Success {
        let deferred = Success()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.MismatchedLock(message: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                try self.storage.wipeLocal()
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }
}
