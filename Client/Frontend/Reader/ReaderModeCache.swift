/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let ReaderModeCacheSharedInstance = ReaderModeCache()

/// Really basic persistent cache to store readerized content. Has a simple hashed structure
/// to avoid storing many items in the same directory.
///
/// This currently lives in ~/Library/Caches so that the data can be pruned in case the OS needs
/// more space. Whether that is a good idea or not is not sure. We have a bug on file to investigate
/// and improve at a later time.

class ReaderModeCache {
    class var sharedInstance: ReaderModeCache {
        return ReaderModeCacheSharedInstance
    }

    func put(url: NSURL, _ readabilityResult: ReadabilityResult, error: NSErrorPointer) -> Bool {
        if let cacheDirectoryPath = cacheDirectoryForURL(url) {
            if NSFileManager.defaultManager().createDirectoryAtPath(cacheDirectoryPath, withIntermediateDirectories: true, attributes: nil, error: error) {
                let contentFilePath = cacheDirectoryPath.stringByAppendingPathComponent("content.json")
                let string: NSString = readabilityResult.encode()
                return string.writeToFile(contentFilePath, atomically: true, encoding: NSUTF8StringEncoding, error: error)
            }
        }
        return false
    }

    func get(url: NSURL, error: NSErrorPointer) -> ReadabilityResult? {
        if let cacheDirectoryPath = cacheDirectoryForURL(url) {
            let contentFilePath = cacheDirectoryPath.stringByAppendingPathComponent("content.json")
            if NSFileManager.defaultManager().fileExistsAtPath(contentFilePath) {
                if let string = NSString(contentsOfFile: contentFilePath, encoding: NSUTF8StringEncoding, error: error) {
                    return ReadabilityResult(string: string)
                }
            }
        }
        return nil
    }

    func delete(url: NSURL, error: NSErrorPointer) {
        if let cacheDirectoryPath = cacheDirectoryForURL(url) {
            if NSFileManager.defaultManager().fileExistsAtPath(cacheDirectoryPath) {
                NSFileManager.defaultManager().removeItemAtPath(cacheDirectoryPath, error: error)
            }
        }
    }

    func contains(url: NSURL, error: NSErrorPointer) -> Bool {
        if let cacheDirectoryPath = cacheDirectoryForURL(url) {
            let contentFilePath = cacheDirectoryPath.stringByAppendingPathComponent("content.json")
            return NSFileManager.defaultManager().fileExistsAtPath(contentFilePath)
        }
        return false
    }

    private func cacheDirectoryForURL(url: NSURL) -> NSString? {
        if let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true) as? [String] {
            if paths.count > 0 {
                if let hashedPath = hashedPathForURL(url) {
                    return NSString.pathWithComponents([paths[0], "ReaderView", hashedPath])
                }
            }
        }
        return nil
    }

    private func hashedPathForURL(url: NSURL) -> NSString? {
        if let hash = hashForURL(url) {
            return NSString.pathWithComponents([hash.substringWithRange(NSMakeRange(0, 2)), hash.substringWithRange(NSMakeRange(2, 2)), hash.substringFromIndex(4)])
        }
        return nil
    }

    private func hashForURL(url: NSURL) -> NSString? {
        if let absoluteString = url.absoluteString {
            if let data = absoluteString.dataUsingEncoding(NSUTF8StringEncoding) {
                return data.sha1.hexEncodedString
            }
        }
        return nil
    }
}