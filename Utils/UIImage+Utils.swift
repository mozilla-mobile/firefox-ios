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

private class ThumbnailOperation : NSObject, SDWebImageOperation {
    var cacheOperation: NSOperation?

    var cancelled: Bool {
        if let cacheOperation = cacheOperation {
            return cacheOperation.cancelled
        }
        return false
    }

    func cancel() {
        if let cacheOperation = cacheOperation {
            cacheOperation.cancel()
        }
    }
}

// This is an extension to SDWebImage's api to allow passing in a cache to be used for lookup.
public typealias CompletionBlock = (img: UIImage?, err: NSError, type: SDImageCacheType, key: String) -> Void
extension UIImageView {
    public func moz_getImageFromCache(url: String, cache: SDImageCache, completed: CompletionBlock) {
        self.sd_cancelCurrentImageLoad()

        let operation = ThumbnailOperation()
        let key = SDWebThumbnails.getKey(url)
        operation.cacheOperation = cache.queryDiskCacheForKey(key, done: { (image, cacheType) -> Void in
            let err = NSError()
            // If this was cancelled, don't bother notifying the caller
            if operation.cancelled {
                return
            }

            if let image = image {
                self.image = image
                self.setNeedsLayout()
            }

            completed(img: image, err: err, type: cacheType, key: url)
        })

        self.sd_setImageLoadOperation(operation, forKey: "UIImageViewImageLoad")
    }
}