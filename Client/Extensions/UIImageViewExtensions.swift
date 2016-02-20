/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import WebImage

public extension UIImageView {
    public func setIcon(icon: Favicon?, withPlaceholder placeholder: UIImage) {
        if let icon = icon {
            let imageURL = NSURL(string: icon.url)
            self.sd_setImageWithURL(imageURL, placeholderImage: placeholder)
            return
        }
        self.image = placeholder
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
            let err = NSError(domain: "UIImage+Extensions.runBlockIfNotInCache", code: 0, userInfo: nil)
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