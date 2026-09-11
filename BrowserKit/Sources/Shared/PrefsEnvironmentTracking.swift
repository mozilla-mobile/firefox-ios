// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public extension Prefs {
    /// Runs `reset` when `environment` differs from the value last recorded under `lastUsedKey`, so
    /// callers can discard credentials tied to one backend.
    func resetIfEnvironmentChanged(_ environment: String, forKey lastUsedKey: String, reset: () -> Void) {
        if let lastUsed = stringForKey(lastUsedKey), lastUsed != environment {
            reset()
        }

        setString(environment, forKey: lastUsedKey)
    }
}
