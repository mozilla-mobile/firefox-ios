/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class KeyChainAccountStorage {
    var keychainWrapper: FxAKeychain
    static let keychainKey: String = "accountJSON"
    static let accessibility: FxAKeychainItemAccessibility = .afterFirstUnlock

    init(keychainAccessGroup: String?) {
        keychainWrapper = FxAKeychain.sharedAppContainerKeychainForFxA(keychainAccessGroup: keychainAccessGroup)
    }

    func read() -> PersistedFirefoxAccount? {
        // Firefox iOS v25.0 shipped with the default accessibility, which breaks Send Tab when the screen is locked.
        // This method migrates the existing keychains to the correct accessibility.

        keychainWrapper.ensureStringItemAccessibility(KeyChainAccountStorage.accessibility,
                                                      forKey: KeyChainAccountStorage.keychainKey)
        if let json = keychainWrapper
            .getKeyValue(key: KeyChainAccountStorage.keychainKey,
                         accessibility: KeyChainAccountStorage.accessibility)
        {
            do {
                return try PersistedFirefoxAccount.fromJSON(data: json)
            } catch {
                FxALog.error("FxAccount internal state de-serialization failed: \(error).")
                return nil
            }
        }

        return nil
    }

    func write(_ json: String) {
        if !keychainWrapper.setKeyValue(
            json,
            key: KeyChainAccountStorage.keychainKey,
            accessibility: KeyChainAccountStorage.accessibility
        ) {
            FxALog.error("Could not write account state.")
        }
    }

    func clear() {
        if !keychainWrapper.removeObject(
            key: KeyChainAccountStorage.keychainKey,
            accessibility: KeyChainAccountStorage.accessibility
        ) {
            FxALog.error("Could not clear account state.")
        }
    }
}
