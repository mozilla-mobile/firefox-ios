/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred

@_exported import Logins

private let log = Logger.syncLogger

public extension LoginRecord {
    public convenience init(credentials: URLCredential, protectionSpace: URLProtectionSpace) {
        let hostname: String
        if let _ = protectionSpace.`protocol` {
            hostname = protectionSpace.urlString()
        } else {
            hostname = protectionSpace.host
        }

        let httpRealm = protectionSpace.realm
        let username = credentials.user
        let password = credentials.password

        self.init(fromJSONDict: [
            "hostname": hostname,
            "httpRealm": httpRealm as Any,
            "username": username ?? "",
            "password": password ?? ""
        ])
    }

    public var credentials: URLCredential {
        return URLCredential(user: username ?? "", password: password, persistence: .none)
    }

    public var protectionSpace: URLProtectionSpace {
        return URLProtectionSpace.fromOrigin(hostname)
    }

    public var hasMalformedHostname: Bool {
        let hostnameURL = hostname.asURL
        guard let _ = hostnameURL?.host else {
            return true
        }

        return false
    }

    public var isValid: Maybe<()> {
        // Referenced from https://mxr.mozilla.org/mozilla-central/source/toolkit/components/passwordmgr/nsLoginManager.js?rev=f76692f0fcf8&mark=280-281#271

        // Logins with empty hostnames are not valid.
        if hostname.isEmpty {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with an empty hostname."))
        }

        // Logins with empty passwords are not valid.
        if password.isEmpty {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with an empty password."))
        }

        // Logins with both a formSubmitURL and httpRealm are not valid.
        if let _ = formSubmitURL, let _ = httpRealm {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with both a httpRealm and formSubmitURL."))
        }

        // Login must have at least a formSubmitURL or httpRealm.
        if (formSubmitURL == nil) && (httpRealm == nil) {
            return Maybe(failure: LoginRecordError(description: "Can't add a login without a httpRealm or formSubmitURL."))
        }

        // All good.
        return Maybe(success: ())
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

    let queue: DispatchQueue
    let storage: LoginsStorage

    public fileprivate(set) var isOpen: Bool = false

    private var didAttemptToMoveToBackup = false

    public init(databasePath: String, encryptionKey: String) {
        self.databasePath = databasePath
        self.encryptionKey = encryptionKey

        self.queue =  DispatchQueue(label: "RustLogins queue: \(databasePath)", attributes: [])
        self.storage = LoginsStorage(databasePath: databasePath)
    }

    private func moveDatabaseFileToBackupLocation() {
        let databaseURL = URL(fileURLWithPath: databasePath)
        let databaseContainingDirURL = databaseURL.deletingLastPathComponent()
        let baseFilename = databaseURL.lastPathComponent

        // Attempt to make a backup as long as the database file still exists.
        guard FileManager.default.fileExists(atPath: databasePath) else {
            // No backup was attempted since the database file did not exist.
            Sentry.shared.sendWithStacktrace(message: "The Logins database was deleted while in use", tag: SentryTag.rustLogins)
            return
        }

        Sentry.shared.sendWithStacktrace(message: "Unable to open Logins database", tag: SentryTag.rustLogins, severity: .warning, description: "Attempting to move '\(baseFilename)'")

        // Note that a backup file might already exist! We append a counter to avoid this.
        var bakCounter = 0
        var bakBaseFilename: String
        var bakDatabasePath: String
        repeat {
            bakCounter += 1
            bakBaseFilename = "\(baseFilename).bak.\(bakCounter)"
            bakDatabasePath = databaseContainingDirURL.appendingPathComponent(bakBaseFilename).path
        } while FileManager.default.fileExists(atPath: bakDatabasePath)

        do {
            try FileManager.default.moveItem(atPath: bakDatabasePath, toPath: bakDatabasePath)

            let shmBaseFilename = baseFilename + "-shm"
            let walBaseFilename = baseFilename + "-wal"
            log.debug("Moving \(shmBaseFilename) and \(walBaseFilename)…")

            let shmDatabasePath = databaseContainingDirURL.appendingPathComponent(shmBaseFilename).path
            if FileManager.default.fileExists(atPath: shmDatabasePath) {
                log.debug("\(shmBaseFilename) exists.")
                try FileManager.default.moveItem(atPath: shmDatabasePath, toPath: "\(bakDatabasePath)-shm")
            }

            let walDatabasePath = databaseContainingDirURL.appendingPathComponent(walBaseFilename).path
            if FileManager.default.fileExists(atPath: walDatabasePath) {
                log.debug("\(walBaseFilename) exists.")
                try FileManager.default.moveItem(atPath: shmDatabasePath, toPath: "\(bakDatabasePath)-wal")
            }

            log.debug("Finished moving Logins database successfully.")
        } catch let error as NSError {
            Sentry.shared.sendWithStacktrace(message: "Unable to move Logins database to backup location", tag: SentryTag.rustLogins, severity: .error, description: "Attempted to move to '\(bakBaseFilename)'. \(error.localizedDescription)")
        }
    }

    private func open() -> NSError? {
        do {
            try self.storage.unlock(withEncryptionKey: encryptionKey)
            isOpen = true
            return nil
        } catch let err as NSError {
            if let loginsStoreError = err as? LoginsStoreError {
                switch loginsStoreError {
                // The encryption key is incorrect, or the `databasePath`
                // specified is not a valid database. This is an unrecoverable
                // state unless we can move the existing file to a backup
                // location and start over.
                case .InvalidKey(let message):
                    log.error(message)

                    if !didAttemptToMoveToBackup {
                        moveDatabaseFileToBackupLocation()
                        didAttemptToMoveToBackup = true
                        return open()
                    }
                case .Panic(let message):
                    Sentry.shared.sendWithStacktrace(message: "Panicked when opening Logins database", tag: SentryTag.rustLogins, severity: .error, description: message)
                default:
                    Sentry.shared.sendWithStacktrace(message: "Unspecified or other error when opening Logins database", tag: SentryTag.rustLogins, severity: .error, description: loginsStoreError.localizedDescription)
                }
            } else {
                Sentry.shared.sendWithStacktrace(message: "Unknown error when opening Logins database", tag: SentryTag.rustLogins, severity: .error, description: err.localizedDescription)
            }

            return err
        }
    }

    private func close() -> NSError? {
        do {
            try self.storage.lock()
            isOpen = false
            return nil
        } catch let err as NSError {
            Sentry.shared.sendWithStacktrace(message: "Unknown error when closing Logins database", tag: SentryTag.rustLogins, severity: .error, description: err.localizedDescription)
            return err
        }
    }

    public func reopenIfClosed() {
        if !isOpen {
            _ = open()
        }
    }

    public func forceClose() {
        if isOpen {
            _ = close()
        }
    }

    public func sync(unlockInfo: SyncUnlockInfo) -> Success {
        let deferred = Success()

        queue.async {
            if !self.isOpen, let error = self.open() {
                deferred.fill(Maybe(failure: error))
                return
            }

            do {
                try self.storage.sync(unlockInfo: unlockInfo)
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                if let loginsStoreError = err as? LoginsStoreError {
                    switch loginsStoreError {
                    case .Panic(let message):
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

    public func get(id: String) -> Deferred<Maybe<LoginRecord?>> {
        let deferred = Deferred<Maybe<LoginRecord?>>()

        queue.async {
            if !self.isOpen, let error = self.open() {
                deferred.fill(Maybe(failure: error))
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

    public func searchLoginsWithQuery(_ query: String?) -> Deferred<Maybe<Cursor<LoginRecord>>> {
        return list().bind({ result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            guard let records = result.successValue else {
                return deferMaybe(ArrayCursor(data: []))
            }

            guard let query = query, !query.isEmpty else {
                return deferMaybe(ArrayCursor(data: records))
            }

            let filteredRecords = records.filter({
                $0.hostname.contains(query) ||
                ($0.username ?? "").contains(query) ||
                $0.password.contains(query)
            })
            return deferMaybe(ArrayCursor(data: filteredRecords))
        })
    }

    public func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace, withUsername username: String? = nil) -> Deferred<Maybe<Cursor<LoginRecord>>> {
        return list().bind({ result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            guard let records = result.successValue else {
                return deferMaybe(ArrayCursor(data: []))
            }

            let filteredRecords: [LoginRecord]
            if let username = username {
                filteredRecords = records.filter({
                    $0.username == username && (
                        $0.hostname == protectionSpace.urlString() ||
                        $0.hostname == protectionSpace.host
                    )
                })
            } else {
                filteredRecords = records.filter({
                    $0.hostname == protectionSpace.urlString() ||
                    $0.hostname == protectionSpace.host
                })
            }
            return deferMaybe(ArrayCursor(data: filteredRecords))
        })
    }

    public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return list().bind({ result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            return deferMaybe((result.successValue?.count ?? 0) > 0)
        })
    }

    public func list() -> Deferred<Maybe<[LoginRecord]>> {
        let deferred = Deferred<Maybe<[LoginRecord]>>()

        queue.async {
            if !self.isOpen, let error = self.open() {
                deferred.fill(Maybe(failure: error))
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

    public func add(login: LoginRecord) -> Deferred<Maybe<String>> {
        let deferred = Deferred<Maybe<String>>()

        queue.async {
            if !self.isOpen, let error = self.open() {
                deferred.fill(Maybe(failure: error))
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

    public func use(login: LoginRecord) -> Success {
        login.timesUsed += 1
        login.timeLastUsed = Int64(Date.nowMicroseconds())

        return self.update(login: login)
    }

    public func update(login: LoginRecord) -> Success {
        let deferred = Success()

        queue.async {
            if !self.isOpen, let error = self.open() {
                deferred.fill(Maybe(failure: error))
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
        return all(ids.map({ delete(id: $0) }))
    }

    public func delete(id: String) -> Deferred<Maybe<Bool>> {
        let deferred = Deferred<Maybe<Bool>>()

        queue.async {
            if !self.isOpen, let error = self.open() {
                deferred.fill(Maybe(failure: error))
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
            if !self.isOpen, let error = self.open() {
                deferred.fill(Maybe(failure: error))
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

    public func wipe() -> Success {
        let deferred = Success()

        queue.async {
            if !self.isOpen, let error = self.open() {
                deferred.fill(Maybe(failure: error))
                return
            }

            do {
                try self.storage.wipe()
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }
}
