// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension Unleash {

    /// Adds a refreshing rule to the `rules` array.
    ///
    /// This method checks if a rule of the same type already exists in the `rules` array
    /// and adds the new rule only if it's not present. This prevents duplicate rules of the same type.
    ///
    /// - Parameter rule: The refreshing rule to be added.
    static func addRule(_ rule: RefreshingRule) {
        if !rules.contains(where: { type(of: $0) == type(of: rule) }) {
            rules.append(rule)
        }
    }
}
