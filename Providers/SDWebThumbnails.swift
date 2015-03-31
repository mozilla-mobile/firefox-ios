/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage

/**
 * SDWebImage implementation of the Thumbnails protocol.
 */
public class SDWebThumbnails: Thumbnails {
    let cache: SDImageCache

    required public init(files: FileAccessor) {
        self.cache = SDImageCache(namespace: "thumbnails")
    }

    public func clear(complete: ((success: Bool) -> Void)?) {
        cache.clearMemory()
        cache.clearDiskOnCompletion { () -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                complete?(success: true)
                return
            }
        }
    }

    public class func getKey(url: NSURL) -> String {
        return getKey(url.absoluteString!)
    }

    public class func getKey(url: String) -> String {
        return "thumbnail://\(url)"
    }

    public func get(url: NSURL, complete: (thumbnail: Thumbnail?) -> Void) {
        var thumbnail: Thumbnail? = nil
        let key = SDWebThumbnails.getKey(url)
        if let img = cache.imageFromDiskCacheForKey(key) {
            thumbnail = Thumbnail(image: img)
        }

        dispatch_async(dispatch_get_main_queue()) {
            complete(thumbnail: thumbnail)
        }
    }

    public func set(url: NSURL, thumbnail: Thumbnail, complete: ((success: Bool) -> Void)?) {
        let key = SDWebThumbnails.getKey(url)
        cache.storeImage(thumbnail.image, forKey: key)

        dispatch_async(dispatch_get_main_queue()) {
            complete?(success: true)
            return
        }
    }
}
