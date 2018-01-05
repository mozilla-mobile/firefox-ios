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
    public var isGif : Bool {
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

    /// Generates a UIImage from GIF data by calling out to SDWebImage. The latter in turn uses UIImage(data: NSData)
    /// in certain cases so we have to synchronize calls (see bug 1223132).
    public static func imageFromGIFDataThreadSafe(_ data: Data) -> UIImage? {
        imageLock.lock()
        let image = UIImage.sd_animatedGIF(with: data)
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

    public convenience init?(template name: String) {
        self.init(named: name)
        withRenderingMode(.alwaysTemplate)
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
    @available(*, deprecated, message: "use only in testing code")
    public func isStrictlyEqual(to other: UIImage) -> Bool {
        // Must use same constructor for PNG metadata block to be the same.
        let imageA = UIImage(data: UIImagePNGRepresentation(self)!)!
        let imageB = UIImage(data: UIImagePNGRepresentation(other)!)!
        let dataA = UIImagePNGRepresentation(imageA)!
        let dataB = UIImagePNGRepresentation(imageB)!
        return dataA == dataB
    }
}
