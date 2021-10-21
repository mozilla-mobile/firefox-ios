/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension NSLayoutConstraint {
    
    /// Builder function that return a new NSLayoutConstraints with the priority set. This is useful  to inline constraint creation in a call to `NSLayoutConstraint.active()`.
    /// - Parameter priority: the priority to set
    /// - Returns: the same `NSLayoutConstraint` with the priority set
    func priority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
    
    /// Builder function that return a new NSLayoutConstraints with the multiplier set. This is useful  to inline constraint creation in a call to `NSLayoutConstraint.active()`.
    /// - Parameter multiplier: the multiplier to set
    /// - Returns: a new `NSLayoutContraint` instance
    func multiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(
            item: self.firstItem!,
            attribute: self.firstAttribute,
            relatedBy: self.relation,
            toItem: self.secondItem,
            attribute: self.secondAttribute,
            multiplier: multiplier,
            constant: self.constant
        )
    }
}
