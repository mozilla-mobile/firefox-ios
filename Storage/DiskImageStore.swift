/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import UIKit

private class DiskImageStoreErrorType: MaybeErrorType {
    let description: String
    init(description: String) {
        self.description = description
    }
}

/**
 * Disk-backed key-value image store.
 */
public class DiskImageStore {
    private let files: FileAccessor
    private let filesDir: String
    private let queue = dispatch_queue_create("DiskImageStore", DISPATCH_QUEUE_CONCURRENT)
    private let quality: CGFloat
    private var keys: Set<String>

    required public init(files: FileAccessor, namespace: String, quality: Float) {
        self.files = files
        self.filesDir = try! files.getAndEnsureDirectory(namespace)
        self.quality = CGFloat(quality)

        // Build an in-memory set of keys from the existing images on disk.
        var keys = [String]()
        if let fileEnumerator = NSFileManager.defaultManager().enumeratorAtPath(filesDir) {
            for file in fileEnumerator {
                keys.append(file as! String)
            }
        }
        self.keys = Set(keys)
    }

    /// Gets an image for the given key if it is in the store.
    public func get(key: String) -> Deferred<Maybe<UIImage>> {
        if !keys.contains(key) {
            return deferMaybe(DiskImageStoreErrorType(description: "Image key not found"))
        }

        return deferDispatchAsync(queue) { () -> Deferred<Maybe<UIImage>> in
            let imagePath = (self.filesDir as NSString).stringByAppendingPathComponent(key)
            if let data = NSData(contentsOfFile: imagePath),
                let image = UIImage(data: data)
            {
                return deferMaybe(image)
            }

            return deferMaybe(DiskImageStoreErrorType(description: "Invalid image data"))
        }
    }

    /// Adds an image for the given key.
    /// This put is asynchronous; the image is not recorded in the cache until the write completes.
    /// Does nothing if this key already exists in the store.
    public func put(key: String, image: UIImage) -> Success {
        if keys.contains(key) {
            return deferMaybe(DiskImageStoreErrorType(description: "Key already in store"))
        }

        return deferDispatchAsync(queue) { () -> Success in
            let imagePath = (self.filesDir as NSString).stringByAppendingPathComponent(key)
            if let data = UIImageJPEGRepresentation(image, self.quality) {
                if data.writeToFile(imagePath, atomically: false) {
                    self.keys.insert(key)
                    return succeed()
                }
            }

            return deferMaybe(DiskImageStoreErrorType(description: "Could not write image to file"))
        }
    }

    /// Clears all images from the cache, excluding the given set of keys.
    public func clearExcluding(keys: Set<String>) {
        let keysToDelete = self.keys.subtract(keys)

        for key in keysToDelete {
            let path = NSString(string: filesDir).stringByAppendingPathComponent(key)
            try! NSFileManager.defaultManager().removeItemAtPath(path)
        }

        self.keys = self.keys.intersect(keys)
    }
}
