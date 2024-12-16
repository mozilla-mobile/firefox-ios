// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension UserDefaults {
    /// Returns `true` if this value exists, and `false` if the value is `nil`.
    ///
    /// @discussion:
    /// Calling `.bool(forKey:)` for a value that does NOT exist always returns false. However, sometimes we want to check
    /// that the value has actually been set first.
    func valueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
