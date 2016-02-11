/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private let imageLock = NSLock()

extension UIImage {
    /// Despite docs that say otherwise, UIImage(data: NSData) isn't thread-safe (see bug 1223132).
    /// As a workaround, synchronize access to this initializer.
    /// This fix requires that you *always* use this over UIImage(data: NSData)!
    public static func imageFromDataThreadSafe(data: NSData) -> UIImage? {
        imageLock.lock()
        let image = UIImage(data: data)
        imageLock.unlock()
        return image
    }

    public static func createWithColor(size: CGSize, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        let rect = CGRect(origin: CGPointZero, size: size)
        color.setFill()
        CGContextFillRect(context, rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    public func createScaled(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        drawInRect(CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
}
