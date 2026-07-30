// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension NSLayoutAnchor where AnchorType == NSLayoutXAxisAnchor {
    /// Similar to `constraint(equalTo:)` except that it also takes an optional
    /// multiplier, constant and priority. This makes it really easy to inline
    /// constraints in a call to `NSLayoutConstraint.activate()`.
    func constraint(
        equalTo anchor: NSLayoutAnchor<AnchorType>,
        multiplier: CGFloat = 1.0,
        constant: CGFloat = 0.0,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {
        let constraint = self.constraint(equalTo: anchor)
        return NSLayoutConstraint(
            item: constraint.firstItem!,
            attribute: constraint.firstAttribute,
            relatedBy: constraint.relation,
            toItem: constraint.secondItem,
            attribute: constraint.secondAttribute,
            multiplier: multiplier,
            constant: constant
        ).priority(priority)
    }
}

extension NSLayoutAnchor where AnchorType == NSLayoutYAxisAnchor {
    /// Similar to `constraint(equalTo:)` except that it also takes an optional
    /// multiplier, constant and priority. This makes it really easy to inline
    /// constraints in a call to `NSLayoutConstraint.activate()`.
    func constraint(
        equalTo anchor: NSLayoutAnchor<AnchorType>,
        multiplier: CGFloat = 1.0,
        constant: CGFloat = 0.0,
        priority: UILayoutPriority = .required
    ) -> NSLayoutConstraint {
        let constraint = self.constraint(equalTo: anchor)
        return NSLayoutConstraint(
            item: constraint.firstItem!,
            attribute: constraint.firstAttribute,
            relatedBy: constraint.relation,
            toItem: constraint.secondItem,
            attribute: constraint.secondAttribute,
            multiplier: multiplier,
            constant: constant
        ).priority(priority)
    }
}
