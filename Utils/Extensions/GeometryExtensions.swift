/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension CGRect {
    public var center: CGPoint {
        get {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        set {
            self.origin = CGPoint(x: newValue.x - size.width / 2, y: newValue.y - size.height / 2)
        }
    }
}

extension CGSize {
    /**
     Returns the size that best fits this size. Best fit in this case is defined as the size
     which requires the least amount of scaling to fill this size.

     - parameter sizes: Sizes to attempt to find the best fitting size.

     - returns: Size that requires the least amount of scaling to fill this size.
     */
    public func sizeThatBestFitsFromSizes(sizes: [CGSize]) -> CGSize? {

        func maxDiffForSize(size: CGSize) -> CGFloat {
            let diffX = floor(abs(size.width - self.width))
            let diffY = floor(abs(size.height - self.height))
            return max(diffX, diffY)
        }

        guard let first = sizes.first else {
            return nil
        }

        let initial = (first, maxDiffForSize(first))
        return sizes.reduce(initial) { acc, s in
            let max = maxDiffForSize(s)
            if max < acc.1 {
                return (s, max)
            }
            return acc
        } .0
    }
}


/**
Generates the affine transform for transforming the first CGRect into the second one

- parameter frame:   CGRect to transform from
- parameter toFrame: CGRect to transform to

- returns: CGAffineTransform that transforms the first CGRect into the second
*/
public func CGAffineTransformMakeRectToRect(frame: CGRect, toFrame: CGRect) -> CGAffineTransform {
    let scale = toFrame.size.width / frame.size.width
    let tx = toFrame.origin.x + toFrame.width / 2 - (frame.origin.x + frame.width / 2)
    let ty = toFrame.origin.y - frame.origin.y * scale * 2
    let translation = CGAffineTransformMakeTranslation(tx, ty)
    let scaledAndTranslated = CGAffineTransformScale(translation, scale, scale)
    return scaledAndTranslated
}
