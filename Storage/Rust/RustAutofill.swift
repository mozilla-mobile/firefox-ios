// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
@_exported import MozillaAppServices

typealias AutofillStore = Store

public extension AutofillApiError {
    var descriptionValue: String {
        switch self {
        case .SqlError: return "SqlError"
        case .CryptoError: return "CryptoError"
        case .NoSuchRecord: return "NoSuchRecord"
        case .UnexpectedAutofillApiError: return "UnexpectedAutofillApiError"
        case .InterruptedError: return "InterruptedError"
        }
    }
}

public enum AutofillEncryptionKeyError: Error {
    case illegalState
    case noKeyCreated
}

// Note: This was created in lieu of a view model
public struct UnencryptedCreditCardFields {
    public var ccName: String
    public var ccNumber: String
    public var ccNumberLast4: String
    public var ccExpMonth: Int64
    public var ccExpYear: Int64
    public var ccType: String

    func toUpdatableCreditCardFields() -> UpdatableCreditCardFields {
        let rustKeys = RustAutofillEncryptionKeys()
        let ccNumberEnc = rustKeys.encryptCreditCardNum(creditCardNum: self.ccNumber)
        return UpdatableCreditCardFields(ccName: self.ccName,
                                         ccNumberEnc: ccNumberEnc ?? "",
                                         ccNumberLast4: self.ccNumberLast4,
                                         ccExpMonth: self.ccExpMonth,
                                         ccExpYear: self.ccExpYear,
                                         ccType: self.ccType)
    }
}

public class RustAutofillEncryptionKeys {
    public let ccKeychainKey = "appservices.key.creditcard.perfield"

    let keychain: MZKeychainWrapper = MZKeychainWrapper.sharedClientAppContainerKeychain
    let ccCanaryPhraseKey = "creditCardCanaryPhrase"
    let canaryPhrase = "a string for checking validity of the key"

    public init() {}

    fileprivate func createAndStoreKey() throws -> String {
        do {
            let secret = try createAutofillKey()
            let canary = try self.createCanary(text: canaryPhrase, key: secret)

            keychain.set(secret,
                         forKey: ccKeychainKey,
                         withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)
            keychain.set(canary,
                         forKey: ccCanaryPhraseKey,
                         withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)

            return secret
        } catch let err as NSError {
            if let autofillStoreError = err as? AutofillApiError {
                sendAutofillStoreErrorToSentry(err: autofillStoreError,
                                               errorDomain: err.domain,
                                               errorMessage: "Error while creating and storing credit card key")

                throw AutofillEncryptionKeyError.noKeyCreated
            } else {
                SentryIntegration.shared.sendWithStacktrace(message: "Unknown error while creating and storing credit card key",
                                                            tag: SentryTag.rustAutofill,
                                                            severity: .error,
                                                            description: err.localizedDescription)

                throw AutofillEncryptionKeyError.noKeyCreated
            }
        }
    }

    func decryptCreditCardNum(encryptedCCNum: String) -> String? {
        guard let key = self.keychain.string(forKey: self.ccKeychainKey) else {
            return nil
        }

        do {
            return try decryptString(key: key, ciphertext: encryptedCCNum)
        } catch let err as NSError {
            if let autofillStoreError = err as? AutofillApiError {
                sendAutofillStoreErrorToSentry(err: autofillStoreError,
                                               errorDomain: err.domain,
                                               errorMessage: "Error while decrypting credit card")
            } else {
                SentryIntegration.shared.sendWithStacktrace(message: "Unknown error while decrypting credit card",
                                                            tag: SentryTag.rustAutofill,
                                                            severity: .error,
                                                            description: err.localizedDescription)
            }
            return nil
        }
    }

    fileprivate func checkCanary(canary: String,
                                 text: String,
                                 key: String) throws -> Bool {
        return try decryptString(key: key, ciphertext: canary) == text
    }

    func encryptCreditCardNum(creditCardNum: String) -> String? {
        guard let key = self.keychain.string(forKey: self.ccKeychainKey) else {
            return nil
        }

        do {
            return try encryptString(key: key, cleartext: creditCardNum)
        } catch let err as NSError {
            if let autofillStoreError = err as? AutofillApiError {
                sendAutofillStoreErrorToSentry(err: autofillStoreError,
                                               errorDomain: err.domain,
                                               errorMessage: "Error while encrypting credit card")
            } else {
                SentryIntegration.shared.sendWithStacktrace(message: "Unknown error while encrypting credit card",
                                                            tag: SentryTag.rustAutofill,
                                                            severity: .error,
                                                            description: err.localizedDescription)
            }
        }
        return nil
    }

    fileprivate func createCanary(text: String,
                                  key: String) throws -> String {
        return try encryptString(key: key, cleartext: text)
    }

    private func sendAutofillStoreErrorToSentry(err: AutofillApiError,
                                                errorDomain: String,
                                                errorMessage: String) {
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

        SentryIntegration.shared.sendWithStacktrace(
            message: errorMessage,
            tag: SentryTag.rustAutofill,
            severity: .error,
            description: "\(errorDomain) - \(err.descriptionValue): \(message)")
    }
}

public class RustAutofill {
    let databasePath: String

    let queue: DispatchQueue
    var storage: AutofillStore?

    private(set) var isOpen = false

    private var didAttemptToMoveToBackup = false

    public init(databasePath: String) {
        self.databasePath = databasePath

        queue = DispatchQueue(label: "RustAutofill queue: \(databasePath)",
                              attributes: [])
    }

    private func open() -> NSError? {
        do {
            try getStoredKey()
            storage = try AutofillStore(dbpath: databasePath)
            isOpen = true
            return nil
        } catch let err as NSError {
            if let autofillStoreError = err as? AutofillApiError {
                // This is an unrecoverable
                // state unless we can move the existing file to a backup
                // location and start over.
                SentryIntegration.shared.sendWithStacktrace(
                    message: "Rust Autofill store error when opening database",
                    tag: SentryTag.rustAutofill,
                    severity: .error,
                    description: autofillStoreError.localizedDescription)
            } else {
                SentryIntegration.shared.sendWithStacktrace(
                    message: "Unknown error when opening Rust Autofill database",
                    tag: SentryTag.rustAutofill,
                    severity: .error,
                    description: err.localizedDescription)
            }

            if !didAttemptToMoveToBackup {
                RustShared.moveDatabaseFileToBackupLocation(
                    databasePath: self.databasePath)
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

    public func addCreditCard(creditCard: UnencryptedCreditCardFields, completion: @escaping (CreditCard?, Error?) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = AutofillApiError.UnexpectedAutofillApiError(
                    reason: "Database is closed")
                completion(nil, error)
                return
            }

            do {
                let id = try self.storage?.addCreditCard(cc: creditCard.toUpdatableCreditCardFields())
                completion(id!, nil)
            } catch let err as NSError {
                completion(nil, err)
            }
        }
    }

    public func getCreditCard(id: String, completion: @escaping (CreditCard?, Error?) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = AutofillApiError.UnexpectedAutofillApiError(
                    reason: "Database is closed")
                completion(nil, error)
                return
            }

            do {
                let record = try self.storage?.getCreditCard(guid: id)
                completion(record, nil)
            } catch let err as NSError {
                completion(nil, err)
            }
        }
    }

    public func listCreditCards(completion: @escaping ([CreditCard]?, Error?) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = AutofillApiError.UnexpectedAutofillApiError(
                    reason: "Database is closed")
                completion(nil, error)
                return
            }

            do {
                let records = try self.storage?.getAllCreditCards()
                completion(records, nil)
            } catch let err as NSError {
                completion(nil, err)
            }
        }
    }

    public func updateCreditCard(id: String, creditCard: UnencryptedCreditCardFields, completion: @escaping (Bool, Error?) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = AutofillApiError.UnexpectedAutofillApiError(
                    reason: "Database is closed")
                completion(false, error)
                return
            }

            do {
                try self.storage?.updateCreditCard(
                    guid: id,
                    cc: creditCard.toUpdatableCreditCardFields())
                completion(true, nil)
            } catch let err as NSError {
                completion(false, err)
            }
        }
    }

    public func deleteCreditCard(id: String, completion: @escaping (Bool, Error?) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = AutofillApiError.UnexpectedAutofillApiError(
                    reason: "Database is closed")
                completion(false, error)
                return
            }

            do {
                let existed = try self.storage?.deleteCreditCard(guid: id)
                completion(existed!, nil)
            } catch let err as NSError {
                completion(false, err)
            }
        }
    }

    public func use(creditCard: CreditCard, completion: @escaping (Bool, Error?) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = AutofillApiError.UnexpectedAutofillApiError(
                    reason: "Database is closed")
                completion(false, error)
                return
            }

            do {
                try self.storage?.touchCreditCard(guid: creditCard.guid)
                completion(true, nil)
            } catch let err as NSError {
                completion(false, err)
            }
        }
    }

    public func scrubCreditCardNums(completion: @escaping (Bool, Error?) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = AutofillApiError.UnexpectedAutofillApiError(
                    reason: "Database is closed")
                completion(false, error)
                return
            }

            do {
                try self.storage?.scrubEncryptedData()
                completion(true, nil)
            } catch let err as NSError {
                completion(false, err)
            }
        }
    }

    @discardableResult
    public func getStoredKey() throws -> String {
        let rustKeys = RustAutofillEncryptionKeys()
        let key = rustKeys.keychain.string(forKey: rustKeys.ccKeychainKey)
        let encryptedCanaryPhrase = rustKeys.keychain.string(
            forKey: rustKeys.canaryPhrase)

        switch(key, encryptedCanaryPhrase) {
        case (.some(key), .some(encryptedCanaryPhrase)):
            // We expected the key to be present, and it is.
            do {
                let canaryIsValid = try rustKeys.checkCanary(
                    canary: encryptedCanaryPhrase!,
                    text: rustKeys.canaryPhrase,
                    key: key!)
                if canaryIsValid {
                    return key!
                } else {
                    SentryIntegration.shared.sendWithStacktrace(
                        message: "Autofill key was corrupted, new one generated",
                        tag: SentryTag.rustAutofill,
                        severity: .warning)

                    self.scrubCreditCardNums(completion: {_, _ in })
                    return try rustKeys.createAndStoreKey()
                }
            } catch let error as NSError {
                SentryIntegration.shared.sendWithStacktrace(
                    message: "Error retrieving autofill encryption key",
                    tag: SentryTag.rustAutofill,
                    severity: .error,
                    description: error.localizedDescription)
            }
        case (.some(key), .none):
            // The key is present, but we didn't expect it to be there.
            do {
                SentryIntegration.shared.sendWithStacktrace(
                    message: "Autofill key lost due to storage malfunction, new one generated",
                    tag: SentryTag.rustAutofill,
                    severity: .warning)

                self.scrubCreditCardNums(completion: {_, _ in })
                return try rustKeys.createAndStoreKey()
            } catch let error as NSError {
                throw error
            }
        case (.none, .some(encryptedCanaryPhrase)):
            // We expected the key to be present, but it's gone missing on us.
            do {
                SentryIntegration.shared.sendWithStacktrace(
                    message: "Autofill key lost, new one generated",
                    tag: SentryTag.rustAutofill,
                    severity: .warning)

                self.scrubCreditCardNums(completion: {_, _ in })
                return try rustKeys.createAndStoreKey()
            } catch let error as NSError {
                throw error
            }
        case (.none, .none):
            // We didn't expect the key to be present, and it's not (which is the case for
            // first-time calls).
            do {
                return try rustKeys.createAndStoreKey()
            } catch let error as NSError {
                throw error
            }
        default:
            // If none of the above cases apply, we're in a state that shouldn't be possible
            // but is disallowed nonetheless
            throw AutofillEncryptionKeyError.illegalState
        }

        // This must be declared again for Swift's sake even though the above switch statement
        // handles all cases
        throw AutofillEncryptionKeyError.illegalState
    }
}
