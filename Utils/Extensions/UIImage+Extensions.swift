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

    func createScaled(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        drawInRect(CGRect(origin: CGPoint(x: 0, y: 0), size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }

    func getPixelData(var inRect rect: CGRect? = nil) -> [UIColor] {
        if rect == nil {
            rect = CGRect(origin: CGPoint(x: 0,y: 0), size: size)
        }

        var result = [UIColor]()
        let width = Int(size.width)
        let height = Int(size.height)

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        var pixelData = CGDataProviderCopyData(CGImageGetDataProvider(CGImage))
        var rawData = CFDataGetBytePtr(pixelData)

        let y2 = Int(rect!.origin.y + rect!.height)
        let x2 = Int(rect!.origin.x + rect!.width)
        for y in Int(rect!.origin.y)..<y2 {
            for x in Int(rect!.origin.x)..<x2 {
                var byteIndex = (bytesPerRow * y) + x * bytesPerPixel
                let alpha  = rawData[byteIndex + 3]
                if alpha > 200 {
                    let red   = rawData[byteIndex]
                    let green = rawData[byteIndex + 1]
                    let blue  = rawData[byteIndex + 2]
                    byteIndex += bytesPerPixel

                    var c = UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: CGFloat(alpha)/255.0)
                    result.append(c)
                }
            }
        }

        return result
    }

    public func getAverageLightness(inRect rect: CGRect? = nil) -> CGFloat {
        // Get a list of colors near the top of the image
        let colors = getPixelData(inRect: rect)

        var avg = [CGFloat](count: 4, repeatedValue: 0)
        var rgb = [CGFloat](count: 4, repeatedValue: 0)
        for color in colors {
            color.getRed(&rgb[0], green: &rgb[1], blue: &rgb[2], alpha: &rgb[3])
            avg[0] += rgb[0]
            avg[1] += rgb[1]
            avg[2] += rgb[2]
            avg[3] += rgb[3]
        }
        avg[0] /= CGFloat(colors.count)
        avg[1] /= CGFloat(colors.count)
        avg[2] /= CGFloat(colors.count)
        avg[3] /= CGFloat(colors.count)

        // Now convert to hsl and use lightness to determine if this is light or not.
        var c = UIColor(red: avg[0], green: avg[1], blue: avg[2], alpha: avg[3])
        var hsl = [CGFloat](count: 4, repeatedValue: 0)
        c.getHue(&hsl[0], saturation: &hsl[1], brightness: &hsl[2], alpha: &hsl[3])
        return hsl[2]
    }
}

public class ImageOperation : NSObject, SDWebImageOperation {
    public var cacheOperation: NSOperation?

    var cancelled: Bool {
        if let cacheOperation = cacheOperation {
            return cacheOperation.cancelled
        }
        return false
    }

    @objc public func cancel() {
        if let cacheOperation = cacheOperation {
            cacheOperation.cancel()
        }
    }
}

// This is an extension to SDWebImage's api to allow passing in a cache to be used for lookup.
public typealias CompletionBlock = (img: UIImage?, err: NSError, type: SDImageCacheType, key: String) -> Void
extension UIImageView {
    // This is a helper function for custom async loaders. It starts an operation that will check for the image in
    // a cache (either one passed in or the default if none is specified). If its found in the cache its returned,
    // otherwise, block is run and should return an image to show.
    private func runBlockIfNotInCache(key: String, var cache: SDImageCache? = nil, completed: CompletionBlock, block: () -> UIImage?) {
        self.sd_cancelCurrentImageLoad()

        let operation = ImageOperation()
        if cache == nil {
            cache = SDImageCache.sharedImageCache()
        }

        operation.cacheOperation = cache!.queryDiskCacheForKey(key, done: { (var image, cacheType) -> Void in
            let err = NSError()
            // If this was cancelled, don't bother notifying the caller
            if operation.cancelled {
                return
            }

            // If it was found in the cache, we can just use it
            if let image = image {
                self.image = image
                self.setNeedsLayout()
            } else {
                // Otherwise, the block has a chance to load it
                image = block()
                if image != nil {
                    self.image = image
                    cache!.storeImage(image, forKey: key)
                }
            }

            completed(img: image, err: err, type: cacheType, key: key)
        })

        self.sd_setImageLoadOperation(operation, forKey: "UIImageViewImageLoad")
    }

    public func moz_getImageFromCache(key: String, cache: SDImageCache, completed: CompletionBlock) {
        // This cache is filled outside of here. If we don't find the key in it, nothing to do here.
        runBlockIfNotInCache(key, cache: cache, completed: completed) { _ in return nil}
    }

    // Looks up an asset in local storage.
    public func moz_loadAsset(named: String, completed: CompletionBlock) {
        runBlockIfNotInCache(named, completed: completed) {
            return UIImage(named: named)
        }
    }
}