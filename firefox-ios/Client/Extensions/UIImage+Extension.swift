// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIImage {
    func overlayWith(image: UILabel) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width, height: size.height), false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        image.draw(CGRect(origin: CGPoint.zero, size: image.frame.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }

    func overlayWith(image: UIImage,
                     modifier: CGFloat = 0.35,
                     origin: CGPoint = CGPoint(x: 15, y: 16)) -> UIImage {
        let newSize = CGSize(width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: newSize))
        image.draw(in: CGRect(origin: origin,
                              size: CGSize(width: size.width * modifier,
                                           height: size.height * modifier)))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }
}
