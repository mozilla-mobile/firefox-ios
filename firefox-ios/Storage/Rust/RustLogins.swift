// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import Shared
import Common

import class MozillaAppServices.LoginsStorage
import class MozillaAppServices.MZKeychainWrapper
import enum MozillaAppServices.LoginsApiError
import enum MozillaAppServices.MZKeychainItemAccessibility
import func MozillaAppServices.checkCanary
import func MozillaAppServices.createCanary
import func MozillaAppServices.createKey
import struct MozillaAppServices.Login
import struct MozillaAppServices.LoginEntry
import protocol MozillaAppServices.KeyManager

typealias LoginsStoreError = LoginsApiError
public typealias LoginRecord = Login

public extension LoginsStoreError {
    var descriptionValue: String {
        switch self {
        case .InvalidRecord: return "InvalidRecord"
        case .NoSuchRecord: return "NoSuchRecord"
        case .InvalidKey: return "InvalidKey"
        case .Interrupted: return "Interrupted"
        case .SyncAuthInvalid: return "SyncAuthInvalid"
        case .UnexpectedLoginsApiError: return "UnexpectedLoginsApiError"
        case .MissingKey: return "MissingKey"
        case .EncryptionFailed(reason: let reason): return "EncryptionFailed reason:\(reason)"
        case .DecryptionFailed(reason: let reason): return "DecryptionFailed reason:\(reason)"
        case .NssUninitialized: return "NssUninitialized"
        case .NssAuthenticationError(reason: let reason): return "NssAuthenticationError reason:\(reason)"
        case .AuthenticationError(reason: let reason): return "AuthenticationError reason:\(reason)"
        case .AuthenticationCanceled: return "AuthenticationCanceled"
        }
    }
}

public extension Login {
    init(credentials: URLCredential, protectionSpace: URLProtectionSpace) {
        let hostname: String
        if protectionSpace.protocol != nil {
            hostname = protectionSpace.urlString()
        } else {
            hostname = protectionSpace.host
        }

        self.init(
            id: "",
            timesUsed: 0,
            timeCreated: 0,
            timeLastUsed: 0,
            timePasswordChanged: 0,
            origin: hostname,
            httpRealm: protectionSpace.realm,
            formActionOrigin: "",
            usernameField: "",
            passwordField: "",
            password: credentials.password ?? "",
            username: credentials.user ?? ""
        )
    }

    var formSubmitUrl: String? {
        get {
            return self.formActionOrigin
        }
        set (newValue) {
            self.formActionOrigin = newValue
        }
    }

    var hostname: String {
        get {
          return self.origin
        }
        set (newValue) {
          self.origin = newValue
        }
    }

    var credentials: URLCredential {
        return URLCredential(
            user: self.username,
            password: self.password,
            persistence: .forSession
        )
    }

    var protectionSpace: URLProtectionSpace {
        return URLProtectionSpace.fromOrigin(origin)
    }

    var hasMalformedHostname: Bool {
        let hostnameURL = origin.asURL
        guard hostnameURL?.host != nil else { return true }

        return false
    }

    init(fromJSONDict dict: [String: Any]) {
        self.init(
            id: dict["id"] as? String ?? "",
            timesUsed: (dict["timesUsed"] as? Int64) ?? 0,
            timeCreated: (dict["timeCreated"] as? Int64) ?? 0,
            timeLastUsed: (dict["timeLastUsed"] as? Int64) ?? 0,
            timePasswordChanged: (dict["timePasswordChanged"] as? Int64) ?? 0,
            origin: dict["hostname"] as? String ?? "",
            httpRealm: dict["httpRealm"] as? String,
            formActionOrigin: dict["formSubmitUrl"] as? String,
            usernameField: dict["usernameField"] as? String ?? "",
            passwordField: dict["passwordField"] as? String ?? "",
            password: dict["password"] as? String ?? "",
            username: dict["username"] as? String ?? ""
        )
    }
}

public extension LoginEntry {
    init(credentials: URLCredential, protectionSpace: URLProtectionSpace) {
        let hostname: String
        if protectionSpace.protocol != nil {
            hostname = protectionSpace.urlString()
        } else {
            hostname = protectionSpace.host
        }

        self.init(
            origin: hostname,
            httpRealm: protectionSpace.realm,
            formActionOrigin: "",
            usernameField: "",
            passwordField: "",
            password: credentials.password ?? "",
            username: credentials.user ?? ""
        )
    }

    init(fromJSONDict dict: [String: Any]) {
        self.init(
            origin: dict["hostname"] as? String ?? "",
            httpRealm: dict["httpRealm"] as? String,
            formActionOrigin: dict["formSubmitUrl"] as? String,
            usernameField: dict["usernameField"] as? String ?? "",
            passwordField: dict["passwordField"] as? String ?? "",
            password: dict["password"] as? String ?? "",
            username: dict["username"] as? String ?? ""
        )
    }

    var hostname: String {
        get {
            return self.origin
        }
        set (newValue) {
            self.origin = newValue
        }
    }

    var protectionSpace: URLProtectionSpace {
        return URLProtectionSpace.fromOrigin(origin)
    }

    var credentials: URLCredential {
        return URLCredential(user: self.username, password: self.password, persistence: .forSession)
    }

    var isValid: Maybe<Void> {
        // Referenced from https://mxr.mozilla.org/mozilla-central/source/toolkit/components/passwordmgr/nsLoginManager.js?rev=f76692f0fcf8&mark=280-281#271

        // Logins with empty hostnames are not valid.
        if self.origin.isEmpty {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with an empty hostname."))
        }

        // Logins with empty passwords are not valid.
        if self.password.isEmpty {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with an empty password."))
        }

        // Logins with both a formSubmitUrl and httpRealm are not valid.
        if self.formActionOrigin != nil,
           self.httpRealm != nil {
            return Maybe(
                failure: LoginRecordError(description: "Can't add a login with both a httpRealm and formSubmitUrl.")
            )
        }

        // Login must have at least a formSubmitUrl or httpRealm.
        if self.formActionOrigin == nil, self.httpRealm == nil {
            return Maybe(
                failure: LoginRecordError(description: "Can't add a login without a httpRealm or formSubmitUrl.")
            )
        }

        // All good.
        return Maybe(success: ())
    }
}

public class RustLoginEncryptionKeys {
    public let loginPerFieldKeychainKey = "appservices.key.logins.perfield"
    let legacyKeychain = KeychainManager.legacyShared

    let canaryPhraseKey = "canaryPhrase"
    let canaryPhrase = "a string for checking validity of the key"

    private let logger: Logger

    public init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    fileprivate func createAndStoreKey() throws -> String {
        do {
            let secret = try createKey()
            let canary = try createCanary(text: canaryPhrase, encryptionKey: secret)

            DispatchQueue.global(qos: .background).sync {
                legacyKeychain.set(secret,
                                   forKey: loginPerFieldKeychainKey,
                                   withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)
                legacyKeychain.set(canary,
                                   forKey: canaryPhraseKey,
                                   withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)
            }
            return secret
        } catch let err as NSError {
            if let loginsStoreError = err as? LoginsStoreError {
                logLoginsStoreError(
                    err: loginsStoreError,
                    errorDomain: err.domain,
                    errorMessage: "Error while creating and storing logins key")

                throw LoginEncryptionKeyError.noKeyCreated
            } else {
                logger.log("Unknown error while creating and storing logins key",
                           level: .warning,
                           category: .storage,
                           description: err.localizedDescription)

                throw LoginEncryptionKeyError.noKeyCreated
            }
        }
    }

    private func logLoginsStoreError(
        err: LoginsStoreError,
        errorDomain: String,
        errorMessage: String
    ) {
        var message: String {
            switch err {
            case .InvalidRecord(let message),
                    .NoSuchRecord(let message),
                    .Interrupted(let message),
                    .SyncAuthInvalid(let message),
                    .UnexpectedLoginsApiError(let message):
                return message
            case .InvalidKey:
                return "InvalidKey"
            case .MissingKey:
                return "MissingKey"
            case .EncryptionFailed(reason: let reason):
                return "EncryptionFailed reason:\(reason)"
            case .DecryptionFailed(reason: let reason):
                return "DecryptionFailed reason:\(reason)"
            case .NssUninitialized:
                return "NssUninitialized"
            case .NssAuthenticationError(reason: let reason):
                return "NssAuthenticationError reason:\(reason)"
            case .AuthenticationError(reason: let reason):
                return "AuthenticationError reason:\(reason)"
            case .AuthenticationCanceled:
                return "AuthenticationCanceled"
            }
        }

        logger.log(errorMessage,
                   level: .warning,
                   category: .storage,
                   description: "\(errorDomain) - \(err.descriptionValue): \(message)")
    }
}

public class LoginRecordError: MaybeErrorType {
    public let description: String
    public init(description: String) {
        self.description = description
    }
}

/// This is a protocol followed by RustLogins to provide an alternative to using `Deferred` in that code
/// Its part of a long term effort to remove `Deferred` usage inside the application and is a work in progress.
protocol LoginsProtocol {
    func getLogin(id: String, completionHandler: @escaping (Result<Login?, Error>) -> Void)
    func getLoginsFor(
        protectionSpace: URLProtectionSpace,
        withUsername username: String?,
        completionHandler: @escaping (Result<[Login], Error>) -> Void)
    func addLogin(login: LoginEntry, completionHandler: @escaping (Result<Login?, Error>) -> Void)
    func listLogins(completionHandler: @escaping (Result<[Login], Error>) -> Void)
    func updateLogin(id: String, login: LoginEntry, completionHandler: @escaping (Result<Login?, Error>) -> Void)
    func use(login: Login, completionHandler: @escaping (Result<Login?, Error>) -> Void)
    func searchLoginsWithQuery(_ query: String?, completionHandler: @escaping (Result<[Login], Error>) -> Void)
    func deleteLogins(ids: [String], completionHandler: @escaping ([Result<Bool?, Error>]) -> Void)
    func deleteLogin(id: String, completionHandler: @escaping (Result<Bool?, Error>) -> Void)
}

public class RustLogins: LoginsProtocol, KeyManager {
    let perFieldDatabasePath: String

    let queue: DispatchQueue
    var storage: LoginsStorage?
    let rustKeychain = KeychainManager.shared
    var rustKeychainEnabled = false

    private(set) var isOpen = false

    private var didAttemptToMoveToBackup = false

    private let logger: Logger

    public init(databasePath: String,
                logger: Logger = DefaultLogger.shared,
                rustKeychainEnabled: Bool = false) {
        self.perFieldDatabasePath = databasePath
        self.logger = logger
        self.rustKeychainEnabled = rustKeychainEnabled

        queue = DispatchQueue(label: "RustLogins queue: \(databasePath)", attributes: [])
    }

    // Open the db.
    private func open() -> NSError? {
        do {
            storage = try LoginsStorage(databasePath: self.perFieldDatabasePath, keyManager: self)
            isOpen = true
            return nil
        } catch let err as NSError {
            if let loginsStoreError = err as? LoginsStoreError {
                // This is an unrecoverable
                // state unless we can move the existing file to a backup
                // location and start over.
                logger.log("Logins store error when opening Rust Logins database",
                           level: .warning,
                           category: .storage,
                           description: loginsStoreError.localizedDescription)
            } else {
                logger.log("Unknown error when opening Rust Logins database",
                           level: .warning,
                           category: .storage,
                           description: err.localizedDescription)
            }

            if !didAttemptToMoveToBackup {
                RustShared.moveDatabaseFileToBackupLocation(databasePath: self.perFieldDatabasePath)
                didAttemptToMoveToBackup = true
                return open()
            }

            return err
        }
    }

    private func close() -> NSError? {
        storage = nil
        isOpen = false
        return nil
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

    public func getLogin(id: String, completionHandler: @escaping (Result<Login?, Error>) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                completionHandler(.failure(error))
                return
            }

            do {
                let record = try self.storage?.get(id: id)
                completionHandler(.success(record))
            } catch let err as NSError {
                completionHandler(.failure(err))
            }
        }
    }

    public func getLogin(id: String) -> Deferred<Maybe<Login?>> {
        let deferred = Deferred<Maybe<Login?>>()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                let record = try self.storage?.get(id: id)
                deferred.fill(Maybe(success: record))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func searchLoginsWithQuery(_ query: String?) -> Deferred<Maybe<Cursor<Login>>> {
        return listLogins().bind { result in
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
                let username = $0.username
                return $0.origin.lowercased().contains(query) || username.lowercased().contains(query)
            }
            return deferMaybe(ArrayCursor(data: filteredRecords))
        }
    }

    public func getLoginsFor(
        protectionSpace: URLProtectionSpace,
        withUsername username: String?,
        completionHandler: @escaping (Result<[Login], Error>) -> Void) {
        listLogins { result in
            switch result {
            case .success(let records):
                let filteredRecords: [Login]
                if let username = username {
                    filteredRecords = records.filter {
                        return $0.username == username && (
                            $0.origin == protectionSpace.urlString() ||
                            $0.origin == protectionSpace.host
                        )
                    }
                } else {
                    filteredRecords = records.filter {
                        return $0.origin == protectionSpace.urlString() ||
                        $0.origin == protectionSpace.host
                    }
                }
                completionHandler(.success(filteredRecords))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    public func searchLoginsWithQuery(
        _ query: String?,
        completionHandler: @escaping (Result<[Login], Error>) -> Void) {
            listLogins { result in
                switch result {
                case .success(let logins):
                    let records = logins

                    guard let query = query?.lowercased(), !query.isEmpty else {
                        completionHandler(.success(records))
                        return
                    }

                    let filteredRecords = records.filter {
                        return $0.origin.lowercased().contains(query) || $0.username.lowercased().contains(query)
                    }

                    completionHandler(.success(filteredRecords))

                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        }

    public func getLoginsForProtectionSpace(
        _ protectionSpace: URLProtectionSpace,
        withUsername username: String? = nil
    ) -> Deferred<Maybe<Cursor<Login>>> {
        return listLogins().bind { result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            guard let records = result.successValue else {
                return deferMaybe(ArrayCursor(data: []))
            }

            let filteredRecords: [Login]
            if let username = username {
                filteredRecords = records.filter {
                    return $0.username == username && (
                        $0.origin == protectionSpace.urlString() ||
                        $0.origin == protectionSpace.host
                    )
                }
            } else {
                filteredRecords = records.filter {
                    return $0.origin == protectionSpace.urlString() ||
                    $0.origin == protectionSpace.host
                }
            }
            return deferMaybe(ArrayCursor(data: filteredRecords))
        }
    }

    public func hasLogins(completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                completionHandler(.failure(error))
                return
            }

            do {
                let isEmpty = try self.storage?.isEmpty() ?? true
                completionHandler(.success(!isEmpty))
            } catch let error as NSError {
                completionHandler(.failure(error))
            }
        }
    }

    /// TODO(FXIOS-5603): We should remove this once we cleanup all deferred uses
    /// and use hasLogins instead
    public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        let deferred = Deferred<Maybe<Bool>>()
        self.hasLogins { result in
            switch result {
            case .success(let hasLogins):
                deferred.fill(Maybe(success: hasLogins))
            case .failure(let error):
                deferred.fill(Maybe(failure: error as MaybeErrorType))
            }
        }
        return deferred
    }

    public func listLogins() -> Deferred<Maybe<[Login]>> {
        let deferred = Deferred<Maybe<[Login]>>()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                let records = try self.storage?.list()
                deferred.fill(Maybe(success: records ?? []))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func listLogins(completionHandler: @escaping (Result<[Login], Error>) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                completionHandler(.failure(error))
                return
            }

            do {
                let records = try self.storage?.list()
                completionHandler(.success(records ?? []))
            } catch let err as NSError {
                completionHandler(.failure(err))
            }
        }
    }

    public func addLogin(login: LoginEntry) -> Deferred<Maybe<String>> {
        let deferred = Deferred<Maybe<String>>()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")

                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            self.getStoredKey { result in
                switch result {
                case .success:
                    do {
                        let id = try self.storage?.add(login: login).id
                        deferred.fill(Maybe(success: id!))
                    } catch let err as NSError {
                        deferred.fill(Maybe(failure: err))
                    }
                case .failure(let err):
                    deferred.fill(Maybe(failure: err))
                }
            }
        }

        return deferred
    }

    public func addLogin(login: LoginEntry, completionHandler: @escaping (Result<Login?, Error>) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                completionHandler(.failure(error))
                return
            }

            self.getStoredKey { result in
                switch result {
                case .success:
                    do {
                        let login = try self.storage?.add(login: login)
                        completionHandler(.success(login))
                    } catch let err as NSError {
                        completionHandler(.failure(err))
                    }
                case .failure(let err):
                    completionHandler(.failure(err))
                }
            }
        }
    }

    public func use(login: Login) -> Success {
        let deferred = Success()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                try self.storage?.touch(id: login.id)
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func use(login: Login, completionHandler: @escaping (Result<Login?, Error>) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                completionHandler(.failure(error))
                return
            }

            do {
                try self.storage?.touch(id: login.id)
                completionHandler(.success(login))
            } catch let error as NSError {
                completionHandler(.failure(error))
            }
        }
    }

    public func updateLogin(id: String, login: LoginEntry) -> Success {
        let deferred = Success()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            self.getStoredKey { result in
                switch result {
                case .success:
                    do {
                        _ = try self.storage?.update(id: id, login: login)
                        deferred.fill(Maybe(success: ()))
                    } catch let err as NSError {
                        deferred.fill(Maybe(failure: err))
                    }
                case .failure(let err):
                    deferred.fill(Maybe(failure: err))
                }
            }
        }

        return deferred
    }

    public func updateLogin(
        id: String,
        login: LoginEntry,
        completionHandler: @escaping (Result<Login?, Error>) -> Void) {
            queue.async {
                guard self.isOpen else {
                    let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                    completionHandler(.failure(error))
                    return
                }

                self.getStoredKey { result in
                    switch result {
                    case .success:
                        do {
                            let updatedLogin = try self.storage?.update(id: id, login: login)
                            completionHandler(.success(updatedLogin))
                        } catch let error as NSError {
                            completionHandler(.failure(error))
                        }
                    case .failure(let err):
                        completionHandler(.failure(err))
                    }
                }
            }
        }

    public func deleteLogins(ids: [String], completionHandler: @escaping ([Result<Bool?, Error>]) -> Void) {
        var results: [Result<Bool?, Error>] = []
        for id in ids {
            deleteLogin(id: id) { result in
                results.append(result)
                if results.count == ids.count {
                    completionHandler(results)
                }
            }
        }
    }

    public func deleteLogin(id: String, completionHandler: @escaping (Result<Bool?, Error>) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                completionHandler(.failure(error))
                return
            }

            do {
                let existed = try self.storage?.delete(id: id)
                completionHandler(.success(existed))
            } catch let err as NSError {
                completionHandler(.failure(err))
            }
        }
    }

    public func deleteLogins(ids: [String]) -> Deferred<[Maybe<Bool>]> {
        return all(ids.map { deleteLogin(id: $0) })
    }

    public func deleteLogin(id: String) -> Deferred<Maybe<Bool>> {
        let deferred = Deferred<Maybe<Bool>>()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                let existed = try self.storage?.delete(id: id)
                deferred.fill(Maybe(success: existed!))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func wipeLocalEngine() -> Success {
        let deferred = Success()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                try self.storage?.wipeLocal()
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func registerWithSyncManager() {
        queue.async { [unowned self] in
            self.storage?.registerWithSyncManager()
        }
    }

    private func resetLoginsAndKey(rustKeys: RustLoginEncryptionKeys,
                                   completion: @escaping (Result<String, NSError>) -> Void) {
        self.wipeLocalEngine().upon { result in
            guard result.isSuccess else {
                completion(.failure(result.failureValue! as NSError))
                return
            }

            do {
                let key = self.rustKeychainEnabled ?
                    try self.rustKeychain.createLoginsKeyData() :
                    try rustKeys.createAndStoreKey()
                completion(.success(key))
            } catch let error as NSError {
                self.logger.log("Error creating logins encryption key",
                                level: .warning,
                                category: .storage,
                                description: error.localizedDescription)
                completion(.failure(error))
            }
        }
    }

    private func getKeychainData(rustKeys: RustLoginEncryptionKeys) -> (String?, String?) {
        var keychainData: (String?, String?) = (nil, nil)

        DispatchQueue.global(qos: .background).sync {
            let key = rustKeys.legacyKeychain.string(forKey: rustKeys.loginPerFieldKeychainKey)
            let encryptedCanaryPhrase = rustKeys.legacyKeychain.string(forKey: rustKeys.canaryPhraseKey)
            keychainData = (key, encryptedCanaryPhrase)
        }

        return keychainData
    }

    public func getStoredKey(completion: @escaping (Result<String, NSError>) -> Void) {
        let rustKeys = RustLoginEncryptionKeys()
        var key: String?
        var encryptedCanaryPhrase: String?

        if self.rustKeychainEnabled {
            (key, encryptedCanaryPhrase) = rustKeychain.getLoginsKeyData()
        } else {
            (key, encryptedCanaryPhrase) = getKeychainData(rustKeys: rustKeys)
        }

        switch(key, encryptedCanaryPhrase) {
        case (.some(key), .some(encryptedCanaryPhrase)):
                self.handleExpectedKeyAction(rustKeys: rustKeys,
                                             encryptedCanaryPhrase: encryptedCanaryPhrase,
                                             key: key,
                                             completion: completion)
        case (.some(key), .none):
            self.handleUnexpectedKeyAction(rustKeys: rustKeys, completion: completion)
        case (.none, .some(encryptedCanaryPhrase)):
            self.handleMissingKeyAction(rustKeys: rustKeys, completion: completion)
        case (.none, .none):
            self.handleFirstTimeCallOrClearedKeychainAction(rustKeys: rustKeys, completion: completion)
        default:
            self.handleIllegalStateAction(completion: completion)
        }
    }

    private func handleExpectedKeyAction(rustKeys: RustLoginEncryptionKeys,
                                         encryptedCanaryPhrase: String?,
                                         key: String?,
                                         completion: @escaping (Result<String, NSError>) -> Void) {
        // We expected the key to be present, and it is.
        do {
            let canaryIsValid = try checkCanary(canary: encryptedCanaryPhrase!,
                                                text: rustKeys.canaryPhrase,
                                                encryptionKey: key!)
            if canaryIsValid {
                completion(.success(key!))
            } else {
                self.logger.log("Logins key was corrupted, new one generated",
                                level: .warning,
                                category: .storage)
                GleanMetrics.LoginsStoreKeyRegeneration.corrupt.record()
                self.resetLoginsAndKey(rustKeys: rustKeys, completion: completion)
            }
        } catch let error as NSError {
            self.logger.log("Error validating logins encryption key",
                            level: .warning,
                            category: .storage,
                            description: error.localizedDescription)
            completion(.failure(error))
        }
    }

    private func handleUnexpectedKeyAction(rustKeys: RustLoginEncryptionKeys,
                                           completion: @escaping (Result<String, NSError>) -> Void) {
        // The key is present, but we didn't expect it to be there.

        self.logger.log("Logins key lost due to storage malfunction, new one generated",
                        level: .warning,
                        category: .storage)
        GleanMetrics.LoginsStoreKeyRegeneration.other.record()
        self.resetLoginsAndKey(rustKeys: rustKeys, completion: completion)
    }

    private func handleMissingKeyAction(rustKeys: RustLoginEncryptionKeys,
                                        completion: @escaping (Result<String, NSError>) -> Void) {
        // We expected the key to be present, but it's gone missing on us.

        self.logger.log("Logins key lost, new one generated",
                        level: .warning,
                        category: .storage)
        GleanMetrics.LoginsStoreKeyRegeneration.lost.record()
        self.resetLoginsAndKey(rustKeys: rustKeys, completion: completion)
    }

    private func handleFirstTimeCallOrClearedKeychainAction(rustKeys: RustLoginEncryptionKeys,
                                                            completion: @escaping (Result<String, NSError>) -> Void) {
        // We didn't expect the key to be present, which either means this is a first-time
        // call or the key data has been cleared from the keychain.

        self.hasSyncedLogins().upon { result in
            guard result.failureValue == nil else {
                completion(.failure(result.failureValue! as NSError))
                return
            }

            guard let hasLogins = result.successValue else {
                let msg = "Failed to verify logins count before attempting to reset key"
                completion(.failure(LoginEncryptionKeyError.dbRecordCountVerificationError(msg) as NSError))
                return
            }

            if hasLogins {
                // Since the key data isn't present and we have login records in
                // the database, we both clear the database and reset the key.
                GleanMetrics.LoginsStoreKeyRegeneration.keychainDataLost.record()
                self.resetLoginsAndKey(rustKeys: rustKeys, completion: completion)
            } else {
                // There are no records in the database so we don't need to wipe any
                // existing login records. We just need to create a new key.
                do {
                    let key = self.rustKeychainEnabled ?
                        try self.rustKeychain.createLoginsKeyData() :
                        try rustKeys.createAndStoreKey()
                    completion(.success(key))
                } catch let error as NSError {
                    completion(.failure(error))
                }
            }
        }
    }

    private func handleIllegalStateAction(completion: @escaping (Result<String, NSError>) -> Void) {
        // If none of the above cases apply, we're in a state that shouldn't be
        // possible but is disallowed nonetheless
        completion(.failure(LoginEncryptionKeyError.illegalState as NSError))
    }

    // MARK: - KeyManager

    /**
    * Retrieves the encryption key used by the Rust logins component for encrypting and decrypting login data.
    *
    * This method is invoked internally by the Rust component whenever encryption or decryption is required.
    *
    * **Note on thread safety:**
    * Each CRUD operation in Rust acquires a mutex lock on the db to ensure thread safety.
    * Therefore, it's crucial to call `getStoredKey` before performing any such CRUD operations in Swift.
    * `addLogin` and `updateLogin` are good examples of that.
    *
    * **Usage Example:**
    * ```
    * public func methodThatRequiresEncDec() {
    *     ...
    *     self.getStoredKey {
    *         ...
    *         self.storage.someRustMethod()
    *         ...
    *     }
    * }
    * ```
    */
    public func getKey() throws -> Data {
        if self.rustKeychainEnabled {
            switch rustKeychain.queryKeychainForKey(key: rustKeychain.loginsKeyIdentifier) {
            case .success(let result):
                guard let data = result, let key = data.data(using: String.Encoding.utf8) else {
                    throw LoginsStoreError.MissingKey
                }
                return key
            case .failure:
                throw LoginsStoreError.MissingKey
            }
        } else {
            let rustKeys = RustLoginEncryptionKeys()
            guard let keyData = rustKeys.legacyKeychain.data(forKey: rustKeys.loginPerFieldKeychainKey) else {
                throw LoginsStoreError.MissingKey
            }
            return keyData
        }
    }
}
