// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import func MozillaAppServices.createCanary
import func MozillaAppServices.createKey

// FIXME: FXIOS-13988 Make truly thread safe
class MockRustKeychain: @unchecked Sendable, KeychainProtocol {
    static let shared = MockRustKeychain()

    public let loginsKeyIdentifier = "testLoginsKey"
    public let loginsCanaryKeyIdentifier = "testLoginsCanaryKey"
    public let creditCardKeyIdentifier = "testCCKeyID"
    public let creditCardCanaryKeyIdentifier = "testCCCanaryKey"
    public let creditCardCanaryPhrase = "a string for checking validity of the key"

    let loginsCanaryPhrase = "a string for checking validity of the key"

    private var storage: [String: String] = [:]

    public func removeObject(key: String) {
        _ = storage.removeValue(forKey: key)
    }

    public func removeLoginsKeysForDebugMenuItem() {
        removeObject(key: loginsKeyIdentifier)
        removeObject(key: loginsCanaryKeyIdentifier)
    }

    public func removeAutofillKeysForDebugMenuItem() {
        removeObject(key: creditCardKeyIdentifier)
        removeObject(key: creditCardCanaryKeyIdentifier)
    }

    public func removeAllKeys() {
        storage.removeAll()
    }

    public func setLoginsKeyData(keyValue: String, canaryValue: String) {
        storage[loginsKeyIdentifier] = keyValue
        storage[loginsCanaryKeyIdentifier] = canaryValue
    }

    public func setCreditCardsKeyData(keyValue: String, canaryValue: String) {
        storage[creditCardKeyIdentifier] = keyValue
        storage[creditCardCanaryKeyIdentifier] = canaryValue
    }

    public func getLoginsKeyData() -> (String?, String?) {
        return (storage[loginsKeyIdentifier], storage[loginsCanaryKeyIdentifier])
    }

    public func getCreditCardKeyData() -> (String?, String?) {
        return (storage[creditCardKeyIdentifier], storage[creditCardCanaryKeyIdentifier])
    }

    public class func wipeKeychain() {}

    func createLoginsKeyData() throws -> String {
        guard let keyValue = try? createKey(),
              let canaryValue = try? createCanary(text: loginsCanaryPhrase, encryptionKey: keyValue) else {
            throw LoginEncryptionKeyError.noKeyCreated
        }

        storage[loginsCanaryKeyIdentifier] = canaryValue
        storage[loginsKeyIdentifier] = keyValue
        return keyValue
    }

    func queryKeychainForKey(key: String) -> Result<String?, Error> {
        return .success(storage[key])
    }

    func createAndStoreKey(canaryPhrase: String, canaryIdentifier: String, keyIdentifier: String) throws -> String {
        let keyValue = try createKey()
        let canaryValue = try createCanary(text: canaryPhrase, encryptionKey: keyValue)

        storage[canaryIdentifier] = canaryValue
        storage[keyIdentifier] = keyValue
        return keyValue
    }

    func decryptCreditCardNum(encryptedCCNum: String) -> String? {
        return "4242424242424242"
    }

    func checkCanary(canary: String, text: String, key: String) throws -> Bool {
        return true
    }

    func createCreditCardsKeyData() throws -> String {
        return """
        {\"kty\":\"oct\",\"k\":\"iHvskvsnDkECjFSD_mvD6Gnb_XMaxgV45tpj1KXIM28\"}
        """
    }
}
