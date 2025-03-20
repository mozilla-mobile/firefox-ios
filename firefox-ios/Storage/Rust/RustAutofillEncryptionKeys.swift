// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

import class MozillaAppServices.MZKeychainWrapper
import enum MozillaAppServices.AutofillApiError
import enum MozillaAppServices.MZKeychainItemAccessibility
import func MozillaAppServices.createAutofillKey
import func MozillaAppServices.decryptString
import func MozillaAppServices.encryptString

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

public class RustAutofillEncryptionKeys {
    public let ccKeychainKey = "appservices.key.creditcard.perfield"

    let legacyKeychain = MZKeychainWrapper.sharedClientAppContainerKeychain
    let keychain = RustKeychain.sharedClientAppContainerKeychain
    let ccCanaryPhraseKey = "creditCardCanaryPhrase"
    let canaryPhrase = "a string for checking validity of the key"

    private let logger: Logger

    public init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    func createAndStoreKey() throws -> String {
        do {
            let secret = try createAutofillKey()
            let canary = try self.createCanary(text: canaryPhrase, key: secret)

            DispatchQueue.global(qos: .background).sync {
                legacyKeychain.set(secret,
                                   forKey: ccKeychainKey,
                                   withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)
                legacyKeychain.set(canary,
                                   forKey: ccCanaryPhraseKey,
                                   withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)
            }

            return secret
        } catch let err as NSError {
            if let autofillStoreError = err as? AutofillApiError {
                keychain.logAutofillStoreError(err: autofillStoreError,
                                               errorDomain: err.domain,
                                               errorMessage: "Error while creating and storing credit card key")

                throw AutofillEncryptionKeyError.noKeyCreated
            } else {
                logger.log("Unknown error while creating and storing credit card key",
                           level: .warning,
                           category: .storage,
                           description: err.localizedDescription)

                throw AutofillEncryptionKeyError.noKeyCreated
            }
        }
    }

    func decryptCreditCardNum(encryptedCCNum: String, rustKeychainEnabled: Bool) -> String? {
        var keyValue: String?

        if rustKeychainEnabled {
            (keyValue, _) = keychain.getCreditCardKeyData()
        } else {
            keyValue = legacyKeychain.string(forKey: self.ccKeychainKey)
        }

        guard let key = keyValue else { return nil }

        do {
            return try decryptString(key: key, ciphertext: encryptedCCNum)
        } catch let err as NSError {
            if let autofillStoreError = err as? AutofillApiError {
                keychain.logAutofillStoreError(err: autofillStoreError,
                                               errorDomain: err.domain,
                                               errorMessage: "Error while decrypting credit card")
            } else {
                logger.log("Unknown error while decrypting credit card",
                           level: .warning,
                           category: .storage,
                           description: err.localizedDescription)
            }
            return nil
        }
    }

    func checkCanary(canary: String,
                     text: String,
                     key: String) throws -> Bool {
        return try decryptString(key: key, ciphertext: canary) == text
    }

    private func createCanary(text: String,
                              key: String) throws -> String {
        return try encryptString(key: key, cleartext: text)
    }
}
