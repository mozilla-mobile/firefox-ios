/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SwiftKeychainWrapper

class KeyChainAccountStorage {
    internal var keychainWrapper: KeychainWrapper
    internal static var keychainKey: String = "accountJSON"

    init(keychainAccessGroup: String?) {
        keychainWrapper = KeychainWrapper.sharedAppContainerKeychain(keychainAccessGroup: keychainAccessGroup)
    }

    func read() -> FxAccount? {
        if let json = keychainWrapper.string(forKey: KeyChainAccountStorage.keychainKey) {
            do {
                return try FxAccount(fromJsonState: json)
            } catch {
                FxALog.error("FxAccount internal state de-serialization failed: \(error).")
                return nil
            }
        }
        return nil
    }

    func write(_ json: String) {
        if !keychainWrapper.set(json, forKey: KeyChainAccountStorage.keychainKey) {
            FxALog.error("Could not write account state.")
        }
    }

    func clear() {
        if !keychainWrapper.removeObject(forKey: KeyChainAccountStorage.keychainKey) {
            FxALog.error("Could not clear account state.")
        }
    }
}
