/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared

private let log = Logger.syncLogger

private class CachedSource {
    // We track not just mappings between values and non-nil items, but also whether we've tried
    // to look up a value at all. This allows us to distinguish between a cache miss and a
    // cache hit that didn't find an item in the backing store.
    // We expect, given our prefetching, that cache misses will be rare.
    fileprivate var cache: [GUID: BookmarkMirrorItem] = [:]
    fileprivate var seen: Set<GUID> = Set()

    subscript(guid: GUID) -> BookmarkMirrorItem? {
        get {
            return self.cache[guid]
        }

        set(value) {
            self.cache[guid] = value
        }
    }

    func lookup(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>>? {
        guard self.seen.contains(guid) else {
            log.warning("Cache miss for \(guid).")
            return nil
        }

        guard let found = self.cache[guid] else {
            log.verbose("Cache hit, but no record found for \(guid).")
            return deferMaybe(NoSuchRecordError(guid: guid))
        }

        log.verbose("Cache hit for \(guid).")
        return deferMaybe(found)
    }

    var isEmpty: Bool {
        return self.cache.isEmpty
    }

    // fill and seen are separate: we won't find every item in the DB.
    func fill(_ items: [GUID: BookmarkMirrorItem]) -> Success {
        for (x, y) in items {
            self.cache[x] = y
        }
        return succeed()
    }

    func markSeen(_ guid: GUID) {
        self.seen.insert(guid)
    }

    func markSeen<T: Sequence>(_ guids: T) where T.Iterator.Element == GUID {
        self.seen.formUnion(guids)
    }

    func takingGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        var out: [GUID: BookmarkMirrorItem] = [:]
        guids.forEach {
            if let v = self.cache[$0] {
                out[$0] = v
            }
        }
        return deferMaybe(out)
    }
}

// Sorry about the boilerplate.
// These are separate protocols so that the method names don't collide when implemented
// by the same class, but that means extracting more base implementation is more trouble than
// it's worth.
open class CachingLocalItemSource: LocalItemSource {
    fileprivate let cache: CachedSource
    fileprivate let source: LocalItemSource

    public init(source: LocalItemSource) {
        self.cache = CachedSource()
        self.source = source
    }

    open func getLocalItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        if let found = self.cache.lookup(guid) {
            return found
        }

        return self.source.getLocalItemWithGUID(guid) >>== effect {
            self.cache.markSeen(guid)
            self.cache[guid] = $0
        }
    }

    open func getLocalItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        return self.prefetchLocalItemsWithGUIDs(guids) >>> { self.cache.takingGUIDs(guids) }
    }

    open func prefetchLocalItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        log.debug("Prefetching \(guids.count) local items: \(guids.prefix(10))….")
        if guids.isEmpty {
            return succeed()
        }

        return self.source.getLocalItemsWithGUIDs(guids) >>== {
            self.cache.markSeen(guids)
            return self.cache.fill($0)
        }
    }
}

open class CachingMirrorItemSource: MirrorItemSource {
    fileprivate let cache: CachedSource
    fileprivate let source: MirrorItemSource

    public init(source: MirrorItemSource) {
        self.cache = CachedSource()
        self.source = source
    }

    open func getMirrorItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        if let found = self.cache.lookup(guid) {
            return found
        }

        return self.source.getMirrorItemWithGUID(guid) >>== effect {
            self.cache.markSeen(guid)
            self.cache[guid] = $0
        }
    }

    open func getMirrorItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        return self.prefetchMirrorItemsWithGUIDs(guids) >>> { self.cache.takingGUIDs(guids) }
    }

    open func prefetchMirrorItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        log.debug("Prefetching \(guids.count) mirror items: \(guids.prefix(10))….")
        if guids.isEmpty {
            return succeed()
        }

        return self.source.getMirrorItemsWithGUIDs(guids) >>== {
            self.cache.markSeen(guids)
            return self.cache.fill($0)
        }
    }
}

open class CachingBufferItemSource: BufferItemSource {
    fileprivate let cache: CachedSource
    fileprivate let source: BufferItemSource

    public init(source: BufferItemSource) {
        self.cache = CachedSource()
        self.source = source
    }

    open func getBufferItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        if let found = self.cache.lookup(guid) {
            return found
        }

        return self.source.getBufferItemWithGUID(guid) >>== effect {
            self.cache.markSeen(guid)
            self.cache[guid] = $0
        }
    }

    open func getBufferItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        return self.prefetchBufferItemsWithGUIDs(guids) >>> { self.cache.takingGUIDs(guids) }
    }

    open func prefetchBufferItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        log.debug("Prefetching \(guids.count) buffer items: \(guids.prefix(10))….")
        if guids.isEmpty {
            return succeed()
        }

        return self.source.getBufferItemsWithGUIDs(guids) >>== {
            self.cache.markSeen(guids)
            return self.cache.fill($0)
        }
    }
}
