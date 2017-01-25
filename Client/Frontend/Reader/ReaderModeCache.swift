/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let DiskReaderModeCacheSharedInstance = DiskReaderModeCache()
private let MemoryReaderModeCacheSharedInstance = MemoryReaderModeCache()

let ReaderModeCacheErrorDomain = "com.mozilla.client.readermodecache."
enum ReaderModeCacheErrorCode: Int {
    case noPathsFound = 0
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
    func put(_ url: URL, _ readabilityResult: ReadabilityResult) throws

    func get(_ url: URL) throws -> ReadabilityResult

    func delete(_ url: URL, error: NSErrorPointer)

    func contains(_ url: URL) -> Bool
}

/// A non-persistent cache for readerized content for times when you don't want to write reader data to disk.
/// For example, when the user is in a private tab, we want to make sure that we leave no trace on the file system
class MemoryReaderModeCache: ReaderModeCache {
    var cache: NSCache<AnyObject, AnyObject>

    init(cache: NSCache<AnyObject, AnyObject> = NSCache()) {
        self.cache = cache
    }

    class var sharedInstance: ReaderModeCache {
        return MemoryReaderModeCacheSharedInstance
    }

    func put(_ url: URL, _ readabilityResult: ReadabilityResult) throws {
        cache.setObject(ReadabilityResultWrapper(readabilityResult: readabilityResult), forKey: url as AnyObject)
    }

    func get(_ url: URL) throws -> ReadabilityResult {
        guard let resultWrapper = cache.object(forKey: url as AnyObject) as? ReadabilityResultWrapper else {
            throw NSError(domain: ReaderModeCacheErrorDomain, code: ReaderModeCacheErrorCode.noPathsFound.rawValue, userInfo: nil)
        }
        return resultWrapper.result
    }

    func delete(_ url: URL, error: NSErrorPointer) {
        cache.removeObject(forKey: url as AnyObject)
    }

    func contains(_ url: URL) -> Bool {
        return cache.object(forKey: url as AnyObject) != nil
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

    func put(_ url: URL, _ readabilityResult: ReadabilityResult) throws {
        guard let (cacheDirectoryPath, contentFilePath) = cachePathsForURL(url) else {
            throw NSError(domain: ReaderModeCacheErrorDomain, code: ReaderModeCacheErrorCode.noPathsFound.rawValue, userInfo: nil)
        }

        try FileManager.default.createDirectory(atPath: cacheDirectoryPath, withIntermediateDirectories: true, attributes: nil)
        let string: String = readabilityResult.encode()
        try string.write(toFile: contentFilePath, atomically: true, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        return
    }

    func get(_ url: URL) throws -> ReadabilityResult {
        if let (_, contentFilePath) = cachePathsForURL(url), FileManager.default.fileExists(atPath: contentFilePath) {
            let string = try NSString(contentsOfFile: contentFilePath, encoding: String.Encoding.utf8.rawValue)
            if let value = ReadabilityResult(string: string as String) {
                return value
            }
        }

        throw NSError(domain: ReaderModeCacheErrorDomain, code: ReaderModeCacheErrorCode.noPathsFound.rawValue, userInfo: nil)
    }

    func delete(_ url: URL, error: NSErrorPointer) {
        guard let (cacheDirectoryPath, _) = cachePathsForURL(url) else { return }

        if FileManager.default.fileExists(atPath: cacheDirectoryPath) {
            do {
                try FileManager.default.removeItem(atPath: cacheDirectoryPath)
            } catch let error1 as NSError {
                error?.pointee = error1
            }
        }
    }

    func contains(_ url: URL) -> Bool {
        if let (_, contentFilePath) = cachePathsForURL(url), FileManager.default.fileExists(atPath: contentFilePath) {
            return true
        }

        return false
    }

    fileprivate func cachePathsForURL(_ url: URL) -> (cacheDirectoryPath: String, contentFilePath: String)? {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        if !paths.isEmpty, let hashedPath = hashedPathForURL(url) {
            let cacheDirectoryURL = URL(fileURLWithPath: NSString.path(withComponents: [paths[0], "ReaderView", hashedPath]))
            return (cacheDirectoryURL.path, cacheDirectoryURL.appendingPathComponent("content.json").path)
        }

        return nil
    }

    fileprivate func hashedPathForURL(_ url: URL) -> String? {
        guard let hash = hashForURL(url) else { return nil }

        return NSString.path(withComponents: [hash.substring(with: NSRange(location: 0, length: 2)), hash.substring(with: NSRange(location: 2, length: 2)), hash.substring(from: 4)]) as String
    }

    fileprivate func hashForURL(_ url: URL) -> NSString? {
        guard let data = url.absoluteString.data(using: String.Encoding.utf8) else { return nil }

        return data.sha1.hexEncodedString as NSString?
    }
}
