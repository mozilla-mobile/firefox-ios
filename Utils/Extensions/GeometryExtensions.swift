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

/**
Generates the affine transform for transforming the first CGRect into the second one

- parameter frame:   CGRect to transform from
- parameter toFrame: CGRect to transform to

- returns: CGAffineTransform that transforms the first CGRect into the second
*/
func CGAffineTransformMakeRectToRect(_ frame: CGRect, toFrame: CGRect) -> CGAffineTransform {
    let scale = toFrame.size.width / frame.size.width
    let tx = toFrame.origin.x + toFrame.width / 2 - (frame.origin.x + frame.width / 2)
    let ty = toFrame.origin.y - frame.origin.y * scale * 2
    let translation = CGAffineTransform(translationX: tx, y: ty)
    let scaledAndTranslated = translation.scaleBy(x: scale, y: scale)
    return scaledAndTranslated
}
