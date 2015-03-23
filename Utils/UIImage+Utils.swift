/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension UIImage {
    class func createWithColor(size: CGSize, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0);
        let context = UIGraphicsGetCurrentContext();
        let rect = CGRect(origin: CGPointZero, size: size)
        color.setFill()
        CGContextFillRect(context, rect)
        var image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        return image
    }
}