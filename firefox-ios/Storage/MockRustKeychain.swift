// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import func MozillaAppServices.createCanary
import func MozillaAppServices.createKey

class MockRustKeychain: RustKeychain {
    static let shared = MockRustKeychain()

    private var storage: [String: String] = [:]

    private init() {
        super.init(serviceName: "Test")
    }
    override public func removeObject(key: String) {
        _ = storage.removeValue(forKey: key)
    }

    override public func removeLoginsKeysForDebugMenuItem() {
        removeObject(key: loginsKeyIdentifier)
        removeObject(key: loginsCanaryKeyIdentifier)
    }

    override public func removeAllKeys() {
        storage.removeAll()
    }

    override public func setLoginsKeyData(keyValue: String, canaryValue: String) {
        storage[loginsKeyIdentifier] = keyValue
        storage[loginsCanaryKeyIdentifier] = canaryValue
    }

    override public func setCreditCardsKeyData(keyValue: String, canaryValue: String) {
        storage[creditCardKeyIdentifier] = keyValue
        storage[creditCardCanaryKeyIdentifier] = canaryValue
    }

    override public func getLoginsKeyData() -> (String?, String?) {
        return (storage[loginsKeyIdentifier], storage[loginsCanaryKeyIdentifier])
    }

    override public func getCreditCardKeyData() -> (String?, String?) {
        return (storage[creditCardKeyIdentifier], storage[creditCardCanaryKeyIdentifier])
    }

    override public class func wipeKeychain() {}

    override func createLoginsKeyData() throws -> String {
        guard let keyValue = try? createKey(),
              let canaryValue = try? createCanary(text: loginsCanaryPhrase, encryptionKey: keyValue) else {
            throw LoginEncryptionKeyError.noKeyCreated
        }

        storage[loginsCanaryKeyIdentifier] = canaryValue
        storage[loginsKeyIdentifier] = keyValue
        return keyValue
    }

    override func queryKeychainForKey(key: String) -> Result<String?, Error> {
        return .success(storage[key])
    }

    override func createAndStoreKey(canaryPhrase: String, canaryIdentifier: String, keyIdentifier: String) throws -> String {
        let keyValue = try createKey()
        let canaryValue = try createCanary(text: canaryPhrase, encryptionKey: keyValue)

        storage[canaryIdentifier] = canaryValue
        storage[keyIdentifier] = keyValue
        return keyValue
    }
}
