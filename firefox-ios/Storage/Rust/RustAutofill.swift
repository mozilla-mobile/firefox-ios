// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Glean

import class MozillaAppServices.Store
import enum MozillaAppServices.AutofillApiError
import func MozillaAppServices.encryptString
import struct MozillaAppServices.Address
import struct MozillaAppServices.CreditCard
import struct MozillaAppServices.UpdatableAddressFields
import struct MozillaAppServices.UpdatableCreditCardFields

/// Typealias for AutofillStore.
typealias AutofillStore = Store

/// Enum representing errors related to Autofill encryption keys.
public enum AutofillEncryptionKeyError: Error {
    /// Indicates an illegal state error.
    case illegalState
    /// Indicates that no key was created.
    case noKeyCreated
}

// TODO: FXIOS-13161 - refactor this to ensure it's actually thread safe and remove @unchecked Sendable
public class RustAutofill: @unchecked Sendable {
    /// The path to the Autofill database file.
    let databasePath: String
    /// DispatchQueue for synchronization.
    let queue: DispatchQueue
    /// Shared rust keychain for credit card encryption/decryption.
    let rustKeychain = KeychainManager.shared
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
    public init(databasePath: String,
                logger: Logger = DefaultLogger.shared) {
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
        completion: @escaping @Sendable (CreditCard?, Error?) -> Void
    ) {
        performDatabaseOperation { error in
            guard error == nil else {
                completion(nil, error)
                return
            }

            self.encryptCreditCard(creditCard: creditCard) { result in
                switch result {
                case .success(let encCreditCard):
                    do {
                        let card = try self.storage?.addCreditCard(cc: encCreditCard)
                        completion(card, nil)
                    } catch let err as NSError {
                        completion(nil, err)
                    }
                case .failure(let err):
                    completion(nil, err)
                }
            }
        }
    }

    /// Decrypts a credit card number using RustKeychain.
    ///
    /// - Parameter encryptedCCNum: The encrypted credit card number.
    /// - Returns: The decrypted credit card number or nil if the input is invalid.
    /// - Note: Uses guard statements and optionals effectively, following Swift best practices.
    public func decryptCreditCardNumber(encryptedCCNum: String?) -> String? {
        guard let encryptedCCNum = encryptedCCNum, !encryptedCCNum.isEmpty else {
            return nil
        }
        return rustKeychain.decryptCreditCardNum(encryptedCCNum: encryptedCCNum)
    }

    /// Retrieves a credit card from the database by its identifier.
    ///
    /// - Parameters:
    ///   - id: The identifier of the credit card.
    ///   - completion: A closure called upon completion with the retrieved credit card or an error.
    /// - Note: Follows the common pattern of using completion handlers for asynchronous tasks.
    public func getCreditCard(id: String, completion: @escaping @Sendable (CreditCard?, Error?) -> Void) {
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
    public func listCreditCards(completion: @escaping @Sendable ([CreditCard]?, Error?) -> Void) {
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
    public func checkForCreditCardExistance(
        cardNumber: String,
        completion: @escaping @Sendable (CreditCard?, Error?) -> Void) {
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
        completion: @escaping @Sendable (Bool?, Error?) -> Void
    ) {
        performDatabaseOperation { error in
            guard error == nil else {
                completion(false, error)
                return
            }

            self.encryptCreditCard(creditCard: creditCard) { result in
                switch result {
                case .success(let encCreditCard):
                    do {
                        try self.storage?.updateCreditCard(guid: id, cc: encCreditCard)
                        completion(true, nil)
                    } catch let err as NSError {
                        completion(nil, err)
                    }
                case .failure(let err):
                    completion(nil, err)
                }
            }
        }
    }

    /// Deletes a credit card from the database.
    ///
    /// - Parameters:
    ///   - id: The identifier of the credit card to be deleted.
    ///   - completion: A closure called upon completion with a boolean indicating success and an error if any.
    /// - Note: Deletes a credit card and reports the result using a completion handler.
    public func deleteCreditCard(id: String, completion: @escaping @Sendable (Bool, Error?) -> Void) {
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
    public func use(creditCard: CreditCard, completion: @escaping @Sendable (Bool, Error?) -> Void) {
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
    /// - Parameter completion: A closure called upon completion with a result indicating success or failure.
    /// - Note: Scrubs encrypted credit card numbers and reports the result using a completion handler.
    public func scrubCreditCardNums(completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        performDatabaseOperation { error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            do {
                try self.storage?.scrubEncryptedData()
                completion(.success(()))
            } catch let err as NSError {
                completion(.failure(err))
            }
        }
    }

    /// Iterates through the stored credit cards checking that each record can be decrypted. If any records cannot be
    /// decrypted, they are locally scrubbed to potentially be overwritten by a perviously synced server record.
    ///
    /// This function is meant to be executed only once (which is enforced via the `CreditCardsHaveBeenVerified` pref)
    /// and is called before a credit card sync in `RustSyncManager`.
    ///
    /// - Parameters:
    /// - Note: Scrubs undecryptable credit cards for sync users. This function is for a very specific purpose and should not
    /// be used for general purposes.
    public func verifyCreditCards(
        key: String,
        completionHandler: @escaping @Sendable (Bool) -> Void) {
        performDatabaseOperation { error in
            guard error == nil, let storage = self.storage else {
                completionHandler(false)
                return
            }
            do {
                 let result = try storage.scrubUndecryptableCreditCardDataForRemoteReplacement(localEncryptionKey: key)

                if result.totalScrubbedRecords > 0 {
                    GleanMetrics.UserCreditCards.undecryptableCount.add(Int32(result.totalScrubbedRecords))
                }
                completionHandler(true)
            } catch let err as NSError {
                self.logger.log("Error verifying credit cards",
                                level: .warning,
                                category: .storage,
                                description: err.localizedDescription)
                completionHandler(false)
            }
        }
    }

    enum AddressAutofillError: Error {
        case addAddressFailure
    }

    /// Adds an address asynchronously.
    ///
    /// - Parameters:
    ///   - address: The address fields to add.
    ///   - completion: A closure that is called when the operation is complete.
    ///   It takes a `Result` object as its parameter, which contains either the added address or an error.
    public func addAddress(
        address: UpdatableAddressFields,
        completion: @escaping @Sendable (Result<Address, Error>) -> Void) {
        performDatabaseOperation { [weak self] error in
            if let error {
                completion(.failure(error))
                return
            }
            do {
                if let address = try self?.storage?.addAddress(a: address) {
                    completion(.success(address))
                } else {
                    completion(.failure(AddressAutofillError.addAddressFailure))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Retrieves an address from the database by its identifier.
    ///
    /// - Parameters:
    ///   - id: The identifier of the address.
    ///   - completion: A closure called upon completion with the retrieved address or an error.
    public func getAddress(id: String, completion: @escaping @Sendable (Address?, Error?) -> Void) {
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

    /// Updates the address asynchronously.
    ///
    /// - Parameters:
    ///   - id: The identifier of the address to update.
    ///   - address: The updated address fields.
    ///   - completion: A closure called upon update completion, taking a Result object indicating success or failure.
    public func updateAddress(
        id: String,
        address: UpdatableAddressFields,
        completion: @escaping @Sendable (Result<Void, Error>) -> Void
    ) {
        performDatabaseOperation { error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            do {
                try self.storage?.updateAddress(guid: id, a: address)
                completion(.success(()))
            } catch let error {
                completion(.failure(error))
            }
        }
    }

    /// Deletes an address from the storage.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the address to be deleted.
    ///   - completion: A closure called upon update completion, taking a Result object indicating success or failure.
    public func deleteAddress(id: String, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        performDatabaseOperation { error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
            do {
                _ = try self.storage?.deleteAddress(guid: id)
                completion(.success(()))
            } catch let error {
                completion(.failure(error))
            }
        }
    }

    /// Retrieves all addresses from the database.
    ///
    /// - Parameter completion: A closure called upon completion with the list of addresses or an error.
    /// - Note: Uses a completion handler for handling asynchronous code execution.
    public func listAllAddresses(completion: @escaping @Sendable ([Address]?, Error?) -> Void) {
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

    /// Reports when the credit card encryption key can't be rerieved for a credit cards sync
    public func reportPreSyncKeyRetrievalFailure(err: String) {
        GleanMetrics
            .PreSyncKeyRetrievalFailure
            .creditCards
            .record(GleanMetrics.PreSyncKeyRetrievalFailure.CreditCardsExtra(errorMessage: err))
    }

    /// Retrieves the stored encryption key.
    ///
    /// - Parameters:
    ///   - completion: A closure called upon completion with the encryption key or an error upon failure.
    public func getStoredKey(completion: @Sendable @escaping (Result<String, NSError>) -> Void) {
        DispatchQueue.global(qos: .background).sync {
            let (key, encryptedCanaryPhrase) = rustKeychain.getCreditCardKeyData()

            switch (key, encryptedCanaryPhrase) {
            case (.some(key), .some(encryptedCanaryPhrase)):
                self.handleExpectedKeyAction(encryptedCanaryPhrase: encryptedCanaryPhrase,
                                             key: key,
                                             completion: completion)
            case (.some(key), .none):
                GleanMetrics.CreditCardKeyRegeneration.other.record()
                self.handleUnexpectedKeyAction(completion: completion)
            case (.none, .some(encryptedCanaryPhrase)):
                 GleanMetrics.CreditCardKeyRegeneration.lost.record()
                self.handleUnexpectedKeyAction(completion: completion)
            case (.none, .none):
                self.handleFirstTimeCallOrClearedKeychainAction(completion: completion)
            default:
                // If none of the above cases apply, we're in a state that shouldn't be possible
                // but is disallowed nonetheless
                completion(.failure(AutofillEncryptionKeyError.illegalState as NSError))
            }
        }
    }

    private func handleExpectedKeyAction(encryptedCanaryPhrase: String?,
                                         key: String?,
                                         completion: @Sendable @escaping (Result<String, NSError>) -> Void) {
        // We expected the key to be present, and it is.
        var canaryIsValid = false
        do {
            canaryIsValid = try rustKeychain.checkCanary(
                canary: encryptedCanaryPhrase!,
                text: rustKeychain.creditCardCanaryPhrase,
                key: key!
            )
        } catch let error as NSError {
            logger.log("Error validating autofill encryption key",
                       level: .warning,
                       category: .storage,
                       description: error.localizedDescription)
            completion(.failure(error))
            return
        }
        if canaryIsValid {
            completion(.success(key!))
        } else {
            logger.log("Autofill key was corrupted, new one generated",
                       level: .warning,
                       category: .storage)
            GleanMetrics.CreditCardKeyRegeneration.corrupt.record()
            resetCreditCardsAndKey(completion: completion)
        }
    }

    private func handleUnexpectedKeyAction(completion: @Sendable @escaping (Result<String, NSError>) -> Void) {
        // The key is present, but we didn't expect it to be there.
        // or
        // We expected the key to be present, but it's gone missing on us
        logger.log("Autofill key lost, new one generated",
                   level: .warning,
                   category: .storage)
        resetCreditCardsAndKey(completion: completion)
    }

    private func handleFirstTimeCallOrClearedKeychainAction(
        completion: @Sendable @escaping (Result<String, NSError>) -> Void) {
        // We didn't expect the key to be present, which either means this is a first-time
        // call or the key data has been cleared from the keychain.
        hasCreditCards { result in
            switch result {
            case .success(let hasCreditCards):
                if hasCreditCards {
                    // Since the key data isn't present and we have credit card records in
                    // the database, we both scrub the records and reset the key.
                    GleanMetrics.CreditCardKeyRegeneration.keychainDataLost.record()
                    self.resetCreditCardsAndKey(completion: completion)
                } else {
                    // There are no records in the database so we don't need to scrub any
                    // existing credit card records. We just need to create a new key.
                    do {
                        let key = try self.rustKeychain.createCreditCardsKeyData()
                        completion(.success(key))
                    } catch let error as NSError {
                        completion(.failure(error))
                    }
                }
            case .failure(let err):
                completion(.failure(err as NSError))
            }
        }
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

    private func performDatabaseOperation(_ operation: @escaping @Sendable (Error?) -> Void) {
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

    private func resetCreditCardsAndKey(completion: @Sendable @escaping (Result<String, NSError>) -> Void) {
        self.scrubCreditCardNums { result in
            switch result {
            case .success(()):
                do {
                    let key = try self.rustKeychain.createCreditCardsKeyData()
                    completion(.success(key))
                } catch let error as NSError {
                    self.logger.log("Error creating credit card encryption key",
                                    level: .warning,
                                    category: .storage,
                                    description: error.localizedDescription)
                    completion(.failure(error))
                }
            case .failure(let err):
                completion(.failure(err as NSError))
            }
        }
    }

    private func hasCreditCards(completion: @Sendable @escaping (Result<Bool, Error>) -> Void) {
        return listCreditCards { (creditCards, err) in
            guard err == nil else {
                completion(.failure(err!))
                return
            }

            completion(.success(creditCards?.count ?? 0 > 0))
        }
    }

    private func encryptCreditCard(creditCard: UnencryptedCreditCardFields,
                                   completion: @escaping @Sendable (Result<UpdatableCreditCardFields, Error>) -> Void) {
        getStoredKey { result in
            var ccNumberEnc: String
            switch result {
            case .success(let key):
                do {
                    ccNumberEnc = try encryptString(key: key, cleartext: creditCard.ccNumber)
                } catch let error as NSError {
                    self.logger.log("Error encrypting credit card number",
                                    level: .warning,
                                    category: .storage,
                                    description: error.localizedDescription)
                    completion(.failure(error))
                    return
                }

                let encCreditCard = UpdatableCreditCardFields(ccName: creditCard.ccName,
                                                              ccNumberEnc: ccNumberEnc,
                                                              ccNumberLast4: creditCard.ccNumberLast4,
                                                              ccExpMonth: creditCard.ccExpMonth,
                                                              ccExpYear: creditCard.ccExpYear,
                                                              ccType: creditCard.ccType)
                completion(.success(encCreditCard))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
