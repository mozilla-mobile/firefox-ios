/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let DiskReaderModeCacheSharedInstance = DiskReaderModeCache()
private let MemoryReaderModeCacheSharedInstance = MemoryReaderModeCache()

let ReaderModeCacheErrorDomain = "com.mozilla.client.readermodecache."
enum ReaderModeCacheErrorCode: Int {
    case NoPathsFound = 0
}

// NSObject wrapper around ReadabilityResult Swift struct for adding into the NSCache
private class ReadabilityResultWrapper: NSObject {
    let result: ReadabilityResult

    init(readabilityResult: ReadabilityResult) {
        self.result = readabilityResult
        super.init()
    }
}

protocol ReaderModeCache {
    func put(url: NSURL, _ readabilityResult: ReadabilityResult) throws

    func get(url: NSURL) throws -> ReadabilityResult

    func delete(url: NSURL, error: NSErrorPointer)

    func contains(url: NSURL) -> Bool
}

/// A non-persistent cache for readerized content for times when you don't want to write reader data to disk.
/// For example, when the user is in a private tab, we want to make sure that we leave no trace on the file system
class MemoryReaderModeCache: ReaderModeCache {
    var cache: NSCache

    init(cache: NSCache = NSCache()) {
        self.cache = cache
    }

    class var sharedInstance: ReaderModeCache {
        return MemoryReaderModeCacheSharedInstance
    }

    func put(url: NSURL, _ readabilityResult: ReadabilityResult) throws {
        cache.setObject(ReadabilityResultWrapper(readabilityResult: readabilityResult), forKey: url)
    }

    func get(url: NSURL) throws -> ReadabilityResult {
        guard let resultWrapper = cache.objectForKey(url) as? ReadabilityResultWrapper else {
            throw NSError(domain: ReaderModeCacheErrorDomain, code: ReaderModeCacheErrorCode.NoPathsFound.rawValue, userInfo: nil)
        }
        return resultWrapper.result
    }

    func delete(url: NSURL, error: NSErrorPointer) {
        cache.removeObjectForKey(url)
    }

    func contains(url: NSURL) -> Bool {
        return cache.objectForKey(url) != nil
    }
}

/// Really basic persistent cache to store readerized content. Has a simple hashed structure
/// to avoid storing many items in the same directory.
///
/// This currently lives in ~/Library/Caches so that the data can be pruned in case the OS needs
/// more space. Whether that is a good idea or not is not sure. We have a bug on file to investigate
/// and improve at a later time.
class DiskReaderModeCache: ReaderModeCache {
    class var sharedInstance: ReaderModeCache {
        return DiskReaderModeCacheSharedInstance
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