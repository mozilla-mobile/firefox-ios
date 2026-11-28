// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// FXIOS-13517 - MemoryReaderModeCache is not thread safe
/// A non-persistent cache for reader mode content for times when you don't want to write reader data to disk.
/// For example, when the user is in a private tab, we want to make sure that we leave no trace on the file system
///
/// Reads that miss in memory fall through to an optional, read-only `fallback` so content that was already
/// stored on disk (e.g. reading list items saved from a regular tab) is still available. Writes, deletes and
/// clears only ever touch the in-memory cache.
public final class MemoryReaderModeCache: ReaderModeCache, @unchecked Sendable {
    public static let shared = MemoryReaderModeCache(fallback: DiskReaderModeCache.shared)
    private var cache: NSCache<AnyObject, AnyObject>
    private let fallback: ReaderModeCache?

    init(cache: NSCache<AnyObject, AnyObject> = NSCache(), fallback: ReaderModeCache? = nil) {
        self.cache = cache
        self.fallback = fallback
    }

    public func put(_ url: URL, _ readabilityResult: ReadabilityResult) throws {
        cache.setObject(ReadabilityResultWrapper(readabilityResult: readabilityResult), forKey: url as AnyObject)
    }

    public func get(_ url: URL) throws -> ReadabilityResult {
        guard let resultWrapper = cache.object(forKey: url as AnyObject) as? ReadabilityResultWrapper else {
            if let fallback, let result = try? fallback.get(url) {
                return result
            }
            throw NSError(
                domain: ReaderModeError.domain,
                code: ReaderModeError.CacheError.noPathsFound.rawValue,
                userInfo: nil
            )
        }
        return resultWrapper.result
    }

    public func delete(_ url: URL, error: NSErrorPointer) {
        cache.removeObject(forKey: url as AnyObject)
    }

    public func contains(_ url: URL) -> Bool {
        return cache.object(forKey: url as AnyObject) != nil || fallback?.contains(url) == true
    }

    public func clear() {
        cache.removeAllObjects()
    }
}
