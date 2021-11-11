// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

extension UIImage {
    func tinted(_ color: UIColor) -> UIImage? {
           UIGraphicsBeginImageContextWithOptions(size, false, scale)
           defer { UIGraphicsEndImageContext() }
           color.set()
           draw(in: CGRect(origin: .zero, size: size))
           return UIGraphicsGetImageFromCurrentImageContext()
       }

       static func color(_ color: UIColor, size: CGSize=CGSize(width: 1, height: 1)) -> UIImage? {
           UIGraphicsBeginImageContextWithOptions(size, false, 0)
           color.setFill()
           UIRectFill(CGRect(origin: CGPoint.zero, size: size))
           let image = UIGraphicsGetImageFromCurrentImageContext()
           UIGraphicsEndImageContext()
           return image
       }
}
