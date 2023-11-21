// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
@_exported import MozillaAppServices
import Common

typealias AutofillStore = Store

public enum AutofillEncryptionKeyError: Error {
    case illegalState
    case noKeyCreated
}

public class RustAutofill {
    let databasePath: String
    let queue: DispatchQueue
    var storage: AutofillStore?

    private(set) var isOpen = false
    private var didAttemptToMoveToBackup = false
    private let logger: Logger

    public init(databasePath: String, logger: Logger = DefaultLogger.shared) {
        self.databasePath = databasePath
        queue = DispatchQueue(label: "RustAutofill queue: \(databasePath)")
        self.logger = logger
    }

    internal func open() -> NSError? {
        do {
            try getStoredKey()
            storage = try AutofillStore(dbpath: databasePath)
            isOpen = true
            return nil
        } catch let err as NSError {
            handleDatabaseError(err)
            return err
        }
    }

    internal func close() -> NSError? {
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
        performDatabaseOperation { error in
            if let error = error {
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

    public func decryptCreditCardNumber(encryptedCCNum: String?) -> String? {
        guard let encryptedCCNum = encryptedCCNum, !encryptedCCNum.isEmpty else {
            return nil
        }
        let keys = RustAutofillEncryptionKeys()
        return keys.decryptCreditCardNum(encryptedCCNum: encryptedCCNum)
    }

    public func getCreditCard(id: String, completion: @escaping (CreditCard?, Error?) -> Void) {
        performDatabaseOperation { error in
            if let error = error {
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
        performDatabaseOperation { error in
            if let error = error {
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

    public func checkForCreditCardExistance(cardNumber: String, completion: @escaping (CreditCard?, Error?) -> Void) {
        performDatabaseOperation { error in
            if let error = error {
                completion(nil, error)
                return
            }
            do {
                guard let records = try self.storage?.getAllCreditCards(),
                      let foundCard = records.first(where: { $0.ccNumberLast4 == cardNumber })
                else {
                    completion(nil, nil)
                    return
                }
                completion(foundCard, nil)
            } catch let err as NSError {
                completion(nil, err)
            }
        }
    }

    public func updateCreditCard(id: String, creditCard: UnencryptedCreditCardFields, completion: @escaping (Bool, Error?) -> Void) {
        performDatabaseOperation { error in
            if let error = error {
                completion(false, error)
                return
            }
            do {
                try self.storage?.updateCreditCard(
                    guid: id,
                    cc: creditCard.toUpdatableCreditCardFields()
                )
                completion(true, nil)
            } catch let err as NSError {
                completion(false, err)
            }
        }
    }

    public func deleteCreditCard(id: String, completion: @escaping (Bool, Error?) -> Void) {
        performDatabaseOperation { error in
            if let error = error {
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
        performDatabaseOperation { error in
            if let error = error {
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
        performDatabaseOperation { error in
            if let error = error {
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

    public func registerWithSyncManager() {
        queue.async { [unowned self] in
            self.storage?.registerWithSyncManager()
        }
    }

    @discardableResult
    public func getStoredKey() throws -> String {
        let rustKeys = RustAutofillEncryptionKeys()
        let key = rustKeys.keychain.string(forKey: rustKeys.ccKeychainKey)
        let encryptedCanaryPhrase = rustKeys.keychain.string(
            forKey: rustKeys.ccCanaryPhraseKey
        )

        switch (key, encryptedCanaryPhrase) {
        case (.some(let key), .some(let encryptedCanaryPhrase)):
            // We expected the key to be present, and it is.
            do {
                let canaryIsValid = try rustKeys.checkCanary(
                    canary: encryptedCanaryPhrase,
                    text: rustKeys.canaryPhrase,
                    key: key
                )
                if canaryIsValid {
                    return key
                } else {
                    handleKeyCorruption()
                    return try rustKeys.createAndStoreKey()
                }
            } catch let error as NSError {
                logger.log("Error retrieving autofill encryption key",
                           level: .warning,
                           category: .storage,
                           description: error.localizedDescription)
            }
        case (.some(key), .none), (.none, .some(encryptedCanaryPhrase)):
            // The key is present, but we didn't expect it to be there.
            // or
            // We expected the key to be present, but it's gone missing on us
            do {
                handleKeyLoss()
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

    // MARK: - Private Helper Methods

    private func handleDatabaseError(_ error: NSError) {
        // This is an unrecoverable state unless we can move the existing file to a backup
        // location and start over.
        if let autofillStoreError = error as? AutofillApiError {
            logger.log("Rust Autofill store error when opening database",
                       level: .warning,
                       category: .storage,
                       description: autofillStoreError.localizedDescription)
        } else {
            logger.log("Unknown error when opening Rust Autofill database",
                       level: .warning,
                       category: .storage,
                       description: error.localizedDescription)
        }

        if !didAttemptToMoveToBackup {
            RustShared.moveDatabaseFileToBackupLocation(databasePath: self.databasePath)
            didAttemptToMoveToBackup = true
            _ = open()
        }
    }

    private func performDatabaseOperation(_ operation: @escaping (Error?) -> Void) {
        queue.async {
            guard self.isOpen else {
                let error = AutofillApiError.UnexpectedAutofillApiError(
                    reason: "Database is closed")
                operation(error)
                return
            }
            operation(nil)
        }
    }

    private func handleKeyCorruption() {
        logger.log("Autofill key was corrupted, new one generated",
                   level: .warning,
                   category: .storage)
        scrubCreditCardNums(completion: { _, _ in })
    }

    private func handleKeyLoss() {
        logger.log("Autofill key lost, new one generated",
                   level: .warning,
                   category: .storage)
        scrubCreditCardNums(completion: { _, _ in })
    }
}
