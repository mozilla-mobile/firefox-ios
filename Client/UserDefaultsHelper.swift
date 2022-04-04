// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// UserDefaultsManager is meant to store items that need to persist between app launches.

protocol UserDefaultsManageable { }

extension UserDefaultsManageable {
    var userDefaultsManager: UserDefaultsManager {
        return UserDefaultsManager.shared
    }
}

struct UserDefaultsManager {
    
    // MARK: - Properties
    
    static let shared = UserDefaultsManager()
    
    private var userDefaults: UserDefaults = .standard
    
    /// Get the userDefaults value of that key.
    /// - Parameter key: A key to look up.
    /// - Returns: Optionally returns the value. Callers need to handle the nil case.
    func getPreference<T: Any>(_ key: String) -> T? {
        return userDefaults.object(forKey: key) as? T
    }
    
    /// Set the key/value pair for that UserDefaults key.
    /// - Parameters:
    ///   - value: The value to set for the associated key.
    ///   - key: A key to set.
    func setPreference<T: Any>(_ value: T, key: String) {
        userDefaults.set(value as T, forKey: key)
    }
    
    /// Remove one preference setting at the specified key.
    /// - Parameter key: The key, pointing to an entry to delete.
    func deletePreference(_ key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
}

