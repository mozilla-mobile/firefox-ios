/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

private let ThumbnailsDirName = "thumbnails"

/**
 * Disk-backed implementation of the Thumbnails protocol.
 */
public class FileThumbnails: Thumbnails {
    private let files: FileAccessor
    private let thumbnailsDir: String

    required public init(files: FileAccessor) {
        self.files = files
        thumbnailsDir = files.getAndEnsureDirectory(relativeDir: ThumbnailsDirName)!
    }

    public func clear(complete: ((success: Bool) -> Void)?) {
        let success = files.removeFilesInDirectory(relativePath: ThumbnailsDirName)

        dispatch_async(dispatch_get_main_queue()) {
            complete?(success: success)
            return
        }
    }

    public func get(url: NSURL, complete: (thumbnail: Thumbnail?) -> Void) {
        var thumbnail: Thumbnail? = nil

        if let filename = getFilename(url) {
            let thumbnailPath = thumbnailsDir.stringByAppendingPathComponent(filename)
            if let data = NSData(contentsOfFile: thumbnailPath) {
                if let image = UIImage(data: data) {
                    thumbnail = Thumbnail(image: image)
                }
            }
        }

        dispatch_async(dispatch_get_main_queue()) {
            complete(thumbnail: thumbnail)
            return
        }
    }

    public func set(url: NSURL, thumbnail: Thumbnail, complete: ((success: Bool) -> Void)?) {
        var success = false

        if let filename = getFilename(url) {
            let thumbnailPath = thumbnailsDir.stringByAppendingPathComponent(filename)
            let data = UIImagePNGRepresentation(thumbnail.image)
            success = data.writeToFile(thumbnailPath, atomically: false)
        }

        dispatch_async(dispatch_get_main_queue()) {
            complete?(success: success)
            return
        }
    }

    /**
     * Returns a hex encoded String of the URL's SHA1 hash,
     * which is used as the thumbnail filename.
     */
    private func getFilename(url: NSURL) -> String? {
        return url.absoluteString?.sha1.hexEncodedString
    }
}
