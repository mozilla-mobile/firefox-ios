/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SDWebImage

private let imageLock = NSLock()

extension CGRect {
    public init(width: CGFloat, height: CGFloat) {
        self.init(x: 0, y: 0, width: width, height: height)
    }

    public init(size: CGSize) {
        self.init(origin: .zero, size: size)
    }
}

extension Data {
    public var isGIF: Bool {
        return [0x47, 0x49, 0x46].elementsEqual(prefix(3))
    }
}

extension UIImage {
    /// Despite docs that say otherwise, UIImage(data: NSData) isn't thread-safe (see bug 1223132).
    /// As a workaround, synchronize access to this initializer.
    /// This fix requires that you *always* use this over UIImage(data: NSData)!
    public static func imageFromDataThreadSafe(_ data: Data) -> UIImage? {
        imageLock.lock()
        let image = UIImage(data: data)
        imageLock.unlock()
        return image
    }

    public static func createWithColor(_ size: CGSize, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        let rect = CGRect(size: size)
        color.setFill()
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }

    public func createScaled(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        draw(in: CGRect(size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }

    public static func templateImageNamed(_ name: String) -> UIImage? {
        return UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
    }

    // Uses compositor blending to apply color to an image.
    public func tinted(withColor: UIColor) -> UIImage {
        let img2 = UIImage.createWithColor(size, color: withColor)
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let renderer = UIGraphicsImageRenderer(size: size)
        let result = renderer.image { ctx in
            img2.draw(in: rect, blendMode: .normal, alpha: 1)
            draw(in: rect, blendMode: .destinationIn, alpha: 1)
        }
        return result
    }

    // TESTING ONLY: not for use in release/production code.
    // PNG comparison can return false negatives, be very careful using for non-equal comparison.
    // PNG comparison requires UIImages to be constructed the same way in order for the metadata block to match,
    // this function ensures that.
    //
    // This can be verified with this code:
    //    let image = UIImage(named: "fxLogo")!
    //    let data = UIImagePNGRepresentation(image)!
    //    assert(data != UIImagePNGRepresentation(UIImage(data: data)!))
    public func isStrictlyEqual(to other: UIImage) -> Bool {
        // Must use same constructor for PNG metadata block to be the same.
        let imageA = UIImage(data: self.pngData()!)!
        let imageB = UIImage(data: other.pngData()!)!
        let dataA = imageA.pngData()!
        let dataB = imageB.pngData()!
        return dataA == dataB
    }
}
