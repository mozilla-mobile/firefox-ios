/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import os.log

internal typealias APIHandle = UInt64
internal typealias ConnectionHandle = UInt64

/**
 * This is something like a places connection manager. It primarialy exists to
 * ensure that only a single write connection is active at once.
 *
 * If it helps, you can think of this as something like a connection pool
 * (although it does not actually perform any pooling).
 */
public class PlacesAPI {
    private let handle: APIHandle
    private let writeConn: PlacesWriteConnection
    private let queue = DispatchQueue(label: "com.mozilla.places.api")
    private let interruptHandle: InterruptHandle

    /**
     * Initialize a PlacesAPI
     *
     * - Parameter path: an absolute path to a file that will be used for the internal database.
     *
     * - Throws: `PlacesError` if initializing the database failed.
     */
    public init(path: String) throws {
        let handle = try PlacesError.unwrap { error in
            places_api_new(path, error)
        }
        self.handle = handle
        do {
            let writeHandle = try PlacesError.unwrap { error in
                places_connection_new(handle, Int32(PlacesConn_ReadWrite), error)
            }
            writeConn = try PlacesWriteConnection(handle: writeHandle)

            interruptHandle = InterruptHandle(ptr: try PlacesError.unwrap { error in
                places_new_sync_conn_interrupt_handle(handle, error)
            })

            writeConn.api = self
        } catch let e {
            // We failed to open the write connection (or the interrupt handle),
            // even though the API was opened. This is... strange, but possible.
            // Anyway, we want to clean up our API if this happens.
            //
            // If closing the API fails, it's probably caused by the same
            // underlying problem as whatever made us fail to open the write
            // connection, so we'd rather use the first error, since it's
            // hopefully more descriptive.
            PlacesError.unwrapOrLog { error in
                places_api_destroy(handle, error)
            }
            // Note: We don't need to explicitly clean up `self.writeConn` in
            // the case that it gets opened successfully, but initializing
            // `self.interruptHandle` fails -- the `PlacesWriteConnection`
            // `deinit` should still run and do the right thing.
            throw e
        }
    }

    deinit {
        // Note: we shouldn't need to queue.sync with our queue in deinit (no more references
        // exist to us), however we still need to sync with the write conn's queue, since it
        // could still be in use.

        self.writeConn.queue.sync {
            // If the writer is still around (it should be), return it to the api.
            let writeHandle = self.writeConn.takeHandle()
            if writeHandle != 0 {
                PlacesError.unwrapOrLog { error in
                    places_api_return_write_conn(self.handle, writeHandle, error)
                }
            }
        }

        PlacesError.unwrapOrLog { error in
            places_api_destroy(self.handle, error)
        }
    }

    /**
     * Migrate bookmarks tables from a `browser.db` database.
     *
     * It is recommended that this only be called for non-sync users,
     * as syncing the bookmarks over will result in better handling of sync
     * metadata, among other things.
     *
     * This should be performed before any writes to the database.
     *
     * Throws:
     *     - `PlacesError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                          object from another thread.
     *
     *                                          This is allowed (although not ideal) and should leave
     *                                          the database in a valid state.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *
     *                                 In particular, no explicit error is exposed for the
     *                                 case where `path` is not valid or does not exist,
     *                                 but it will show up here.
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    open func migrateBookmarksFromBrowserDb(path: String) throws {
        try queue.sync {
            try PlacesError.unwrap { error in
                places_bookmarks_import_from_ios(handle, path, error)
            }
        }
    }

    /**
     * Open a new reader connection.
     *
     * - Throws: `PlacesError` if a connection could not be opened.
     */
    open func openReader() throws -> PlacesReadConnection {
        return try queue.sync {
            let conn = try PlacesError.unwrap { error in
                places_connection_new(handle, Int32(PlacesConn_ReadOnly), error)
            }
            return try PlacesReadConnection(handle: conn, api: self)
        }
    }

    /**
     * Get the writer connection.
     *
     * - Note: There is only ever a single writer connection,
     *         and it's opened when the database is constructed,
     *         so this function does not throw
     */
    open func getWriter() -> PlacesWriteConnection {
        return queue.sync {
            self.writeConn
        }
    }

    /**
     * Sync the bookmarks collection.
     *
     * - Returns: A JSON string representing a telemetry ping for this sync. The
     *            string contains the ping payload, and should be sent to the
     *            telemetry submission endpoint.
     *
     * - Throws:
     *     - `PlacesError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                          object from another thread.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    open func syncBookmarks(unlockInfo: SyncUnlockInfo) throws -> String {
        return try queue.sync {
            let pingStr = try PlacesError.unwrap { err in
                sync15_bookmarks_sync(handle,
                                      unlockInfo.kid,
                                      unlockInfo.fxaAccessToken,
                                      unlockInfo.syncKey,
                                      unlockInfo.tokenserverURL,
                                      err)
            }
            return String(freeingPlacesString: pingStr)
        }
    }

    /**
     * Resets all sync metadata for history, including change flags,
     * sync statuses, and last sync time. The next sync after reset
     * will behave the same way as a first sync when connecting a new
     * device.
     *
     * This method only needs to be called when the user disconnects
     * from Sync. There are other times when Places resets sync metadata,
     * but those are handled internally in the Rust code.
     *
     * - Throws:
     *     - `PlacesError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                          object from another thread.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    open func resetHistorySyncMetadata() throws {
        return try queue.sync {
            try PlacesError.unwrap { err in
                places_reset(handle, err)
            }
        }
    }

    /**
     * Resets all sync metadata for bookmarks, including change flags, sync statuses, and
     * last sync time. The next sync after reset will behave the same way as a first sync
     * when connecting a new device.
     *
     * - Throws:
     *     - `PlacesError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                          object from another thread.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    open func resetBookmarkSyncMetadata() throws {
        return try queue.sync {
            try PlacesError.unwrap { err in
                bookmarks_reset(handle, err)
            }
        }
    }

    /**
     * Attempt to interrupt a long-running operation which may be happening
     * concurrently (specifically, for `interrupt` on `PlacesAPI`, this refers
     * to a call to `sync`).
     *
     * If the operation is interrupted, it should fail with a
     * `PlacesError.databaseInterrupted` error.
     */
    open func interrupt() {
        interruptHandle.interrupt()
    }
}

/**
 * A read-only connection to the places database.
 */
public class PlacesReadConnection {
    fileprivate let queue = DispatchQueue(label: "com.mozilla.places.conn")
    fileprivate var handle: ConnectionHandle
    fileprivate weak var api: PlacesAPI?
    fileprivate let interruptHandle: InterruptHandle

    fileprivate init(handle: ConnectionHandle, api: PlacesAPI? = nil) throws {
        self.handle = handle
        self.api = api
        interruptHandle = InterruptHandle(ptr: try PlacesError.unwrap { error in
            places_new_interrupt_handle(handle, error)
        })
    }

    // Note: caller synchronizes!
    fileprivate func checkApi() throws {
        if api == nil {
            throw PlacesError.connUseAfterAPIClosed
        }
    }

    // Note: caller synchronizes!
    fileprivate func takeHandle() -> ConnectionHandle {
        let handle = self.handle
        self.handle = 0
        return handle
    }

    deinit {
        // Note: don't need to queue.sync in deinit -- no more references exist to us.
        let handle = self.takeHandle()
        if handle != 0 {
            // In practice this can only fail if the rust code panics.
            PlacesError.unwrapOrLog { err in
                places_connection_destroy(handle, err)
            }
        }
    }

    /**
     * Returns the bookmark subtree rooted at `rootGUID`.
     *
     * This differs from `getBookmark` in that it populates folder children
     * recursively (specifically, any `BookmarkFolder`s in the returned value
     * will have their `children` list populated, and not just `childGUIDs`.
     *
     * However, if `recursive: false` is passed, only a single level of child
     * nodes are returned for folders.
     *
     * - Parameter rootGUID: the GUID where to start the tree.
     *
     * - Parameter recursive: Whether or not to return more than a single
     *                        level of children for folders. If false, then
     *                        any folders which are children of the requested
     *                        node will *only* have their `childGUIDs`
     *                        populated, and *not* their `children`.
     *
     * - Returns: The bookmarks tree starting from `rootGUID`, or null if the
     *            provided guid didn't refer to a known bookmark item.
     * - Throws:
     *     - `PlacesError.databaseCorrupt`: If corruption is encountered when fetching
     *                                      the tree
     *     - `PlacesError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                          object from another thread.
     *     - `PlacesError.connUseAfterAPIClosed`: If the PlacesAPI that returned this connection
     *                                            object has been closed. This indicates API
     *                                            misuse.
     *     - `PlacesError.databaseBusy`: If this query times out with a SQLITE_BUSY error.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    open func getBookmarksTree(rootGUID: String, recursive: Bool) throws -> BookmarkNode? {
        return try queue.sync {
            try self.checkApi()
            let buffer = try PlacesError.unwrap { (error: UnsafeMutablePointer<PlacesRustError>) -> PlacesRustBuffer in
                if recursive {
                    return bookmarks_get_tree(self.handle, rootGUID, error)
                } else {
                    return bookmarks_get_by_guid(self.handle, rootGUID, 1, error)
                }
            }
            if buffer.data == nil {
                return nil
            }
            defer { places_destroy_bytebuffer(buffer) }
            // This should never fail, since we encoded it on the other side with Rust
            let msg = try MsgTypes_BookmarkNode(serializedData: Data(placesRustBuffer: buffer))
            return unpackProtobuf(msg: msg)
        }
    }

    /**
     * Returns the information about the bookmark with the provided id.
     *
     * This differs from `getBookmarksTree` in that it does not populate the `children` list
     * if `guid` refers to a folder (However, its `childGUIDs` list will be
     * populated).
     *
     * - Parameter guid: the guid of the bookmark to fetch.
     *
     * - Returns: The bookmark node, or null if the provided guid didn't refer to a
     *            known bookmark item.
     * - Throws:
     *     - `PlacesError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                          object from another thread.
     *     - `PlacesError.connUseAfterAPIClosed`: If the PlacesAPI that returned this connection
     *                                            object has been closed. This indicates API
     *                                            misuse.
     *     - `PlacesError.databaseBusy`: If this query times out with a SQLITE_BUSY error.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    open func getBookmark(guid: String) throws -> BookmarkNode? {
        return try queue.sync {
            try self.checkApi()
            let buffer = try PlacesError.unwrap { error in
                bookmarks_get_by_guid(self.handle, guid, 0, error)
            }
            if buffer.data == nil {
                return nil
            }
            defer { places_destroy_bytebuffer(buffer) }
            // This could probably be try!
            let msg = try MsgTypes_BookmarkNode(serializedData: Data(placesRustBuffer: buffer))
            return unpackProtobuf(msg: msg)
        }
    }

    /**
     * Returns the list of bookmarks with the provided URL.
     *
     * - Note: If the URL is not percent-encoded/punycoded, that will be performed
     *         internally, and so the returned bookmarks may not have an identical
     *         URL to the one passed in, however, it will be the same according to
     *         https://url.spec.whatwg.org
     *
     * - Parameter url: The url to search for.
     *
     * - Returns: A list of bookmarks that have the requested URL.
     *
     * - Throws:
     *     - `PlacesError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                          object from another thread.
     *     - `PlacesError.connUseAfterAPIClosed`: If the PlacesAPI that returned this connection
     *                                            object has been closed. This indicates API
     *                                            misuse.
     *     - `PlacesError.databaseBusy`: If this query times out with a SQLITE_BUSY error.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    open func getBookmarksWithURL(url: String) throws -> [BookmarkItem] {
        return try queue.sync {
            try self.checkApi()
            let buffer = try PlacesError.unwrap { error in
                bookmarks_get_all_with_url(self.handle, url, error)
            }
            defer { places_destroy_bytebuffer(buffer) }
            // This could probably be try!
            let msg = try MsgTypes_BookmarkNodeList(serializedData: Data(placesRustBuffer: buffer))
            return unpackProtobufItemList(msg: msg)
        }
    }

    /**
     * Returns the URL for the provided search keyword, if one exists.
     *
     * - Parameter keyword: The search keyword.
     * - Returns: The bookmarked URL for the keyword, if set.
     * - Throws:
     *     - `PlacesError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                          object from another thread.
     *     - `PlacesError.connUseAfterAPIClosed`: If the PlacesAPI that returned this connection
     *                                            object has been closed. This indicates API
     *                                            misuse.
     *     - `PlacesError.databaseBusy`: If this query times out with a SQLITE_BUSY error.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    open func getBookmarkURLForKeyword(keyword: String) throws -> String? {
        return try queue.sync {
            try self.checkApi()
            let maybeURL = try PlacesError.tryUnwrap { error in
                bookmarks_get_url_for_keyword(self.handle, keyword, error)
            }
            guard let url = maybeURL else {
                return nil
            }
            return String(freeingPlacesString: url)
        }
    }

    /**
     * Returns the list of bookmarks that match the provided search string.
     *
     * The order of the results is unspecified.
     *
     * - Parameter query: The search query
     * - Parameter limit: The maximum number of items to return.
     * - Returns: A list of bookmarks where either the URL or the title
     *            contain a word (e.g. space separated item) from the
     *            query.
     * - Throws:
     *     - `PlacesError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                          object from another thread.
     *     - `PlacesError.connUseAfterAPIClosed`: If the PlacesAPI that returned this connection
     *                                            object has been closed. This indicates API
     *                                            misuse.
     *     - `PlacesError.databaseBusy`: If this query times out with a SQLITE_BUSY error.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    open func searchBookmarks(query: String, limit: UInt) throws -> [BookmarkItem] {
        return try queue.sync {
            try self.checkApi()
            let buffer = try PlacesError.unwrap { error in
                bookmarks_search(self.handle, query, Int32(limit), error)
            }
            defer { places_destroy_bytebuffer(buffer) }
            // This could probably be try!
            let msg = try MsgTypes_BookmarkNodeList(serializedData: Data(placesRustBuffer: buffer))
            return unpackProtobufItemList(msg: msg)
        }
    }

    /**
     * Returns the list of most recently added bookmarks.
     *
     * The result list be in order of time of addition, descending (more recent
     * additions first), and will contain no folder or separator nodes.
     *
     * - Parameter limit: The maximum number of items to return.
     * - Returns: A list of recently added bookmarks.
     * - Throws:
     *     - `PlacesError.databaseInterrupted`: If a call is made to
     *                                          `interrupt()` on this object
     *                                          from another thread.
     *     - `PlacesError.connUseAfterAPIClosed`: If the PlacesAPI that returned
     *                                            this connection object has
     *                                            been closed. This indicates
     *                                            API misuse.
     *     - `PlacesError.databaseBusy`: If this query times out with a
     *       SQLITE_BUSY error.
     *     - `PlacesError.unexpected`: When an error that has not specifically
     *                                 been exposed to Swift is encountered (for
     *                                 example IO errors from the database code,
     *                                 etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us
     *                            know).
     */
    open func getRecentBookmarks(limit: UInt) throws -> [BookmarkItem] {
        return try queue.sync {
            try self.checkApi()
            let buffer = try PlacesError.unwrap { error in
                bookmarks_get_recent(self.handle, Int32(limit), error)
            }
            defer { places_destroy_bytebuffer(buffer) }
            let msg = try MsgTypes_BookmarkNodeList(serializedData: Data(placesRustBuffer: buffer))
            return unpackProtobufItemList(msg: msg)
        }
    }

    /**
     * Attempt to interrupt a long-running operation which may be
     * happening concurrently. If the operation is interrupted,
     * it will fail.
     *
     * - Note: Not all operations can be interrupted, and no guarantee is
     *         made that a concurrent interrupt call will be respected
     *         (as we may miss it).
     */
    open func interrupt() {
        interruptHandle.interrupt()
    }
}

/**
 * A read-write connection to the places database.
 */
public class PlacesWriteConnection: PlacesReadConnection {
    /**
     * Run periodic database maintenance. This might include, but is
     * not limited to:
     *
     * - `VACUUM`ing.
     * - Requesting that the indices in our tables be optimized.
     * - Periodic repair or deletion of corrupted records.
     * - etc.
     *
     * It should be called at least once a day, but this is merely a
     * recommendation and nothing too dire should happen if it is not
     * called.
     *
     * - Throws:
     *     - `PlacesError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                            object has been closed. This indicates API
     *                                            misuse.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     *
     */
    open func runMaintenance() throws {
        return try queue.sync {
            try self.checkApi()
            try PlacesError.unwrap { error in
                places_run_maintenance(self.handle, error)
            }
        }
    }

    /**
     * Delete the bookmark with the provided GUID.
     *
     * If the requested bookmark is a folder, all children of
     * bookmark are deleted as well, recursively.
     *
     * - Parameter guid: The GUID of the bookmark to delete
     *
     * - Returns: Whether or not the bookmark existed.
     *
     * - Throws:
     *     - `PlacesError.cannotUpdateRoot`: if `guid` is one of the bookmark roots.
     *     - `PlacesError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                            object has been closed. This indicates API
     *                                            misuse.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    @discardableResult
    open func deleteBookmarkNode(guid: String) throws -> Bool {
        return try queue.sync {
            try self.checkApi()
            let resByte = try PlacesError.unwrap { error in
                bookmarks_delete(self.handle, guid, error)
            }
            return resByte != 0
        }
    }

    /**
     * Create a bookmark folder, returning its guid.
     *
     * - Parameter parentGUID: The GUID of the (soon to be) parent of this bookmark.
     *
     * - Parameter title: The title of the folder.
     *
     * - Parameter position: The index where to insert the record inside
     *                       its parent. If not provided, this item will
     *                       be appended.
     *
     * - Returns: The GUID of the newly inserted bookmark folder.
     *
     * - Throws:
     *     - `PlacesError.cannotUpdateRoot`: If `parentGUID` is `BookmarkRoots.RootGUID`.
     *     - `PlacesError.noSuchItem`: If `parentGUID` does not refer to a known bookmark.
     *     - `PlacesError.invalidParent`: If `parentGUID` refers to a bookmark which is
     *                                    not a folder.
     *     - `PlacesError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                            object has been closed. This indicates API
     *                                            misuse.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    @discardableResult
    open func createFolder(parentGUID: String,
                           title: String,
                           position: UInt32? = nil) throws -> String {
        return try queue.sync {
            try self.checkApi()
            var msg = insertionMsg(type: .folder, parentGUID: parentGUID, position: position)
            msg.title = title
            return try doInsert(msg: msg)
        }
    }

    /**
     * Create a bookmark separator, returning its guid.
     *
     * - Parameter parentGUID: The GUID of the (soon to be) parent of this bookmark.
     *
     * - Parameter position: The index where to insert the record inside
     *                       its parent. If not provided, this item will
     *                       be appended.
     *
     * - Returns: The GUID of the newly inserted bookmark separator.
     * - Throws:
     *     - `PlacesError.cannotUpdateRoot`: If `parentGUID` is `BookmarkRoots.RootGUID`.
     *     - `PlacesError.noSuchItem`: If `parentGUID` does not refer to a known bookmark.
     *     - `PlacesError.invalidParent`: If `parentGUID` refers to a bookmark which is
     *                                    not a folder.
     *     - `PlacesError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                            object has been closed. This indicates API
     *                                            misuse.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    @discardableResult
    open func createSeparator(parentGUID: String, position: UInt32? = nil) throws -> String {
        return try queue.sync {
            try self.checkApi()
            let msg = insertionMsg(type: .separator, parentGUID: parentGUID, position: position)
            return try doInsert(msg: msg)
        }
    }

    /**
     * Create a bookmark item, returning its guid.
     *
     * - Parameter parentGUID: The GUID of the (soon to be) parent of this bookmark.
     *
     * - Parameter position: The index where to insert the record inside
     *                       its parent. If not provided, this item will
     *                       be appended.
     *
     * - Parameter url: The URL to bookmark
     *
     * - Parameter title: The title of the new bookmark, if any.
     *
     * - Returns: The GUID of the newly inserted bookmark item.
     *
     * - Throws:
     *     - `PlacesError.urlParseError`: If `url` is not a valid URL.
     *     - `PlacesError.urlTooLong`: If `url` is more than 65536 bytes after
     *                                 punycoding and hex encoding.
     *     - `PlacesError.cannotUpdateRoot`: If `parentGUID` is `BookmarkRoots.RootGUID`.
     *     - `PlacesError.noSuchItem`: If `parentGUID` does not refer to a known bookmark.
     *     - `PlacesError.invalidParent`: If `parentGUID` refers to a bookmark which is
     *                                    not a folder.
     *     - `PlacesError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                            object has been closed. This indicates API
     *                                            misuse.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    @discardableResult
    open func createBookmark(parentGUID: String,
                             url: String,
                             title: String?,
                             position: UInt32? = nil) throws -> String {
        return try queue.sync {
            try self.checkApi()
            var msg = insertionMsg(type: .bookmark, parentGUID: parentGUID, position: position)
            msg.url = url
            if let t = title {
                msg.title = t
            }
            return try doInsert(msg: msg)
        }
    }

    /**
     * Update a bookmark to the provided info.
     *
     * - Parameters:
     *     - guid: Guid of the bookmark to update
     *
     *     - parentGUID: If the record should be moved to another folder, the guid
     *                   of the folder it should be moved to. Interacts with
     *                   `position`, see the note below for details.
     *
     *     - position: If the record should be moved, the 0-based index where it
     *                 should be moved to. Interacts with `parentGUID`, see the note
     *                 below for details
     *
     *     - title: If the record is a `BookmarkNodeType.bookmark` or a `BookmarkNodeType.folder`,
     *              and its title should be changed, then the new value of the title.
     *
     *     - url: If the record is a `BookmarkNodeType.bookmark` node, and its `url`
     *            should be changed, then the new value for the url.
     *
     * - Note: The `parentGUID` and `position` parameters interact with eachother
     *   as follows:
     *
     *     - If `parentGUID` is not provided and `position` is, we treat this
     *       a move within the same folder.
     *
     *     - If `parentGUID` and `position` are both provided, we treat this as
     *       a move to / within that folder, and we insert at the requested
     *       position.
     *
     *     - If `position` is not provided (and `parentGUID` is) then its
     *       treated as a move to the end of that folder.
     * - Throws:
     *     - `PlacesError.illegalChange`: If the change requested is impossible given the
     *                                    type of the item in the DB. For example, on
     *                                    attempts to update the title of a separator.
     *     - `PlacesError.cannotUpdateRoot`: If `guid` is a member of `BookmarkRoots.All`, or
     *                                       `parentGUID` is is `BookmarkRoots.RootGUID`.
     *     - `PlacesError.noSuchItem`: If `guid` or `parentGUID` (if specified) do not refer
     *                                 to known bookmarks.
     *     - `PlacesError.invalidParent`: If `parentGUID` is specified and refers to a bookmark
     *                                    which is not a folder.
     *     - `PlacesError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                            object has been closed. This indicates API
     *                                            misuse.
     *     - `PlacesError.unexpected`: When an error that has not specifically been exposed
     *                                 to Swift is encountered (for example IO errors from
     *                                 the database code, etc).
     *     - `PlacesError.panic`: If the rust code panics while completing this
     *                            operation. (If this occurs, please let us know).
     */
    open func updateBookmarkNode(guid: String,
                                 parentGUID: String? = nil,
                                 position: UInt32? = nil,
                                 title: String? = nil,
                                 url: String? = nil) throws {
        try queue.sync {
            try self.checkApi()
            var msg = MsgTypes_BookmarkNode()
            msg.guid = guid
            if let parent = parentGUID {
                msg.parentGuid = parent
            }
            if let pos = position {
                msg.position = pos
            }
            if let t = title {
                msg.title = t
            }
            if let u = url {
                msg.url = u
            }
            let data = try! msg.serializedData()
            let size = Int32(data.count)
            try data.withUnsafeBytes { bytes in
                try PlacesError.unwrap { error in
                    bookmarks_update(self.handle, bytes.bindMemory(to: UInt8.self).baseAddress!, size, error)
                }
            }
        }
    }

    // Helper for the various creation functions.
    // Note: Caller synchronizes
    private func doInsert(msg: MsgTypes_BookmarkNode) throws -> String {
        // This can only fail if we failed to set the `type` of the msg
        let data = try! msg.serializedData()
        let size = Int32(data.count)
        return try data.withUnsafeBytes { bytes -> String in
            let idStr = try PlacesError.unwrap { error in
                bookmarks_insert(self.handle, bytes.bindMemory(to: UInt8.self).baseAddress!, size, error)
            }
            return String(freeingPlacesString: idStr)
        }
    }

    // Remove the boilerplate common for all insertion messages
    private func insertionMsg(type: BookmarkNodeType,
                              parentGUID: String,
                              position: UInt32?) -> MsgTypes_BookmarkNode {
        var msg = MsgTypes_BookmarkNode()
        msg.nodeType = type.rawValue
        msg.parentGuid = parentGUID
        if let pos = position {
            msg.position = pos
        }
        return msg
    }
}

// Wrapper around rust interrupt handle.
private class InterruptHandle {
    let ptr: OpaquePointer
    init(ptr: OpaquePointer) {
        self.ptr = ptr
    }

    deinit {
        places_interrupt_handle_destroy(self.ptr)
    }

    func interrupt() {
        PlacesError.unwrapOrLog { error in
            places_interrupt(self.ptr, error)
        }
    }
}
