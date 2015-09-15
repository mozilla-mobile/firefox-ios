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

let ReaderModeCacheErrorDomain = "com.mozilla.client.readermodecache."
enum ReaderModeCacheErrorCode: Int {
    case NoPathsFound = 0
}

class ReaderModeCache {
    class var sharedInstance: ReaderModeCache {
        return ReaderModeCacheSharedInstance
    }

    func put(url: NSURL, _ readabilityResult: ReadabilityResult) throws {
        guard let (cacheDirectoryPath, contentFilePath) = cachePathsForURL(url) else {
            throw NSError(domain: ReaderModeCacheErrorDomain, code: ReaderModeCacheErrorCode.NoPathsFound.rawValue, userInfo: nil)
        }

        try NSFileManager.defaultManager().createDirectoryAtPath(cacheDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        let string: NSString = readabilityResult.encode()
        try string.writeToFile(contentFilePath, atomically: true, encoding: NSUTF8StringEncoding)
        return
    }

    func get(url: NSURL) throws -> ReadabilityResult {
        if let (_, contentFilePath) = cachePathsForURL(url) where NSFileManager.defaultManager().fileExistsAtPath(contentFilePath) {
            let string = try NSString(contentsOfFile: contentFilePath, encoding: NSUTF8StringEncoding)
            if let value = ReadabilityResult(string: string as String) {
                return value
            }
        }

        throw NSError(domain: ReaderModeCacheErrorDomain, code: ReaderModeCacheErrorCode.NoPathsFound.rawValue, userInfo: nil)
    }

    func delete(url: NSURL, error: NSErrorPointer) {
        guard let (cacheDirectoryPath, _) = cachePathsForURL(url) else { return }

        if NSFileManager.defaultManager().fileExistsAtPath(cacheDirectoryPath) {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(cacheDirectoryPath)
            } catch let error1 as NSError {
                error.memory = error1
            }
        }
    }

    func contains(url: NSURL) -> Bool {
        if let (_, contentFilePath) = cachePathsForURL(url) where NSFileManager.defaultManager().fileExistsAtPath(contentFilePath) {
            return true
        }

        return false
    }

    private func cachePathsForURL(url: NSURL) -> (cacheDirectoryPath: String, contentFilePath: String)? {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        if !paths.isEmpty, let hashedPath = hashedPathForURL(url) {
            let cacheDirectoryURL = NSURL(fileURLWithPath: NSString.pathWithComponents([paths[0], "ReaderView", hashedPath]))
            if let cacheDirectoryPath = cacheDirectoryURL.path,
                   contentFilePath = cacheDirectoryURL.URLByAppendingPathComponent("content.json").path {
                return (cacheDirectoryPath, contentFilePath)
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