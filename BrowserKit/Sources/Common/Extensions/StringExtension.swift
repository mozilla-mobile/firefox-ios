// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension StringProtocol {
    /// Returns a new string in which all occurrences of a target
    /// string within the receiver are removed.
    public func removingOccurrences<Target>(of target: Target) -> String where Target: StringProtocol {
        return replacingOccurrences(of: target, with: "")
    }
}
