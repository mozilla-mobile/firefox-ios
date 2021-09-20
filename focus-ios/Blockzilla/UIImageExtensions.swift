/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UIImage {
    public func createScaled(targetSize: CGFloat) -> UIImage {
        let widthRatio  = targetSize  / self.size.width
        let heightRatio = targetSize / self.size.height

        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: self.size.width * heightRatio, height: self.size.height * heightRatio)
        } else {
            newSize = CGSize(width: self.size.width * widthRatio,  height: self.size.height * widthRatio)
        }
        
        let rect = CGRect(
            origin: CGPoint(x: (targetSize - newSize.width) / 2.0, y: (targetSize - newSize.height) / 2.0),
            size: CGSize(width: newSize.width, height: newSize.height)
        )
        
        return UIGraphicsImageRenderer(size: CGSize(width: targetSize, height: targetSize)).image { context in
            self.draw(in: rect)
        }
    }
    
    func alpha(_ value: CGFloat) -> UIImage {
        let imageRenderer = UIGraphicsImageRenderer(size: size)
        return imageRenderer.image(actions: { (context) in
            draw(at: .zero, blendMode: .normal, alpha: value)
        })
    }
}
