/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class KeyChainAccountStorage {
    var keychainWrapper: MZKeychainWrapper
    static var keychainKey: String = "accountJSON"
    static var accessibility: MZKeychainItemAccessibility = .afterFirstUnlock

    init(keychainAccessGroup: String?) {
        keychainWrapper = MZKeychainWrapper.sharedAppContainerKeychain(keychainAccessGroup: keychainAccessGroup)
    }

    func read() -> PersistedFirefoxAccount? {
        // Firefox iOS v25.0 shipped with the default accessibility, which breaks Send Tab when the screen is locked.
        // This method migrates the existing keychains to the correct accessibility.
        keychainWrapper.ensureStringItemAccessibility(
            KeyChainAccountStorage.accessibility,
            forKey: KeyChainAccountStorage.keychainKey
        )
        if let json = keychainWrapper.string(
            forKey: KeyChainAccountStorage.keychainKey,
            withAccessibility: KeyChainAccountStorage.accessibility
        ) {
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
        if !keychainWrapper.set(
            json,
            forKey: KeyChainAccountStorage.keychainKey,
            withAccessibility: KeyChainAccountStorage.accessibility
        ) {
            FxALog.error("Could not write account state.")
        }
    }

    func clear() {
        if !keychainWrapper.removeObject(
            forKey: KeyChainAccountStorage.keychainKey,
            withAccessibility: KeyChainAccountStorage.accessibility
        ) {
            FxALog.error("Could not clear account state.")
        }
    }
}

public extension MZKeychainWrapper {
    func ensureStringItemAccessibility(
        _ accessibility: MZKeychainItemAccessibility,
        forKey key: String
    ) {
        if hasValue(forKey: key) {
            if accessibilityOfKey(key) != accessibility {
                FxALog.info("ensureStringItemAccessibility: updating item \(key) with \(accessibility)")

                guard let value = string(forKey: key) else {
                    FxALog.error("ensureStringItemAccessibility: failed to get item \(key)")
                    return
                }

                if !removeObject(forKey: key) {
                    FxALog.error("ensureStringItemAccessibility: failed to remove item \(key)")
                }

                if !set(value, forKey: key, withAccessibility: accessibility) {
                    FxALog.error("ensureStringItemAccessibility: failed to update item \(key)")
                }
            }
        }
    }
}
