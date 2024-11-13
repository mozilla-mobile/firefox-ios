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
    
    /// Trys to load an `UIImage` from the content of a gif in the main `Bundle`
    ///
    /// The `frameDuration` it's set to 0.1 seconds as default but maybe adjusted depending on the loaded gif.
    static func gifFromBundle(named name: String, frameDuration: CGFloat = 0.1) -> UIImage? {
        guard let gifPath = Bundle.main.path(forResource: name, ofType: "gif"),
              let gifData = NSData(contentsOfFile: gifPath) as Data?,
              let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            return nil
        }

        var frames: [UIImage] = []
        let frameCount = CGImageSourceGetCount(source)

        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                frames.append(UIImage(cgImage: cgImage))
            }
        }

        return UIImage.animatedImage(with: frames, duration: Double(frameCount) * frameDuration)
    }
}
