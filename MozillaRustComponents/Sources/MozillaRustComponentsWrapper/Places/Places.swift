/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import os.log

typealias UniffiPlacesApi = PlacesApi
typealias UniffiPlacesConnection = PlacesConnection

/**
 * This is specifically for throwing when there is
 * API misuse and/or connection issues with PlacesReadConnection
 */
public enum PlacesConnectionError: Error {
    case connUseAfterApiClosed
}

/**
 * This is something like a places connection manager. It primarialy exists to
 * ensure that only a single write connection is active at once.
 *
 * If it helps, you can think of this as something like a connection pool
 * (although it does not actually perform any pooling).
 */
public class PlacesAPI {
    private let writeConn: PlacesWriteConnection
    private let api: UniffiPlacesApi

    private let queue = DispatchQueue(label: "com.mozilla.places.api")

    /**
     * Initialize a PlacesAPI
     *
     * - Parameter path: an absolute path to a file that will be used for the internal database.
     *
     * - Throws: `PlacesApiError` if initializing the database failed.
     */
    public init(path: String) throws {
        try api = placesApiNew(dbPath: path)

        let uniffiConn = try api.newConnection(connType: ConnectionType.readWrite)
        writeConn = try PlacesWriteConnection(conn: uniffiConn)

        writeConn.api = self
    }

    /**
     * Open a new reader connection.
     *
     * - Throws: `PlacesApiError` if a connection could not be opened.
     */
    open func openReader() throws -> PlacesReadConnection {
        return try queue.sync {
            let uniffiConn = try api.newConnection(connType: ConnectionType.readOnly)
            return try PlacesReadConnection(conn: uniffiConn, api: self)
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

    open func registerWithSyncManager() {
        queue.sync {
            self.api.registerWithSyncManager()
        }
    }
}

/**
 * A read-only connection to the places database.
 */
public class PlacesReadConnection {
    fileprivate let queue = DispatchQueue(label: "com.mozilla.places.conn")
    fileprivate var conn: UniffiPlacesConnection
    fileprivate weak var api: PlacesAPI?
    private let interruptHandle: SqlInterruptHandle

    fileprivate init(conn: UniffiPlacesConnection, api: PlacesAPI? = nil) throws {
        self.conn = conn
        self.api = api
        interruptHandle = self.conn.newInterruptHandle()
    }

    // Note: caller synchronizes!
    fileprivate func checkApi() throws {
        if api == nil {
            throw PlacesConnectionError.connUseAfterApiClosed
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
     *     - `PlacesApiError.databaseCorrupt`: If corruption is encountered when fetching
     *                                         the tree
     *     - `PlacesApiError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                             object from another thread.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: If the PlacesAPI that returned this connection
     *                                                      object has been closed. This indicates API
     *                                                      misuse.
     *     - `PlacesApiError.databaseBusy`: If this query times out with a SQLITE_BUSY error.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically been exposed
     *                                    to Swift is encountered (for example IO errors from
     *                                    the database code, etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us know).
     */
    open func getBookmarksTree(rootGUID: Guid, recursive: Bool) throws -> BookmarkNodeData? {
        return try queue.sync {
            try self.checkApi()
            if recursive {
                return try self.conn.bookmarksGetTree(itemGuid: rootGUID)?.asBookmarkNodeData
            } else {
                return try self.conn.bookmarksGetByGuid(guid: rootGUID, getDirectChildren: true)?.asBookmarkNodeData
            }
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
     *     - `PlacesApiError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                             object from another thread.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: If the PlacesAPI that returned this connection
     *                                                      object has been closed. This indicates API
     *                                                      misuse.
     *     - `PlacesApiError.databaseBusy`: If this query times out with a SQLITE_BUSY error.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically been exposed
     *                                    to Swift is encountered (for example IO errors from
     *                                    the database code, etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us know).
     */
    open func getBookmark(guid: Guid) throws -> BookmarkNodeData? {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.bookmarksGetByGuid(guid: guid, getDirectChildren: false)?.asBookmarkNodeData
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
     *     - `PlacesApiError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                             object from another thread.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: If the PlacesAPI that returned this connection
     *                                                      object has been closed. This indicates API
     *                                                      misuse.
     *     - `PlacesApiError.databaseBusy`: If this query times out with a SQLITE_BUSY error.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically been exposed
     *                                    to Swift is encountered (for example IO errors from
     *                                    the database code, etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us know).
     */
    open func getBookmarksWithURL(url: Url) throws -> [BookmarkItemData] {
        return try queue.sync {
            try self.checkApi()
            let items = try self.conn.bookmarksGetAllWithUrl(url: url)
            return toBookmarkItemDataList(items: items)
        }
    }

    /**
     * Returns the URL for the provided search keyword, if one exists.
     *
     * - Parameter keyword: The search keyword.
     * - Returns: The bookmarked URL for the keyword, if set.
     * - Throws:
     *     - `PlacesApiError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                             object from another thread.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: If the PlacesAPI that returned this connection
     *                                                      object has been closed. This indicates API
     *                                                      misuse.
     *     - `PlacesApiError.databaseBusy`: If this query times out with a SQLITE_BUSY error.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically been exposed
     *                                    to Swift is encountered (for example IO errors from
     *                                    the database code, etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us know).
     */
    open func getBookmarkURLForKeyword(keyword: String) throws -> Url? {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.bookmarksGetUrlForKeyword(keyword: keyword)
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
     *     - `PlacesApiError.databaseInterrupted`: If a call is made to `interrupt()` on this
     *                                             object from another thread.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: If the PlacesAPI that returned this connection
     *                                                      object has been closed. This indicates API
     *                                                      misuse.
     *     - `PlacesApiError.databaseBusy`: If this query times out with a SQLITE_BUSY error.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically been exposed
     *                                    to Swift is encountered (for example IO errors from
     *                                    the database code, etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us know).
     */
    open func searchBookmarks(query: String, limit: UInt) throws -> [BookmarkItemData] {
        return try queue.sync {
            try self.checkApi()
            let items = try self.conn.bookmarksSearch(query: query, limit: Int32(limit))
            return toBookmarkItemDataList(items: items)
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
     *     - `PlacesApiError.databaseInterrupted`: If a call is made to
     *                                             `interrupt()` on this object
     *                                             from another thread.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: If the PlacesAPI that returned
     *                                                      this connection object has
     *                                                      been closed. This indicates
     *                                                      API misuse.
     *     - `PlacesApiError.databaseBusy`: If this query times out with a
     *                                      SQLITE_BUSY error.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically
     *                                    been exposed to Swift is encountered (for
     *                                    example IO errors from the database code,
     *                                    etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us
     *                               know).
     */
    open func getRecentBookmarks(limit: UInt) throws -> [BookmarkItemData] {
        return try queue.sync {
            try self.checkApi()
            let items = try self.conn.bookmarksGetRecent(limit: Int32(limit))
            return toBookmarkItemDataList(items: items)
        }
    }

    /**
     * Counts the number of bookmark items in the bookmark trees under the specified GUIDs.
     * Empty folders, non-existing GUIDs and non-folder guids will return zero.
     *
     * - Parameter folderGuids: The guids of folders to query.
     * - Returns: Count of all bookmark items (ie, not folders or separators) in all specified folders recursively.
     * - Throws:
     *     - `PlacesApiError.databaseInterrupted`: If a call is made to
     *                                             `interrupt()` on this object
     *                                             from another thread.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: If the PlacesAPI that returned
     *                                                      this connection object has
     *                                                      been closed. This indicates
     *                                                      API misuse.
     *     - `PlacesApiError.databaseBusy`: If this query times out with a
     *                                      SQLITE_BUSY error.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically
     *                                    been exposed to Swift is encountered (for
     *                                    example IO errors from the database code,
     *                                    etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us
     *                               know).
     */
    open func countBookmarksInTrees(folderGuids: [Guid]) throws -> Int {
        return try queue.sync {
            try self.checkApi()
            return try Int(self.conn.bookmarksCountBookmarksInTrees(folderGuids: folderGuids))
        }
    }

    open func getLatestHistoryMetadataForUrl(url: Url) throws -> HistoryMetadata? {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.getLatestHistoryMetadataForUrl(url: url)
        }
    }

    open func getHistoryMetadataSince(since: Int64) throws -> [HistoryMetadata] {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.getHistoryMetadataSince(since: since)
        }
    }

    open func getHistoryMetadataBetween(start: Int64, end: Int64) throws -> [HistoryMetadata] {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.getHistoryMetadataBetween(start: start, end: end)
        }
    }

    open func getHighlights(weights: HistoryHighlightWeights, limit: Int32) throws -> [HistoryHighlight] {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.getHistoryHighlights(weights: weights, limit: limit)
        }
    }

    open func queryHistoryMetadata(query: String, limit: Int32) throws -> [HistoryMetadata] {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.queryHistoryMetadata(query: query, limit: limit)
        }
    }

    // MARK: History Read APIs

    open func matchUrl(query: String) throws -> Url? {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.matchUrl(query: query)
        }
    }

    open func queryAutocomplete(search: String, limit: Int32) throws -> [SearchResult] {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.queryAutocomplete(search: search, limit: limit)
        }
    }

    open func getVisitUrlsInRange(start: PlacesTimestamp, end: PlacesTimestamp, includeRemote: Bool)
        throws -> [Url]
    {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.getVisitedUrlsInRange(start: start, end: end, includeRemote: includeRemote)
        }
    }

    open func getVisitInfos(start: PlacesTimestamp, end: PlacesTimestamp, excludeTypes: VisitTransitionSet)
        throws -> [HistoryVisitInfo]
    {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.getVisitInfos(startDate: start, endDate: end, excludeTypes: excludeTypes)
        }
    }

    open func getVisitCount(excludedTypes: VisitTransitionSet) throws -> Int64 {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.getVisitCount(excludeTypes: excludedTypes)
        }
    }

    open func getVisitPageWithBound(
        bound: Int64,
        offset: Int64,
        count: Int64,
        excludedTypes: VisitTransitionSet
    )
        throws -> HistoryVisitInfosWithBound
    {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.getVisitPageWithBound(
                bound: bound, offset: offset, count: count, excludeTypes: excludedTypes
            )
        }
    }

    open func getVisited(urls: [String]) throws -> [Bool] {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.getVisited(urls: urls)
        }
    }

    open func getTopFrecentSiteInfos(numItems: Int32, thresholdOption: FrecencyThresholdOption)
        throws -> [TopFrecentSiteInfo]
    {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.getTopFrecentSiteInfos(
                numItems: numItems,
                thresholdOption: thresholdOption
            )
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
     * - Deleting older visits when the database exceeds dbSizeLimit
     * - etc.
     *
     * Maintenance in performed in small chunks at a time to avoid blocking the
     * DB connection for too long.  This means that this should be called
     * regularly when the app is idle.
     *
     * - Parameter dbSizeLimit: Maximum DB size to aim for, in bytes.  If the
     *   database exceeds this size, we will prune a small number of visits. For
     *   reference, desktop normally uses 75 MiB (78643200).  If it determines
     *   that either the disk or memory is constrained then it halves the amount.
     *   The default of 0 disables pruning.
     *
     * - Throws:
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                                      object has been closed. This indicates API
     *                                                      misuse.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically been exposed
     *                                    to Swift is encountered (for example IO errors from
     *                                    the database code, etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us know).
     *
     */
    open func runMaintenance(dbSizeLimit: UInt32 = 0) throws {
        return try queue.sync {
            try self.checkApi()
            // The Kotlin code uses a higher pruneLimit, while Swift is extra conservative.  The
            // main reason for this is the v119 places incident.  Once we figure that one out more,
            // let's increase the prune limit here as well.
            _ = try self.conn.runMaintenancePrune(dbSizeLimit: dbSizeLimit, pruneLimit: 6)
            try self.conn.runMaintenanceVacuum()
            try self.conn.runMaintenanceOptimize()
            try self.conn.runMaintenanceCheckpoint()
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
     *     - `PlacesApiError.cannotUpdateRoot`: if `guid` is one of the bookmark roots.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                                      object has been closed. This indicates API
     *                                               misuse.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically been exposed
     *                                    to Swift is encountered (for example IO errors from
     *                                    the database code, etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us know).
     */
    @discardableResult
    open func deleteBookmarkNode(guid: Guid) throws -> Bool {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.bookmarksDelete(id: guid)
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
     *     - `PlacesApiError.cannotUpdateRoot`: If `parentGUID` is `BookmarkRoots.RootGUID`.
     *     - `PlacesApiError.noSuchItem`: If `parentGUID` does not refer to a known bookmark.
     *     - `PlacesApiError.invalidParent`: If `parentGUID` refers to a bookmark which is
     *                                       not a folder.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                                      object has been closed. This indicates API
     *                                                      misuse.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically been exposed
     *                                    to Swift is encountered (for example IO errors from
     *                                    the database code, etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us know).
     */
    @discardableResult
    open func createFolder(parentGUID: Guid,
                           title: String,
                           position: UInt32? = nil) throws -> Guid
    {
        return try queue.sync {
            try self.checkApi()
            let p = position == nil ? BookmarkPosition.append : BookmarkPosition.specific(pos: position ?? 0)
            let f = InsertableBookmarkFolder(parentGuid: parentGUID, position: p, title: title, children: [])
            return try doInsert(item: InsertableBookmarkItem.folder(f: f))
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
     *     - `PlacesApiError.cannotUpdateRoot`: If `parentGUID` is `BookmarkRoots.RootGUID`.
     *     - `PlacesApiError.noSuchItem`: If `parentGUID` does not refer to a known bookmark.
     *     - `PlacesApiError.invalidParent`: If `parentGUID` refers to a bookmark which is
     *                                       not a folder.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                                      object has been closed. This indicates API
     *                                                      misuse.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically been exposed
     *                                    to Swift is encountered (for example IO errors from
     *                                    the database code, etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us know).
     */
    @discardableResult
    open func createSeparator(parentGUID: Guid, position: UInt32? = nil) throws -> Guid {
        return try queue.sync {
            try self.checkApi()
            let p = position == nil ? BookmarkPosition.append : BookmarkPosition.specific(pos: position ?? 0)
            let s = InsertableBookmarkSeparator(parentGuid: parentGUID, position: p)
            return try doInsert(item: InsertableBookmarkItem.separator(s: s))
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
     *     - `PlacesApiError.urlParseError`: If `url` is not a valid URL.
     *     - `PlacesApiError.urlTooLong`: If `url` is more than 65536 bytes after
     *                                    punycoding and hex encoding.
     *     - `PlacesApiError.cannotUpdateRoot`: If `parentGUID` is `BookmarkRoots.RootGUID`.
     *     - `PlacesApiError.noSuchItem`: If `parentGUID` does not refer to a known bookmark.
     *     - `PlacesApiError.invalidParent`: If `parentGUID` refers to a bookmark which is
     *                                       not a folder.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                                      object has been closed. This indicates API
     *                                                      misuse.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically been exposed
     *                                    to Swift is encountered (for example IO errors from
     *                                    the database code, etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us know).
     */
    @discardableResult
    open func createBookmark(parentGUID: String,
                             url: String,
                             title: String?,
                             position: UInt32? = nil) throws -> Guid
    {
        return try queue.sync {
            try self.checkApi()
            let p = position == nil ? BookmarkPosition.append : BookmarkPosition.specific(pos: position ?? 0)
            let bm = InsertableBookmark(parentGuid: parentGUID, position: p, url: url, title: title)
            return try doInsert(item: InsertableBookmarkItem.bookmark(b: bm))
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
     *     - `PlacesApiError.illegalChange`: If the change requested is impossible given the
     *                                       type of the item in the DB. For example, on
     *                                       attempts to update the title of a separator.
     *     - `PlacesApiError.cannotUpdateRoot`: If `guid` is a member of `BookmarkRoots.All`, or
     *                                          `parentGUID` is is `BookmarkRoots.RootGUID`.
     *     - `PlacesApiError.noSuchItem`: If `guid` or `parentGUID` (if specified) do not refer
     *                                    to known bookmarks.
     *     - `PlacesApiError.invalidParent`: If `parentGUID` is specified and refers to a bookmark
     *                                       which is not a folder.
     *     - `PlacesConnectionError.connUseAfterAPIClosed`: if the PlacesAPI that returned this connection
     *                                                      object has been closed. This indicates API
     *                                                      misuse.
     *     - `PlacesApiError.unexpected`: When an error that has not specifically been exposed
     *                                    to Swift is encountered (for example IO errors from
     *                                    the database code, etc).
     *     - `PlacesApiError.panic`: If the rust code panics while completing this
     *                               operation. (If this occurs, please let us know).
     */
    open func updateBookmarkNode(guid: Guid,
                                 parentGUID: Guid? = nil,
                                 position: UInt32? = nil,
                                 title: String? = nil,
                                 url: Url? = nil) throws
    {
        try queue.sync {
            try self.checkApi()
            let data = BookmarkUpdateInfo(
                guid: guid,
                title: title,
                url: url,
                parentGuid: parentGUID,
                position: position
            )
            try self.conn.bookmarksUpdate(data: data)
        }
    }

    // Helper for the various creation functions.
    // Note: Caller synchronizes
    private func doInsert(item: InsertableBookmarkItem) throws -> Guid {
        return try conn.bookmarksInsert(bookmark: item)
    }

    // MARK: History metadata write APIs

    open func noteHistoryMetadataObservation(
        observation: HistoryMetadataObservation,
        _ options: NoteHistoryMetadataObservationOptions = NoteHistoryMetadataObservationOptions()
    ) throws {
        try queue.sync {
            try self.checkApi()
            try self.conn.noteHistoryMetadataObservation(data: observation, options: options)
        }
    }

    // Keeping these three functions inline with what Kotlin (PlacesConnection.kt)
    // to make future work more symmetrical
    open func noteHistoryMetadataObservationViewTime(
        key: HistoryMetadataKey,
        viewTime: Int32?,
        _ options: NoteHistoryMetadataObservationOptions = NoteHistoryMetadataObservationOptions()
    ) throws {
        let obs = HistoryMetadataObservation(
            url: key.url,
            referrerUrl: key.referrerUrl,
            searchTerm: key.searchTerm,
            viewTime: viewTime
        )
        try noteHistoryMetadataObservation(observation: obs, options)
    }

    open func noteHistoryMetadataObservationDocumentType(
        key: HistoryMetadataKey,
        documentType: DocumentType,
        _ options: NoteHistoryMetadataObservationOptions = NoteHistoryMetadataObservationOptions()
    ) throws {
        let obs = HistoryMetadataObservation(
            url: key.url,
            referrerUrl: key.referrerUrl,
            searchTerm: key.searchTerm,
            documentType: documentType
        )
        try noteHistoryMetadataObservation(observation: obs, options)
    }

    open func noteHistoryMetadataObservationTitle(
        key: HistoryMetadataKey,
        title: String,
        _ options: NoteHistoryMetadataObservationOptions = NoteHistoryMetadataObservationOptions()
    ) throws {
        let obs = HistoryMetadataObservation(
            url: key.url,
            referrerUrl: key.referrerUrl,
            searchTerm: key.searchTerm,
            title: title
        )
        try noteHistoryMetadataObservation(observation: obs, options)
    }

    open func deleteHistoryMetadataOlderThan(olderThan: Int64) throws {
        try queue.sync {
            try self.checkApi()
            try self.conn.metadataDeleteOlderThan(olderThan: olderThan)
        }
    }

    open func deleteHistoryMetadata(key: HistoryMetadataKey) throws {
        try queue.sync {
            try self.checkApi()
            try self.conn.metadataDelete(
                url: key.url,
                referrerUrl: key.referrerUrl,
                searchTerm: key.searchTerm
            )
        }
    }

    // MARK: History Write APIs

    open func deleteVisitsFor(url: Url) throws {
        try queue.sync {
            try self.checkApi()
            try self.conn.deleteVisitsFor(url: url)
        }
    }

    open func deleteVisitsBetween(start: PlacesTimestamp, end: PlacesTimestamp) throws {
        try queue.sync {
            try self.checkApi()
            try self.conn.deleteVisitsBetween(start: start, end: end)
        }
    }

    open func deleteVisit(url: Url, timestamp: PlacesTimestamp) throws {
        try queue.sync {
            try self.checkApi()
            try self.conn.deleteVisit(url: url, timestamp: timestamp)
        }
    }

    open func deleteEverythingHistory() throws {
        try queue.sync {
            try self.checkApi()
            try self.conn.deleteEverythingHistory()
        }
    }

    open func acceptResult(searchString: String, url: String) throws {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.acceptResult(searchString: searchString, url: url)
        }
    }

    open func applyObservation(visitObservation: VisitObservation) throws {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.applyObservation(visit: visitObservation)
        }
    }

    open func migrateHistoryFromBrowserDb(path: String, lastSyncTimestamp: Int64) throws -> HistoryMigrationResult {
        return try queue.sync {
            try self.checkApi()
            return try self.conn.placesHistoryImportFromIos(dbPath: path, lastSyncTimestamp: lastSyncTimestamp)
        }
    }
}
