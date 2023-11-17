// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import Shared
@_exported import MozillaAppServices
import Common

typealias LoginsStoreError = LoginsApiError
public typealias LoginRecord = EncryptedLogin

public extension LoginsStoreError {
    var descriptionValue: String {
        switch self {
        case .InvalidRecord: return "InvalidRecord"
        case .NoSuchRecord: return "NoSuchRecord"
        case .IncorrectKey: return "IncorrectKey"
        case .Interrupted: return "Interrupted"
        case .SyncAuthInvalid: return "SyncAuthInvalid"
        case .UnexpectedLoginsApiError: return "UnexpectedLoginsApiError"
        }
    }
}

public extension EncryptedLogin {
    init(credentials: URLCredential, protectionSpace: URLProtectionSpace) {
        let hostname: String
        if protectionSpace.protocol != nil {
            hostname = protectionSpace.urlString()
        } else {
            hostname = protectionSpace.host
        }

        let httpRealm = protectionSpace.realm
        let username = credentials.user ?? ""
        let password = credentials.password ?? ""
        let fields = LoginFields(origin: hostname, httpRealm: httpRealm, formActionOrigin: "", usernameField: "", passwordField: "")
        let record = RecordFields(id: "", timesUsed: 0, timeCreated: 0, timeLastUsed: 0, timePasswordChanged: 0)
        let login = Login(record: record, fields: fields, secFields: SecureLoginFields(password: password, username: username))

        self.init(
            record: record,
            fields: fields,
            secFields: ""
        )

        let rustLoginsEncryption = RustLoginEncryptionKeys()
        let encryptedLogin = rustLoginsEncryption.encryptSecureFields(login: login)
        self.secFields = encryptedLogin?.secFields ?? ""
    }

    var formSubmitUrl: String? {
        get {
            return self.fields.formActionOrigin
        }
        set (newValue) {
            self.fields.formActionOrigin = newValue
        }
    }

    var httpRealm: String? {
        get {
            return self.fields.httpRealm
        }
        set (newValue) {
            self.fields.httpRealm = newValue
        }
    }

    var hostname: String {
        get {
            return self.fields.origin
        }
        set (newValue) {
            self.fields.origin = newValue
        }
    }

    var usernameField: String {
        get {
            return self.fields.usernameField
        }
        set (newValue) {
            self.fields.usernameField = newValue
        }
    }

    var passwordField: String {
        get {
            return self.fields.passwordField
        }
        set (newValue) {
            self.fields.passwordField = newValue
        }
    }

    var id: String {
        get {
            return self.record.id
        }
        set (newValue) {
            self.record.id = newValue
        }
    }

    var timePasswordChanged: Int64 {
        get {
            return self.record.timePasswordChanged
        }
        set (newValue) {
            self.record.timePasswordChanged = newValue
        }
    }

    var timeCreated: Int64 {
        get {
            return self.record.timeCreated
        }
        set (newValue) {
            self.record.timeCreated = newValue
        }
    }

    var decryptedUsername: String {
        let rustKeys = RustLoginEncryptionKeys()
        return rustKeys.decryptSecureFields(login: self)?.secFields.username ?? ""
    }

    var decryptedPassword: String {
        let rustKeys = RustLoginEncryptionKeys()
        return rustKeys.decryptSecureFields(login: self)?.secFields.password ?? ""
    }

    var credentials: URLCredential {
        let rustLoginsEncryption = RustLoginEncryptionKeys()
        let login = rustLoginsEncryption.decryptSecureFields(login: self)
        return URLCredential(user: login?.secFields.username ?? "", password: login?.secFields.password ?? "", persistence: .forSession)
    }

    var protectionSpace: URLProtectionSpace {
        return URLProtectionSpace.fromOrigin(fields.origin)
    }

    var hasMalformedHostname: Bool {
        let hostnameURL = fields.origin.asURL
        guard hostnameURL?.host != nil else { return true }

        return false
    }

    init(fromJSONDict dict: [String: Any]) {
        let password = dict["password"] as? String ?? ""
        let username = dict["username"] as? String ?? ""

        let fields = LoginFields(
            origin: dict["hostname"] as? String ?? "",
            httpRealm: dict["httpRealm"] as? String,
            formActionOrigin: dict["formSubmitUrl"] as? String,
            usernameField: dict["usernameField"] as? String ?? "",
            passwordField: dict["passwordField"] as? String ?? "")

        let record = RecordFields(
            id: dict["id"] as? String ?? "",
            timesUsed: (dict["timesUsed"] as? Int64) ?? 0,
            timeCreated: (dict["timeCreated"] as? Int64) ?? 0,
            timeLastUsed: (dict["timeLastUsed"] as? Int64) ?? 0,
            timePasswordChanged: (dict["timePasswordChanged"] as? Int64) ?? 0)
        let login = Login(
            record: record,
            fields: fields,
            secFields: SecureLoginFields(password: password,
                                         username: username))

        self.init(
            record: record,
            fields: fields,
            secFields: ""
        )

        let rustLoginsEncryption = RustLoginEncryptionKeys()
        let encryptedLogin = rustLoginsEncryption.encryptSecureFields(login: login)
        self.secFields = encryptedLogin?.secFields ?? ""
    }

    func toJSONDict() -> [String: Any] {
        let rustLoginsEncryption = RustLoginEncryptionKeys()
        let login = rustLoginsEncryption.decryptSecureFields(login: self)

        var dict: [String: Any] = [
            "id": record.id,
            "password": login?.secFields.password ?? "",
            "hostname": fields.origin,

            "timesUsed": record.timesUsed,
            "timeCreated": record.timeCreated,
            "timeLastUsed": record.timeLastUsed,
            "timePasswordChanged": record.timePasswordChanged,

            "username": login?.secFields.username ?? "",
            "passwordField": fields.passwordField,
            "usernameField": fields.usernameField,
        ]

        if let httpRealm = fields.httpRealm {
            dict["httpRealm"] = httpRealm
        }

        if let formSubmitUrl = fields.formActionOrigin {
            dict["formSubmitUrl"] = formSubmitUrl
        }

        return dict
    }
}

public class LoginEntryFlattened {
    var id: String
    var hostname: String
    var password: String
    var username: String
    var httpRealm: String?
    var formSubmitUrl: String?
    var usernameField: String
    var passwordField: String

    public init(id: String, hostname: String, password: String, username: String, httpRealm: String?, formSubmitUrl: String?, usernameField: String, passwordField: String) {
        self.id = id
        self.hostname = hostname
        self.password = password
        self.username = username
        self.httpRealm = httpRealm
        self.formSubmitUrl = formSubmitUrl
        self.usernameField = usernameField
        self.passwordField = passwordField
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

        let httpRealm = protectionSpace.realm
        let username = credentials.user
        let password = credentials.password
        let fields = LoginFields(origin: hostname, httpRealm: httpRealm, formActionOrigin: "", usernameField: "", passwordField: "")

        self.init(
            fields: fields,
            secFields: SecureLoginFields(password: password ?? "", username: username ?? "")
        )
    }

    init(fromJSONDict dict: [String: Any]) {
        let password = dict["password"] as? String ?? ""
        let username = dict["username"] as? String ?? ""

        let fields = LoginFields(
            origin: dict["hostname"] as? String ?? "",
            httpRealm: dict["httpRealm"] as? String,
            formActionOrigin: dict["formSubmitUrl"] as? String,
            usernameField: dict["usernameField"] as? String ?? "",
            passwordField: dict["passwordField"] as? String ?? "")

        self.init(
            fields: fields,
            secFields: SecureLoginFields(password: password, username: username)
        )
    }

    init(fromLoginEntryFlattened login: LoginEntryFlattened) {
        self.init(
            fields: LoginFields(
                origin: login.hostname,
                httpRealm: nil,
                formActionOrigin: login.formSubmitUrl,
                usernameField: "",
                passwordField: ""
            ),
            secFields: SecureLoginFields(
                password: login.password,
                username: login.username
            )
        )
    }

    var hostname: String {
        get {
            return self.fields.origin
        }
        set (newValue) {
            self.fields.origin = newValue
        }
    }

    var username: String {
        get {
            return self.secFields.username
        }
        set (newValue) {
            self.secFields.username = newValue
        }
    }

    var password: String {
        get {
            return self.secFields.password
        }
        set (newValue) {
            self.secFields.password = newValue
        }
    }

    var protectionSpace: URLProtectionSpace {
        return URLProtectionSpace.fromOrigin(fields.origin)
    }

    var credentials: URLCredential {
        return URLCredential(user: self.secFields.username, password: self.secFields.password, persistence: .forSession)
    }

    var isValid: Maybe<Void> {
        // Referenced from https://mxr.mozilla.org/mozilla-central/source/toolkit/components/passwordmgr/nsLoginManager.js?rev=f76692f0fcf8&mark=280-281#271

        // Logins with empty hostnames are not valid.
        if self.fields.origin.isEmpty {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with an empty hostname."))
        }

        // Logins with empty passwords are not valid.
        if self.secFields.password.isEmpty {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with an empty password."))
        }

        // Logins with both a formSubmitUrl and httpRealm are not valid.
        if self.fields.formActionOrigin != nil,
           self.fields.httpRealm != nil {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with both a httpRealm and formSubmitUrl."))
        }

        // Login must have at least a formSubmitUrl or httpRealm.
        if self.fields.formActionOrigin == nil, self.fields.httpRealm == nil {
            return Maybe(failure: LoginRecordError(description: "Can't add a login without a httpRealm or formSubmitUrl."))
        }

        // All good.
        return Maybe(success: ())
    }
}

public enum LoginEncryptionKeyError: Error {
    case noKeyCreated
    case illegalState
    case dbRecordCountVerificationError(String)
}

public class RustLoginEncryptionKeys {
    public let loginsSaltKeychainKey = "sqlcipher.key.logins.salt"
    public let loginsUnlockKeychainKey = "sqlcipher.key.logins.db"
    public let loginPerFieldKeychainKey = "appservices.key.logins.perfield"

    // The old database salt and key will be stored in the two keychain keys below to allow
    // for potential data restore
    public let loginsPostMigrationSalt = "sqlcipher.key.logins.salt.post.migration"
    public let loginsPostMigrationKey = "sqlcipher.key.logins.db.post.migration"

    let keychain = MZKeychainWrapper.sharedClientAppContainerKeychain
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

            keychain.set(secret, forKey: loginPerFieldKeychainKey, withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)
            keychain.set(canary,
                         forKey: canaryPhraseKey,
                         withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)

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

    func decryptSecureFields(login: EncryptedLogin) -> Login? {
        guard let key = self.keychain.string(forKey: self.loginPerFieldKeychainKey) else {
            return nil
        }

        do {
            return try decryptLogin(login: login, encryptionKey: key)
        } catch let err as NSError {
            if let loginsStoreError = err as? LoginsStoreError {
                logLoginsStoreError(
                    err: loginsStoreError,
                    errorDomain: err.domain,
                    errorMessage: "Error while decrypting login")
            } else {
                logger.log("Unknown error while decrypting login",
                           level: .warning,
                           category: .storage,
                           description: err.localizedDescription)
            }
        }
        return nil
    }

    func encryptSecureFields(
        login: Login,
        encryptionKey: String? = nil
    ) -> EncryptedLogin? {
        guard let key = self.keychain.string(forKey: self.loginPerFieldKeychainKey) else {
            return nil
        }

        do {
            return try encryptLogin(login: login, encryptionKey: key)
        } catch let err as NSError {
            if let loginsStoreError = err as? LoginsStoreError {
                logLoginsStoreError(
                    err: loginsStoreError,
                    errorDomain: err.domain,
                    errorMessage: "Error while encrypting login")
            } else {
                logger.log("Unknown error while encrypting login",
                           level: .warning,
                           category: .storage,
                           description: err.localizedDescription)
            }
        }
        return nil
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
            case .IncorrectKey:
                return "Incorrect key"
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

public class RustLogins {
    let perFieldDatabasePath: String

    let queue: DispatchQueue
    var storage: LoginsStorage?

    private(set) var isOpen = false

    private var didAttemptToMoveToBackup = false

    private let logger: Logger

    public init(sqlCipherDatabasePath: String,
                databasePath: String,
                logger: Logger = DefaultLogger.shared) {
        self.perFieldDatabasePath = databasePath
        self.logger = logger

        queue = DispatchQueue(label: "RustLogins queue: \(databasePath)", attributes: [])

        // We aren't migrating SQLCipher databases anymore, if one exists, we should delete it
        deleteSQLCipherDBIfExists(sqlCipherDatabasePath: sqlCipherDatabasePath)
    }

    // Open the db after attempting to migrate the database from sqlcipher, and if it fails, it moves the db and creates a new db file and opens it.
    private func open() -> NSError? {
        do {
            storage = try LoginsStorage(databasePath: self.perFieldDatabasePath)
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

    private func deleteInvalidLogins(key: String,
                                     logins: [EncryptedLogin],
                                     completion: @escaping (Bool) -> Void) {
        // Create a list of IDs from saved logins that can't be decrypted
        let loginsToDelete = logins
            .filter { (try? decryptLogin(login: $0, encryptionKey: key)) == nil }
            .map { $0.record.id }

        // Delete all the logins that can't be decrypted
        self.deleteLogins(ids: loginsToDelete).upon { deleteResults in
            var verified = true
            for result in deleteResults {
                if case let .failure(err) = result {
                    let errMsg = "Login could not be deleted during verification"
                    self.logger.log(errMsg,
                                    level: .warning,
                                    category: .storage,
                                    description: err.localizedDescription)
                    verified = false
                }
            }
            completion(verified)
        }
    }

    public func verifyLogins(completion: @escaping (Bool) -> Void) {
        queue.async {
            self.listLogins().upon { loginResult in
                switch loginResult {
                case let .failure(error):
                    self.logger.log("Logins could not be retrieved for verification",
                                    level: .warning,
                                    category: .storage,
                                    description: error.localizedDescription)
                    completion(false)
                    return
                case let .success(logins):
                    guard !logins.isEmpty else {
                        // If there are no logins we don't need to go through this verification
                        // process in the future so we return true.
                        completion(true)
                        return
                    }

                    let rustKeys = RustLoginEncryptionKeys()
                    guard let key = rustKeys.keychain.string(forKey: rustKeys.loginPerFieldKeychainKey) else {
                        // If the key is missing during the verification process, we wipe the database and
                        // recreate the key.
                        self.resetLoginsAndKey(rustKeys: rustKeys) { resetResult in
                            if case let .failure(error) = resetResult {
                                self.logger.log("Logins and key could not be reset during verification",
                                                level: .warning,
                                                category: .storage,
                                                description: error.localizedDescription)
                            }
                            return
                        }
                        completion(false)
                        return
                    }
                    self.deleteInvalidLogins(key: key, logins: logins, completion: completion)
                }
            }
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

    public func getLogin(id: String) -> Deferred<Maybe<EncryptedLogin?>> {
        let deferred = Deferred<Maybe<EncryptedLogin?>>()

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

    public func searchLoginsWithQuery(_ query: String?) -> Deferred<Maybe<Cursor<EncryptedLogin>>> {
        let rustKeys = RustLoginEncryptionKeys()
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
                let username = rustKeys.decryptSecureFields(login: $0)?.secFields.username ?? ""
                return $0.fields.origin.lowercased().contains(query) || username.lowercased().contains(query)
            }
            return deferMaybe(ArrayCursor(data: filteredRecords))
        }
    }

    public func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace, withUsername username: String? = nil) -> Deferred<Maybe<Cursor<EncryptedLogin>>> {
        let rustKeys = RustLoginEncryptionKeys()
        return listLogins().bind { result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            guard let records = result.successValue else {
                return deferMaybe(ArrayCursor(data: []))
            }

            let filteredRecords: [EncryptedLogin]
            if let username = username {
                filteredRecords = records.filter {
                    let login = rustKeys.decryptSecureFields(login: $0)
                    return login?.secFields.username ?? "" == username && (
                        $0.fields.origin == protectionSpace.urlString() ||
                        $0.fields.origin == protectionSpace.host
                    )
                }
            } else {
                filteredRecords = records.filter {
                    return $0.fields.origin == protectionSpace.urlString() ||
                    $0.fields.origin == protectionSpace.host
                }
            }
            return deferMaybe(ArrayCursor(data: filteredRecords))
        }
    }

    public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return listLogins().bind { result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            return deferMaybe((result.successValue?.count ?? 0) > 0)
        }
    }

    public func listLogins() -> Deferred<Maybe<[EncryptedLogin]>> {
        let deferred = Deferred<Maybe<[EncryptedLogin]>>()

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
                case .success(let key):
                    do {
                        let id = try self.storage?.add(login: login, encryptionKey: key).record.id
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

    public func use(login: EncryptedLogin) -> Success {
        let deferred = Success()

        queue.async {
            guard self.isOpen else {
                let error = LoginsStoreError.UnexpectedLoginsApiError(reason: "Database is closed")
                deferred.fill(Maybe(failure: error as MaybeErrorType))
                return
            }

            do {
                try self.storage?.touch(id: login.record.id)
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
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
                case .success(let key):
                    do {
                        _ = try self.storage?.update(id: id, login: login, encryptionKey: key)
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

    private func deleteSQLCipherDBIfExists(sqlCipherDatabasePath: String) {
        // If the sqlCipherDatabasePath is valid, we should delete it
        do {
            if FileManager.default.fileExists(atPath: sqlCipherDatabasePath) {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: sqlCipherDatabasePath))
                logger.log("Successfully deleted SQLCipherDB", level: .debug, category: .storage)
            }
        } catch {
            logger.log("SQLCipher DB exists but could not be deleted", level: .debug, category: .storage)
        }

        let keychain = MZKeychainWrapper.sharedClientAppContainerKeychain
        let rustKeys = RustLoginEncryptionKeys()
        keychain.removeObject(forKey: rustKeys.loginsUnlockKeychainKey, withAccessibility: .afterFirstUnlock)
        keychain.removeObject(forKey: rustKeys.loginsSaltKeychainKey, withAccessibility: .afterFirstUnlock)
    }

    private func resetLoginsAndKey(rustKeys: RustLoginEncryptionKeys,
                                   completion: @escaping (Result<String, NSError>) -> Void) {
        self.wipeLocalEngine().upon { result in
            guard result.isSuccess else {
                completion(.failure(result.failureValue! as NSError))
                return
            }

            do {
                let key = try rustKeys.createAndStoreKey()
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

    public func getStoredKey(completion: @escaping (Result<String, NSError>) -> Void) {
        let rustKeys = RustLoginEncryptionKeys()
        let key = rustKeys.keychain.string(forKey: rustKeys.loginPerFieldKeychainKey)
        let encryptedCanaryPhrase = rustKeys.keychain.string(forKey: rustKeys.canaryPhraseKey)

        switch(key, encryptedCanaryPhrase) {
        case (.some(key), .some(encryptedCanaryPhrase)):
            do {
                let canaryIsValid = try checkCanary(
                    canary: encryptedCanaryPhrase!,
                    text: rustKeys.canaryPhrase,
                    encryptionKey: key!)

                if canaryIsValid {
                    completion(.success(key!))
                } else {
                    logger.log("Logins key was corrupted, new one generated",
                               level: .warning,
                               category: .storage)
                    GleanMetrics.LoginsStoreKeyRegeneration.corrupt.record()
                    self.resetLoginsAndKey(rustKeys: rustKeys, completion: completion)
                }
            } catch let error as NSError {
                logger.log("Error validating logins encryption key",
                           level: .warning,
                           category: .storage,
                           description: error.localizedDescription)
                completion(.failure(error))
            }
        case (.some(key), .none):
            // The key is present, but we didn't expect it to be there.

            logger.log("Logins key lost due to storage malfunction, new one generated",
                       level: .warning,
                       category: .storage)
            GleanMetrics.LoginsStoreKeyRegeneration.other.record()
            self.resetLoginsAndKey(rustKeys: rustKeys, completion: completion)
        case (.none, .some(encryptedCanaryPhrase)):
            // We expected the key to be present, but it's gone missing on us.

            logger.log("Logins key lost, new one generated",
                       level: .warning,
                       category: .storage)
            GleanMetrics.LoginsStoreKeyRegeneration.lost.record()
            self.resetLoginsAndKey(rustKeys: rustKeys, completion: completion)
        case (.none, .none):
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
                    // the database, we both clear the databbase and the reset the key.
                    self.resetLoginsAndKey(rustKeys: rustKeys, completion: completion)
                } else {
                    // There are no records in the database so we don't need to wipe any
                    // existing login records. We just need to create a new key.
                    do {
                        let key = try rustKeys.createAndStoreKey()
                        completion(.success(key))
                    } catch let error as NSError {
                        completion(.failure(error))
                    }
                }
            }
        default:
            // If none of the above cases apply, we're in a state that shouldn't be possible but is disallowed nonetheless
            completion(.failure(LoginEncryptionKeyError.illegalState as NSError))
        }
    }
}
