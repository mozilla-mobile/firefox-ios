// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension NSLayoutConstraint {
    /// Builder function that returns a new `NSLayoutConstraint` with the priority set. This is useful
    /// to inline constraint creation in a call to `NSLayoutConstraint.activate()`.
    /// - Parameter priority: the priority to set
    /// - Returns: the same `NSLayoutConstraint` with the priority set
    public func priority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
