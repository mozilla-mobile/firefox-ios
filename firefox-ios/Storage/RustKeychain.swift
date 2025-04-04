// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

import class MozillaAppServices.MZKeychainWrapper
import enum MozillaAppServices.AutofillApiError
import enum MozillaAppServices.MZKeychainItemAccessibility
import func MozillaAppServices.checkCanary
import func MozillaAppServices.createCanary
import func MozillaAppServices.createKey

public enum LoginEncryptionKeyError: Error {
    case noKeyCreated
    case illegalState
    case dbRecordCountVerificationError(String)
}

/// Running tests on Bitrise code that reads/writes to keychain silently fails.
/// SecItemAdd status: -34018 - A required entitlement isn't present.
/// This should be removed if we ever have keychain support on our CI.
public class KeychainManager {
    public static var shared = {
        AppConstants.isRunningTest
            ? MockRustKeychain.shared
            : RustKeychain.sharedClientAppContainerKeychain
    }()

    public static var legacyShared = {
        AppConstants.isRunningTest
            ? MockMZKeychainWrapper.shared
            : MZKeychainWrapper.sharedClientAppContainerKeychain
    }()
}

open class RustKeychain {
    public private(set) var serviceName: String
    public private(set) var accessGroup: String?

    private let logger: Logger

    public let loginsKeyIdentifier = "appservices.key.logins.perfield"
    public let loginsCanaryKeyIdentifier = "canaryPhrase"
    let loginsCanaryPhrase = "a string for checking validity of the key"

    public let creditCardKeyIdentifier = "appservices.key.creditcard.perfield"
    public let creditCardCanaryKeyIdentifier = "creditCardCanaryPhrase"
    let creditCardCanaryPhrase = "a string for checking validity of the key"

    public static var sharedClientAppContainerKeychain: RustKeychain {
        let baseBundleIdentifier = AppInfo.baseBundleIdentifier

        guard let accessGroupPrefix = Bundle.main.object(forInfoDictionaryKey: "MozDevelopmentTeam") as? String else {
            return RustKeychain(serviceName: baseBundleIdentifier)
        }
        return RustKeychain(serviceName: baseBundleIdentifier,
                            accessGroup: AppInfo.keychainAccessGroupWithPrefix(accessGroupPrefix))
    }

    public init(serviceName: String,
                accessGroup: String? = nil,
                logger: Logger = DefaultLogger.shared) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
        self.logger = logger
    }

    struct KeychainError: Error {
        let errorMessage: String
    }

    public func removeObject(key: String) {
        let keychainQueryDictionary: [String: Any] = getBaseKeychainQuery(key: key)
        let status = SecItemDelete(keychainQueryDictionary as CFDictionary)
        logErrorFromStatus(status, errMsg: "Failed to remove key \(key)")
    }

    public func removeAllKeys() {
        var keychainQueryDictionary: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                                      kSecAttrService as String: serviceName]

        if let accessGroup = self.accessGroup {
            keychainQueryDictionary[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = SecItemDelete(keychainQueryDictionary as CFDictionary)
        logErrorFromStatus(status, errMsg: "Failed to remove all keys")
    }

    public func setLoginsKeyData(keyValue: String, canaryValue: String) {
        addOrUpdateKeychainKey(keyValue, key: loginsKeyIdentifier)
        addOrUpdateKeychainKey(canaryValue, key: loginsCanaryKeyIdentifier)
    }

    public func setCreditCardsKeyData(keyValue: String, canaryValue: String) {
        addOrUpdateKeychainKey(keyValue, key: creditCardKeyIdentifier)
        addOrUpdateKeychainKey(canaryValue, key: creditCardCanaryKeyIdentifier)
    }

    public func getLoginsKeyData() -> (String?, String?) {
        return getEncryptionKeyData(keyIdentifier: loginsKeyIdentifier, canaryKeyIdentifier: loginsCanaryKeyIdentifier)
    }

    public func getCreditCardKeyData() -> (String?, String?) {
        return getEncryptionKeyData(keyIdentifier: creditCardKeyIdentifier,
                                    canaryKeyIdentifier: creditCardCanaryKeyIdentifier)
    }

    public class func wipeKeychain() {
        deleteKeychainSecClass(kSecClassGenericPassword) // Generic password items
        deleteKeychainSecClass(kSecClassInternetPassword) // Internet password items
        deleteKeychainSecClass(kSecClassCertificate) // Certificate items
        deleteKeychainSecClass(kSecClassKey) // Cryptographic key items
        deleteKeychainSecClass(kSecClassIdentity) // Identity items
    }

    func logAutofillStoreError(err: AutofillApiError, errorDomain: String? = nil, errorMessage: String) {
        var message: String {
            switch err {
            case .SqlError(let message),
                    .CryptoError(let message),
                    .NoSuchRecord(let message),
                    .UnexpectedAutofillApiError(let message):
                return message
            case .InterruptedError:
                return "Interrupted Error"
            }
        }

        let description = errorDomain == nil ?
                            "\(err.descriptionValue): \(message)" :
                            "\(errorDomain ?? "") - \(err.descriptionValue): \(message)"

        logger.log(errorMessage,
                   level: .warning,
                   category: .storage,
                   description: description)
    }

    func createCreditCardsKeyData() throws -> String {
        do {
            return try createAndStoreKey(canaryPhrase: creditCardCanaryPhrase,
                                         canaryIdentifier: creditCardCanaryKeyIdentifier,
                                         keyIdentifier: creditCardKeyIdentifier)
        } catch let err as AutofillApiError {
            logAutofillStoreError(err: err,
                                  errorMessage: "Error while creating and storing credit card key")
       } catch {
            logger.log("Unknown error while creating and storing credit card key",
                       level: .warning,
                       category: .storage,
                       description: error.localizedDescription)
        }
        throw LoginEncryptionKeyError.noKeyCreated
    }

    func createLoginsKeyData() throws -> String {
        do {
            return try createAndStoreKey(canaryPhrase: loginsCanaryPhrase,
                                         canaryIdentifier: loginsCanaryKeyIdentifier,
                                         keyIdentifier: loginsKeyIdentifier)
        } catch let err as NSError {
            if let loginsStoreError = err as? LoginsStoreError {
                logLoginsStoreError(err: loginsStoreError,
                                    errorDomain: err.domain,
                                    errorMessage: "Error while creating and storing logins key")
            } else {
                logger.log("Unknown error while creating and storing logins key",
                           level: .warning,
                           category: .storage,
                           description: err.localizedDescription)
            }
        }
        throw LoginEncryptionKeyError.noKeyCreated
    }

    func queryKeychainForKey(key: String) -> Result<String?, Error> {
        var keychainQueryDictionary = getBaseKeychainQuery(key: key)
        keychainQueryDictionary[kSecMatchLimit as String] = kSecMatchLimitOne
        keychainQueryDictionary[kSecReturnData as String] = kCFBooleanTrue

        var queryResult: AnyObject?
        let status = SecItemCopyMatching(keychainQueryDictionary as CFDictionary, &queryResult)

        guard status == noErr else {
            let errMsg = SecCopyErrorMessageString(status, nil)
            return .failure(KeychainError(errorMessage: errMsg as? String ?? ""))
        }

        guard let data = queryResult as? Data else {
            return .failure(KeychainError(errorMessage: "Unable to encode query result"))
        }

        return .success(String(data: data, encoding: .utf8))
    }

    func createAndStoreKey(canaryPhrase: String, canaryIdentifier: String, keyIdentifier: String) throws -> String {
         let keyValue = try createKey()
         let canaryValue = try createCanary(text: canaryPhrase, encryptionKey: keyValue)

         DispatchQueue.global(qos: .background).sync {
             addOrUpdateKeychainKey(keyValue, key: keyIdentifier)
             addOrUpdateKeychainKey(canaryValue, key: canaryIdentifier)
         }
         return keyValue
    }

    private class func deleteKeychainSecClass(_ secClass: AnyObject) {
        let query = [kSecClass as String: secClass]
        SecItemDelete(query as CFDictionary)
    }

    private func addOrUpdateKeychainKey(_ value: String, key: String) {
        var addQueryDictionary = getBaseKeychainQuery(key: key)
        addQueryDictionary[kSecValueData as String] = value.data(using: String.Encoding.utf8)
        addQueryDictionary[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let addStatus = SecItemAdd(addQueryDictionary as CFDictionary, nil)

        if addStatus == errSecDuplicateItem {
            let updateStatus = SecItemUpdate(getBaseKeychainQuery(key: key) as CFDictionary,
                                             [kSecValueData: value.data(using: String.Encoding.utf8)] as CFDictionary)
            if updateStatus != errSecSuccess {
                logErrorFromStatus(updateStatus, errMsg: "Failed to update \(key) keychain key")
            }
        } else {
            logErrorFromStatus(addStatus, errMsg: "Failed to add \(key) keychain key")
        }
    }

    private func getEncryptionKeyData(keyIdentifier: String, canaryKeyIdentifier: String) -> (String?, String?) {
        var keychainData: (String?, String?) = (nil, nil)

        DispatchQueue.global(qos: .background).sync {
            let key = getDataFromResult(queryKeychainForKey(key: keyIdentifier))
            let canary = getDataFromResult(queryKeychainForKey(key: canaryKeyIdentifier))

            keychainData = (key, canary)
        }
        return keychainData
    }

    private func getDataFromResult(_ result: Result<String?, Error>) -> String? {
        switch result {
        case .success(let value):
            guard let data = value else {
                return nil
            }
            return data
        case .failure(let err):
            // This failure could be the result of failing to retrieve saved keychain
            // data or querying for key data that hasn't been created yet in the case
            // of a first-time sync sign in for instance.

            logger.log("Failed to get keychain data: \(err)",
                       level: .debug,
                       category: .storage)
            return nil
        }
    }

    private func getBaseKeychainQuery(key: String) -> [String: Any] {
        let encodedIdentifier: Data? = key.data(using: String.Encoding.utf8)
        var keychainQueryDictionary: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                                       kSecAttrService as String: self.serviceName,
                                                       kSecAttrSynchronizable as String: false]
        keychainQueryDictionary[kSecAttrGeneric as String] = encodedIdentifier
        keychainQueryDictionary[kSecAttrAccount as String] = encodedIdentifier

        if let accessGroup = self.accessGroup {
            keychainQueryDictionary[kSecAttrAccessGroup as String] = accessGroup
        }
        return keychainQueryDictionary
    }

    private func logErrorFromStatus(_ status: OSStatus, errMsg: String) {
        guard status != errSecSuccess else {
            return
        }
        let result = SecCopyErrorMessageString(status, nil)
        let defaultMsg = "Unknown Error"
        let detailedMsg = result == nil ? defaultMsg : result as? String ?? defaultMsg

        self.logger.log("\(errMsg): \(detailedMsg)",
                        level: .warning,
                        category: .storage)
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
