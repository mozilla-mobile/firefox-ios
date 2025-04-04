// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A non-persistent cache for reader mode content for times when you don't want to write reader data to disk.
/// For example, when the user is in a private tab, we want to make sure that we leave no trace on the file system
public final class MemoryReaderModeCache: ReaderModeCache {
    public static let shared = MemoryReaderModeCache()
    private var cache: NSCache<AnyObject, AnyObject>

    init(cache: NSCache<AnyObject, AnyObject> = NSCache()) {
        self.cache = cache
    }

    public func put(_ url: URL, _ readabilityResult: ReadabilityResult) throws {
        cache.setObject(ReadabilityResultWrapper(readabilityResult: readabilityResult), forKey: url as AnyObject)
    }

    public func get(_ url: URL) throws -> ReadabilityResult {
        guard let resultWrapper = cache.object(forKey: url as AnyObject) as? ReadabilityResultWrapper else {
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
        return cache.object(forKey: url as AnyObject) != nil
    }

    public func clear() {
        cache.removeAllObjects()
    }
}
