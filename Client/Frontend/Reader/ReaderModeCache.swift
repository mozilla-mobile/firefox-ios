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

    func put(url: NSURL, _ readabilityResult: ReadabilityResult) throws {
        let error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        guard let cacheDirectoryPath = cacheDirectoryForURL(url) else { throw error }
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(cacheDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            let contentFilePath = (cacheDirectoryPath as NSString).stringByAppendingPathComponent("content.json")
            let string: NSString = readabilityResult.encode()
            try string.writeToFile(contentFilePath, atomically: true, encoding: NSUTF8StringEncoding)
            return
        } catch let error1 as NSError {
            throw error1
        }
    }

    func get(url: NSURL) throws -> ReadabilityResult {
        var error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        let cacheDirectoryURL = url.URLByAppendingPathComponent("content.json")
        guard let contentFilePath = cacheDirectoryForURL(cacheDirectoryURL) else {
            throw error
        }

        if NSFileManager.defaultManager().fileExistsAtPath(contentFilePath) {
            do {
                let string = try NSString(contentsOfFile: contentFilePath, encoding: NSUTF8StringEncoding)
                if let value = ReadabilityResult(string: string as String) {
                    return value
                }
            } catch let error1 as NSError {
                error = error1
            }
        }
        throw error
    }

    func delete(url: NSURL, error: NSErrorPointer) {
        guard let cacheDirectoryPath = cacheDirectoryForURL(url) else { return }
        if NSFileManager.defaultManager().fileExistsAtPath(cacheDirectoryPath) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(cacheDirectoryPath)
            } catch let error1 as NSError {
                error.memory = error1
            }
        }
    }

    func contains(url: NSURL) throws {
        let error: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
        let cacheDirectoryURL = url.URLByAppendingPathComponent("content.json")
        guard let contentFilePath = cacheDirectoryForURL(cacheDirectoryURL) else { throw error }
        if !NSFileManager.defaultManager().fileExistsAtPath(contentFilePath) {
            throw error
        }
    }

    private func cacheDirectoryForURL(url: NSURL) -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        if paths.count > 0 {
            if let hashedPath = hashedPathForURL(url) {
               return NSString.pathWithComponents([paths[0], "ReaderView", hashedPath]) as String
            }
        }
        return nil
    }

    private func hashedPathForURL(url: NSURL) -> String? {
        guard let hash = hashForURL(url) else { return nil }
        return NSString.pathWithComponents([hash.substringWithRange(NSMakeRange(0, 2)), hash.substringWithRange(NSMakeRange(2, 2)), hash.substringFromIndex(4)]) as String
    }

    private func hashForURL(url: NSURL) -> NSString? {
        guard let data = url.absoluteString.dataUsingEncoding(NSUTF8StringEncoding) else { return nil }
        return data.sha1.hexEncodedString
    }
}