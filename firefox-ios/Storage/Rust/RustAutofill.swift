// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
@_exported import MozillaAppServices
import Common

/// Typealias for AutofillStore.
typealias AutofillStore = Store

/// Enum representing errors related to Autofill encryption keys.
public enum AutofillEncryptionKeyError: Error {
    /// Indicates an illegal state error.
    case illegalState
    /// Indicates that no key was created.
    case noKeyCreated
}

public class RustAutofill {
    /// The path to the Autofill database file.
    let databasePath: String
    /// DispatchQueue for synchronization.
    let queue: DispatchQueue
    /// AutofillStore instance.
    var storage: AutofillStore?

    private(set) var isOpen = false
    private var didAttemptToMoveToBackup = false
    private let logger: Logger

    // MARK: - Initialization

    /// Initializes a new RustAutofill instance.
    ///
    /// - Parameters:
    ///   - databasePath: The path to the Autofill database file.
    ///   - logger: An optional logger for recording informational and error messages. Default is shared DefaultLogger.
    public init(databasePath: String, logger: Logger = DefaultLogger.shared) {
        self.databasePath = databasePath
        queue = DispatchQueue(label: "RustAutofill queue: \(databasePath)")
        self.logger = logger
    }

    // MARK: - Database Operations

    /// Opens the Autofill database.
    ///
    /// - Returns: An optional NSError if an error occurs during the database opening process.
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

    /// Closes the Autofill database.
    ///
    /// - Returns: An optional NSError if an error occurs during the database closing process.
    internal func close() -> NSError? {
        storage = nil
        isOpen = false
        return nil
    }

    /// Reopens the database if it is closed.
    ///
    /// - Returns: An optional NSError if an error occurs during the reopening process.
    public func reopenIfClosed() -> NSError? {
        var error: NSError?
        queue.sync {
            guard !isOpen else { return }
            error = open()
        }
        return error
    }

    /// Forces the database to close.
    ///
    /// - Returns: An optional NSError if an error occurs during the closing process.
    public func forceClose() -> NSError? {
        var error: NSError?
        queue.sync {
            guard isOpen else { return }
            error = close()
        }
        return error
    }

    /// Adds a credit card to the database.
    ///
    /// - Parameters:
    ///   - creditCard: UnencryptedCreditCardFields representing the credit card to be added.
    ///   - completion: A closure called upon completion with the added credit card or an error.
    /// - Note: Uses a completion handler for asynchronous code execution.
    public func addCreditCard(
        creditCard: UnencryptedCreditCardFields,
        completion: @escaping (CreditCard?, Error?) -> Void
    ) {
        performDatabaseOperation { error in
            guard error == nil else {
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

    /// Decrypts a credit card number using RustAutofillEncryptionKeys.
    ///
    /// - Parameter encryptedCCNum: The encrypted credit card number.
    /// - Returns: The decrypted credit card number or nil if the input is invalid.
    /// - Note: Uses guard statements and optionals effectively, following Swift best practices.
    public func decryptCreditCardNumber(encryptedCCNum: String?) -> String? {
        guard let encryptedCCNum = encryptedCCNum, !encryptedCCNum.isEmpty else {
            return nil
        }
        let keys = RustAutofillEncryptionKeys()
        return keys.decryptCreditCardNum(encryptedCCNum: encryptedCCNum)
    }

    /// Retrieves a credit card from the database by its identifier.
    ///
    /// - Parameters:
    ///   - id: The identifier of the credit card.
    ///   - completion: A closure called upon completion with the retrieved credit card or an error.
    /// - Note: Follows the common pattern of using completion handlers for asynchronous tasks.
    public func getCreditCard(id: String, completion: @escaping (CreditCard?, Error?) -> Void) {
        performDatabaseOperation { error in
            guard error == nil else {
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

    /// Retrieves all credit cards from the database.
    ///
    /// - Parameter completion: A closure called upon completion with the list of credit cards or an error.
    /// - Note: Uses a completion handler for handling asynchronous code execution.
    public func listCreditCards(completion: @escaping ([CreditCard]?, Error?) -> Void) {
        performDatabaseOperation { error in
            guard error == nil else {
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

    /// Checks for the existence of a credit card in the database.
    ///
    /// - Parameters:
    ///   - cardNumber: The last four digits of the credit card.
    ///   - completion: A closure called upon completion with the found credit card or an error.
    /// - Note: Checks for the existence of a credit card and uses a completion handler for result reporting.
    public func checkForCreditCardExistance(cardNumber: String, completion: @escaping (CreditCard?, Error?) -> Void) {
        performDatabaseOperation { error in
            guard error == nil else {
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

    /// Updates a credit card in the database.
    ///
    /// - Parameters:
    ///   - id: The identifier of the credit card to be updated.
    ///   - creditCard: UnencryptedCreditCardFields representing the updated credit card details.
    ///   - completion: A closure called upon completion with a boolean indicating success and an error if any.
    /// - Note: Updates a credit card and reports the result using a completion handler.
    public func updateCreditCard(
        id: String,
        creditCard: UnencryptedCreditCardFields,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        performDatabaseOperation { error in
            guard error == nil else {
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

    /// Deletes a credit card from the database.
    ///
    /// - Parameters:
    ///   - id: The identifier of the credit card to be deleted.
    ///   - completion: A closure called upon completion with a boolean indicating success and an error if any.
    /// - Note: Deletes a credit card and reports the result using a completion handler.
    public func deleteCreditCard(id: String, completion: @escaping (Bool, Error?) -> Void) {
        performDatabaseOperation { error in
            guard error == nil else {
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

    /// Marks a credit card as used in the database.
    ///
    /// - Parameters:
    ///   - creditCard: The credit card to be marked as used.
    ///   - completion: A closure called upon completion with a boolean indicating success and an error if any.
    /// - Note: Marks a credit card as used and reports the result using a completion handler.
    public func use(creditCard: CreditCard, completion: @escaping (Bool, Error?) -> Void) {
        performDatabaseOperation { error in
            guard error == nil else {
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

    /// Performs an operation to scrub encrypted credit card numbers from the database.
    ///
    /// - Parameter completion: A closure called upon completion with a boolean indicating success and an error if any.
    /// - Note: Scrubs encrypted credit card numbers and reports the result using a completion handler.
    public func scrubCreditCardNums(completion: @escaping (Bool, Error?) -> Void) {
        performDatabaseOperation { error in
            guard error == nil else {
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

    /// Adds an address to the database.
    ///
    /// - Parameters:
    ///   - address: UpdatableAddressFields representing the address to be added.
    ///   - completion: A closure called upon completion with the added address or an error.
    public func addAddress(address: UpdatableAddressFields, completion: @escaping (Address?, Error?) -> Void) {
        performDatabaseOperation { error in
            guard error == nil else {
                completion(nil, error)
                return
            }
            do {
                // Use optional binding to safely unwrap the optional result of addAddress.
                if let id = try self.storage?.addAddress(a: address) {
                    // Successfully added the address, call the completion handler with the result.
                    completion(id, nil)
                } else {
                    // Handle the case where addAddress returns nil, possibly due to an internal error.
                    let internalError = NSError(domain: "YourDomain", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Internal error: Failed to add address."
                    ])
                    completion(nil, internalError)
                }
            } catch let err as NSError {
                // Handle any other errors that might occur during the database operation.
                completion(nil, err)
            }
        }
    }

    /// Retrieves an address from the database by its identifier.
    ///
    /// - Parameters:
    ///   - id: The identifier of the address.
    ///   - completion: A closure called upon completion with the retrieved address or an error.
    public func getAddress(id: String, completion: @escaping (Address?, Error?) -> Void) {
        performDatabaseOperation { error in
            guard error == nil else {
                completion(nil, error)
                return
            }
            do {
                // Use optional binding to safely unwrap the optional result of getAddress.
                if let record = try self.storage?.getAddress(guid: id) {
                    // Successfully retrieved the address, call the completion handler with the result.
                    completion(record, nil)
                } else {
                    // Handle the case where getAddress returns nil, possibly due to a missing record.
                    let missingRecordError = NSError(domain: "YourDomain", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "Record with id \(id) not found."
                    ])
                    completion(nil, missingRecordError)
                }
            } catch let err as NSError {
                // Handle any other errors that might occur during the database operation.
                completion(nil, err)
            }
        }
    }

    /// Retrieves all addresses from the database.
    ///
    /// - Parameter completion: A closure called upon completion with the list of addresses or an error.
    /// - Note: Uses a completion handler for handling asynchronous code execution.
    public func listAllAddresses(completion: @escaping ([Address]?, Error?) -> Void) {
        performDatabaseOperation { error in
            guard error == nil else {
                completion(nil, error)
                return
            }
            do {
                let records = try self.storage?.getAllAddresses()
                completion(records, nil)
            } catch let error {
                completion(nil, error)
            }
        }
    }

    // MARK: - Sync Manager Interaction

    /// Asynchronously registers the instance with a sync manager.
    ///
    /// - Note: Uses `async` to perform the operation asynchronously.
    public func registerWithSyncManager() {
        queue.async { [unowned self] in
            self.storage?.registerWithSyncManager()
        }
    }

    // MARK: - Key Management

    /// Retrieves the stored encryption key.
    /// - Throws: An error if there is an issue retrieving the key.
    /// - Returns: The retrieved encryption key.
    /// - Note: Uses Swift's `throws` for error handling, providing a clear indication of potential failures.
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
