// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIImage {
    @MainActor
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

    nonisolated(unsafe) private static let gifCache = NSCache<NSString, UIImage>()

    /// Tries to load an `UIImage` from the content of a gif in the main `Bundle`
    ///
    /// The `frameDuration` it's set to 0.1 seconds as default but may be adjusted depending on the loaded gif.
    /// If `maxPixelSize` is provided, each frame is decoded as a thumbnail whose longest edge does not exceed
    /// that value in pixels, which can significantly reduce memory usage for large gifs.
    /// Decoded results are cached per `name`/`maxPixelSize`/`frameDuration` combination to avoid re-decoding
    /// the gif on subsequent calls.
    static func gifFromBundle(named name: String,
                              frameDuration: CGFloat = 0.1,
                              maxPixelSize: CGFloat? = nil) -> UIImage? {
        let cacheKey = "\(name)|\(maxPixelSize ?? 0)|\(frameDuration)" as NSString
        if let cached = gifCache.object(forKey: cacheKey) {
            return cached
        }

        guard let gifPath = Bundle.main.path(forResource: name, ofType: "gif"),
              let gifData = NSData(contentsOfFile: gifPath) as Data?,
              let source = CGImageSourceCreateWithData(gifData as CFData, nil) else {
            return nil
        }

        let frameCount = CGImageSourceGetCount(source)
        let options: CFDictionary? = maxPixelSize.map {
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: $0
            ] as CFDictionary
        }

        var frames: [UIImage] = []
        for i in 0..<frameCount {
            let cgImage: CGImage?
            if let options {
                cgImage = CGImageSourceCreateThumbnailAtIndex(source, i, options)
            } else {
                cgImage = CGImageSourceCreateImageAtIndex(source, i, nil)
            }
            if let cgImage {
                frames.append(UIImage(cgImage: cgImage))
            }
        }

        let animated = UIImage.animatedImage(with: frames, duration: Double(frameCount) * frameDuration)
        if let animated {
            gifCache.setObject(animated, forKey: cacheKey)
        }
        return animated
    }
}
