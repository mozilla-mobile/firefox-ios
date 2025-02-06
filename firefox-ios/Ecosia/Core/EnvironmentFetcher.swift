// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct EnvironmentFetcher {

    private init() {}

    /// Fetches a string value associated with the specified key either from the Main Bundle Info Dictionary or the Process Info environment.
    ///
    /// - Parameters:
    ///   - key: The key for which to retrieve the associated string value.
    /// - Returns: The string value associated with the key, or nil if not found.
    public static func valueFromMainBundleOrProcessInfo(forKey key: String) -> String? {
        // Attempt to retrieve the value from the Main Bundle Info Dictionary
        // If not found, try to retrieve it from the Process Info environment
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String
                ?? ProcessInfo.processInfo.environment[key] else {
            // Return nil if the value is not found in either location
            return nil
        }

        // Return the retrieved value
        return value
    }
}
