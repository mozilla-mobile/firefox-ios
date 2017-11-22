/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension CGRect {
    var center: CGPoint {
        get {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        set {
            self.origin = CGPoint(x: newValue.x - size.width / 2, y: newValue.y - size.height / 2)
        }
    }
}

extension UIEdgeInsets {
    init(equalInset inset: CGFloat) {
        top = inset
        left = inset
        right = inset
        bottom = inset
    }
}

/**
Generates the affine transform for transforming the first CGRect into the second one

- parameter from:   CGRect to transform from
- parameter to: CGRect to transform to

- returns: CGAffineTransform that transforms the first CGRect into the second
*/

extension CGAffineTransform {
    init(from: CGRect, to: CGRect) {
        let scale = to.size.width / from.size.width
        let tx = to.origin.x + to.width / 2 - (from.origin.x + from.width / 2)
        let ty = to.origin.y - from.origin.y * scale * 2
        let translation = CGAffineTransform(translationX: tx, y: ty)
        self = translation.scaledBy(x: scale, y: scale)
    }
}

