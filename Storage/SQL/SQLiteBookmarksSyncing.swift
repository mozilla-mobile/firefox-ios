/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared
import XCGLogger

private let log = Logger.syncLogger

extension SQLiteBookmarks: LocalItemSource {
    public func getLocalItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        return self.db.getMirrorItemFromTable(TableBookmarksLocal, guid: guid)
    }

    public func getLocalItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        return self.db.getMirrorItemsFromTable(TableBookmarksLocal, guids: guids)
    }

    public func prefetchLocalItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        log.debug("Not implemented for SQLiteBookmarks.")
        return succeed()
    }
}

extension SQLiteBookmarks: MirrorItemSource {
    public func getMirrorItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        return self.db.getMirrorItemFromTable(TableBookmarksMirror, guid: guid)
    }

    public func getMirrorItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        return self.db.getMirrorItemsFromTable(TableBookmarksMirror, guids: guids)
    }

    public func prefetchMirrorItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        log.debug("Not implemented for SQLiteBookmarks.")
        return succeed()
    }
}

extension SQLiteBookmarks {
    func getSQLToOverrideFolder(_ folder: GUID, atModifiedTime modified: Timestamp) -> (sql: [String], args: Args) {
        return self.getSQLToOverrideFolders([folder], atModifiedTime: modified)
    }

    func getSQLToOverrideFolders(_ folders: [GUID], atModifiedTime modified: Timestamp) -> (sql: [String], args: Args) {
        if folders.isEmpty {
            return (sql: [], args: [])
        }

        let vars = BrowserDB.varlist(folders.count)
        let args: Args = folders

        // Copy it to the local table.
        // Most of these will be NULL, because we're only dealing with folders,
        // and typically only the Mobile Bookmarks root.
        let overrideSQL = "INSERT OR IGNORE INTO \(TableBookmarksLocal) " +
                          "(guid, type, date_added, bmkUri, title, parentid, parentName, feedUri, siteUri, pos," +
                          " description, tags, keyword, folderName, queryId, is_deleted, " +
                          " local_modified, sync_status, faviconID) " +
                          "SELECT guid, type, date_added, bmkUri, title, parentid, parentName, " +
                          "feedUri, siteUri, pos, description, tags, keyword, folderName, queryId, " +
                          "is_deleted, " +
                          "\(modified) AS local_modified, \(SyncStatus.changed.rawValue) AS sync_status, faviconID " +
                          "FROM \(TableBookmarksMirror) WHERE guid IN \(vars)"

        // Copy its mirror structure.
        let dropSQL = "DELETE FROM \(TableBookmarksLocalStructure) WHERE parent IN \(vars)"
        let copySQL = "INSERT INTO \(TableBookmarksLocalStructure) " +
                      "SELECT * FROM \(TableBookmarksMirrorStructure) WHERE parent IN \(vars)"

        // Mark as overridden.
        let markSQL = "UPDATE \(TableBookmarksMirror) SET is_overridden = 1 WHERE guid IN \(vars)"
        return (sql: [overrideSQL, dropSQL, copySQL, markSQL], args: args)
    }

    func getSQLToOverrideNonFolders(_ records: [GUID], atModifiedTime modified: Timestamp) -> (sql: [String], args: Args) {
        log.info("Getting SQL to override \(records).")
        if records.isEmpty {
            return (sql: [], args: [])
        }

        let vars = BrowserDB.varlist(records.count)
        let args: Args = records.map { $0 }

        // Copy any that aren't overridden to the local table.
        let overrideSQL =
        "INSERT OR IGNORE INTO \(TableBookmarksLocal) " +
        "(guid, type, date_added, bmkUri, title, parentid, parentName, feedUri, siteUri, pos," +
        " description, tags, keyword, folderName, queryId, is_deleted, " +
        " local_modified, sync_status, faviconID) " +
        "SELECT guid, type, date_added, bmkUri, title, parentid, parentName, " +
        "feedUri, siteUri, pos, description, tags, keyword, folderName, queryId, " +
        "is_deleted, " +
        "\(modified) AS local_modified, \(SyncStatus.changed.rawValue) AS sync_status, faviconID " +
        "FROM \(TableBookmarksMirror) WHERE guid IN \(vars) AND is_overridden = 0"

        // Mark as overridden.
        let markSQL = "UPDATE \(TableBookmarksMirror) SET is_overridden = 1 WHERE guid IN \(vars)"
        return (sql: [overrideSQL, markSQL], args: args)
    }

    /**
     * Insert a bookmark into the specified folder.
     * If the folder doesn't exist, or is deleted, insertion will fail.
     *
     * Preconditions:
     * * `deferred` has not been filled.
     * * this function is called inside a transaction that hasn't been finished.
     *
     * Postconditions:
     * * `deferred` has been filled with success or failure.
     * * the transaction will include any status/overlay changes necessary to save the bookmark.
     * * the return value determines whether the transaction should be committed, and
     *   matches the success-ness of the Deferred.
     *
     * Sorry about the long line. If we break it, the indenting below gets crazy.
     */
    fileprivate func insertBookmarkInTransaction(url: URL, title: String, favicon: Favicon?, intoFolder parent: GUID, withTitle parentTitle: String, conn: SQLiteDBConnection) throws {

        log.debug("Inserting bookmark in transaction on thread \(Thread.current)")

        // Keep going if this does not throw.
        func change(_ sql: String, args: Args?, desc: String) throws {
            try conn.executeChange(sql, withArgs: args)
        }

        let urlString = url.absoluteString
        let newGUID = Bytes.generateGUID()
        let now = Date.now()
        let parentArgs: Args = [parent]

        //// Insert the new bookmark and icon without touching structure.
        var args: Args = [
            newGUID,
            BookmarkNodeType.bookmark.rawValue,
            now,
            urlString,
            title,
            parent,
            parentTitle,
            Date.nowNumber(),
            SyncStatus.new.rawValue,
        ]

        let faviconID: Int?

        // Insert the favicon.
        if let icon = favicon {
            faviconID = self.favicons.insertOrUpdateFaviconInTransaction(icon, conn: conn)
        } else {
            faviconID = nil
        }

        log.debug("Inserting bookmark with GUID \(newGUID) and specified icon \(faviconID ??? "nil").")

        // If the caller didn't provide an icon (and they usually don't!),
        // do a reverse lookup in history. We use a view to make this simple.
        let iconValue: String
        if let faviconID = faviconID {
            iconValue = "?"
            args.append(faviconID  )
        } else {
            iconValue = "(SELECT iconID FROM \(ViewIconForURL) WHERE url = ?)"
            args.append(urlString  )
        }

        let insertSQL = "INSERT INTO \(TableBookmarksLocal) " +
                        "(guid, type, date_added, bmkUri, title, parentid, parentName, local_modified, sync_status, faviconID) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, \(iconValue))"
        try change(insertSQL, args: args, desc: "Error inserting \(newGUID).")

        func bumpParentStatus(_ status: Int) throws {
            let bumpSQL = "UPDATE \(TableBookmarksLocal) SET sync_status = \(status), local_modified = \(now) WHERE guid = ?"
            try change(bumpSQL, args: parentArgs, desc: "Error bumping \(parent)'s modified time.")
        }

        func overrideParentMirror() throws {
            // We do this slightly tortured work so that we can reuse these queries
            // in a different context.
            let (sql, args) = getSQLToOverrideFolder(parent, atModifiedTime: now)
            var generator = sql.makeIterator()
            while let query = generator.next() {
                try change(query, args: args, desc: "Error running overriding query.")
            }
        }

        //// Make sure our parent is overridden and appropriately bumped.
        // See discussion here: <https://github.com/mozilla/firefox-ios/commit/2041f1bbde430de29aefb803aae54ed26db47d23#commitcomment-14572312>
        // Note that this isn't as obvious as you might think. We must:
        let localStatusFactory: (SDRow) -> (Int, Bool) = { row in
            let status = row["sync_status"] as! Int
            let deleted = (row["is_deleted"] as! Int) != 0
            return (status, deleted)
        }

        let overriddenFactory: (SDRow) -> Bool = { row in
            row.getBoolean("is_overridden")
        }

        // TODO: these can be merged into a single query.
        let mirrorStatusSQL = "SELECT is_overridden FROM \(TableBookmarksMirror) WHERE guid = ?"
        let localStatusSQL = "SELECT sync_status, is_deleted FROM \(TableBookmarksLocal) WHERE guid = ?"
        let mirrorStatus = conn.executeQuery(mirrorStatusSQL, factory: overriddenFactory, withArgs: parentArgs)[0]
        let localStatus = conn.executeQuery(localStatusSQL, factory: localStatusFactory, withArgs: parentArgs)[0]

        let parentExistsInMirror = mirrorStatus != nil
        let parentExistsLocally = localStatus != nil

        // * Figure out if we were already overridden. We only want to re-clone
        //   if we weren't.
        if !parentExistsLocally {
            if !parentExistsInMirror {
                throw DatabaseError(description: "Folder \(parent) doesn't exist in either mirror or local.")
            }
            // * Mark the parent folder as overridden if necessary.
            //   Overriding the parent involves copying the parent's structure, so that
            //   we can amend it, but also the parent's row itself so that we know it's
            //   changed.
            try overrideParentMirror()
        } else {
            let (status, deleted) = localStatus!
            if deleted {
                throw DatabaseError(description: "Local folder \(parent) is deleted.")
            }

            // * Bump the overridden parent's modified time. We already copied its
            //   structure and values, and if it's in the local table it'll either
            //   already be New or Changed.

            if let syncStatus = SyncStatus(rawValue: status) {
                switch syncStatus {
                case .synced:
                    log.debug("We don't expect folders to ever be marked as Synced.")
                    try bumpParentStatus(SyncStatus.changed.rawValue)
                case .new:
                    fallthrough
                case .changed:
                    // Leave it marked as new or changed, but bump the timestamp.
                    try bumpParentStatus(syncStatus.rawValue)
                }
            } else {
                log.warning("Local folder marked with unknown state \(status). This should never occur.")
                try bumpParentStatus(SyncStatus.changed.rawValue)
            }
        }

        /// Add the new bookmark as a child in the modified local structure.
        // We always append the new row: after insertion, the new item will have the largest index.
        let newIndex = "(SELECT (COALESCE(MAX(idx), -1) + 1) AS newIndex FROM \(TableBookmarksLocalStructure) WHERE parent = ?)"
        let structureSQL = "INSERT INTO \(TableBookmarksLocalStructure) (parent, child, idx) " +
                           "VALUES (?, ?, \(newIndex))"
        let structureArgs: Args = [parent, newGUID, parent]

        try change(structureSQL, args: structureArgs, desc: "Error adding new item \(newGUID) to local structure.")
    }

    /**
     * Assumption: the provided folder GUID exists in either the local table or the mirror table.
     */
    func insertBookmark(_ url: URL, title: String, favicon: Favicon?, intoFolder parent: GUID, withTitle parentTitle: String) -> Success {
        log.debug("Inserting bookmark task on thread \(Thread.current)")
        return db.transaction { conn -> Void in
            try self.insertBookmarkInTransaction(url: url, title: title, favicon: favicon, intoFolder: parent, withTitle: parentTitle, conn: conn)
        }
    }
}

private extension BookmarkMirrorItem {
    // Let's say the buffer structure table looks like this:
    // ===============================
    // | parent    | child     | idx |
    // -------------------------------
    // | aaaa      | bbbb      | 5   |
    // | aaaa      | cccc      | 8   |
    // | aaaa      | dddd      | 19  |
    // ===============================
    // And the self.children array has 5 children (2 new to insert).
    // Then this function should be called with offset = 3 and nextIdx = 20
    func getChildrenArgs(offset: Int = 0, nextIdx: Int = 0) -> [Args] {
        // Only folders have children, and we manage roots ourselves.
        if self.type != .folder ||
           self.guid == BookmarkRoots.RootGUID {
            return []
        }
        let parent = self.guid
        var idx = nextIdx
        return self.children?.suffix(from: offset).map { child in
            let ret: Args = [parent, child, idx]
            idx += 1
            return ret
        } ?? []
    }

    func getUpdateOrInsertArgs() -> Args {
        let args: Args = [
            self.type.rawValue   ,
            self.dateAdded,
            self.serverModified,
            self.isDeleted ? 1 : 0   ,
            self.hasDupe ? 1 : 0,
            self.parentID,
            self.parentName ?? "",     // Workaround for dirty data before Bug 1318414.
            self.feedURI,
            self.siteURI,
            self.pos,
            self.title,
            self.description,
            self.bookmarkURI,
            self.tags,
            self.keyword,
            self.folderName,
            self.queryID,
            self.guid,
        ]

        return args
    }
}

private func deleteStructureForGUIDs(_ guids: [GUID], fromTable table: String, connection: SQLiteDBConnection, withMaxVars maxVars: Int=BrowserDB.MaxVariableNumber) throws {
    log.debug("Deleting \(guids.count) parents from \(table).")
    let chunks = chunk(guids, by: maxVars)
    for chunk in chunks {
        let delStructure = "DELETE FROM \(table) WHERE parent IN \(BrowserDB.varlist(chunk.count))"

        let args: Args = chunk.flatMap { $0 }
        try connection.executeChange(delStructure, withArgs: args)
    }
}

private func insertStructureIntoTable(_ table: String, connection: SQLiteDBConnection, children: [Args], maxVars: Int) throws {
    if children.isEmpty {
        return
    }

    // Insert the new structure rows. This uses three vars per row.
    let maxRowsPerInsert: Int = maxVars / 3
    let chunks = chunk(children, by: maxRowsPerInsert)
    for chunk in chunks {
        log.verbose("Inserting \(chunk.count)…")
        let childArgs: Args = chunk.flatMap { $0 }   // Flatten [[a, b, c], [...]] into [a, b, c, ...].
        let ins = "INSERT INTO \(table) (parent, child, idx) VALUES " +
            Array<String>(repeating: "(?, ?, ?)", count: chunk.count).joined(separator: ", ")
        log.debug("Inserting \(chunk.count) records (out of \(children.count)).")
        try connection.executeChange(ins, withArgs: childArgs)
    }
}

/**
 * This stores incoming records in a buffer.
 * When appropriate, the buffer is merged with the mirror and local storage
 * in the DB.
 */
open class SQLiteBookmarkBufferStorage: BookmarkBufferStorage {
    let db: BrowserDB

    public init(db: BrowserDB) {
        self.db = db
    }

    open func synchronousBufferCount() -> Int? {
        return self.db.runQuery("SELECT COUNT(*) FROM \(TableBookmarksBuffer)", args: nil, factory: IntFactory).value.successValue?[0]
    }

    public func getUpstreamRecordCount() -> Deferred<Int?> {
        let sql =
        "SELECT (SELECT COUNT(*) FROM \(TableBookmarksBuffer)) + " +
        "(SELECT COUNT(*) FROM \(TableBookmarksMirror) WHERE is_overridden = 0) " +
        "AS c"

        return self.db.runQuery(sql, args: nil, factory: IntFactory).bind { result in
            return Deferred(value: result.successValue?[0]!)
        }
    }

    /**
     * Remove child records for any folders that've been deleted or are empty.
     */
    fileprivate func deleteChildrenInTransactionWithGUIDs(_ guids: [GUID], connection: SQLiteDBConnection, withMaxVars maxVars: Int=BrowserDB.MaxVariableNumber) throws {
        try deleteStructureForGUIDs(guids, fromTable: TableBookmarksBufferStructure, connection: connection, withMaxVars: maxVars)
    }

    open func isEmpty() -> Deferred<Maybe<Bool>> {
        return self.db.queryReturnsNoResults("SELECT 1 FROM \(TableBookmarksBuffer)")
    }

    /**
     * This is a little gnarly because our DB access layer is rough.
     * Within a single transaction, we walk the list of items, attempting to update
     * and inserting if the update failed. (TODO: batch the inserts!)
     * Once we've added all of the records, we flatten all of their children
     * into big arg lists and hard-update the structure table.
     */
    open func applyRecords(_ records: [BookmarkMirrorItem]) -> Success {
        return self.applyRecords(records, withMaxVars: BrowserDB.MaxVariableNumber)
    }

    open func applyRecords(_ records: [BookmarkMirrorItem], withMaxVars maxVars: Int) -> Success {
        let guids = records.map { $0.guid }
        let deleted = records.filter { $0.isDeleted }.map { $0.guid }
        let values = records.map { $0.getUpdateOrInsertArgs() }
        let children = records.filter { !$0.isDeleted }.flatMap { $0.getChildrenArgs() }
        let folders = records.filter { $0.type == BookmarkNodeType.folder }.map { $0.guid }

        return db.transaction { conn -> Void in
            // These have the same values in the same order.
            let update =
            "UPDATE \(TableBookmarksBuffer) SET " +
            "type = ?, date_added = ?, server_modified = ?, is_deleted = ?, " +
            "hasDupe = ?, parentid = ?, parentName = ?, " +
            "feedUri = ?, siteUri = ?, pos = ?, title = ?, " +
            "description = ?, bmkUri = ?, tags = ?, keyword = ?, " +
            "folderName = ?, queryId = ? " +
            "WHERE guid = ?"

            // We used to use INSERT OR IGNORE here, but it muffles legitimate errors. The only
            // real use for that is/was to catch duplicates, but the UPDATE we run first should
            // serve that purpose just as well.
            let insert =
            "INSERT INTO \(TableBookmarksBuffer) " +
            "(type, date_added, server_modified, is_deleted, hasDupe, parentid, parentName, " +
             "feedUri, siteUri, pos, title, description, bmkUri, tags, keyword, folderName, queryId, guid) " +
            "VALUES " +
            "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

            for args in values {
                try conn.executeChange(update, withArgs: args)

                if conn.numberOfRowsModified > 0 {
                    continue
                }

                try conn.executeChange(insert, withArgs: args)
            }

            // Delete existing structure for any folders we've seen. We always trust the folders,
            // not the children's parent pointers, so we do this here: we'll insert their current
            // children right after, when we process the child structure rows.
            // We only drop the child structure for deleted folders, not the record itself.
            // Deleted records stay in the buffer table so that we know about the deletion
            // when we do a real sync!

            log.debug("\(folders.count) folders and \(deleted.count) deleted maybe-folders to drop from buffer structure table.")

            try self.deleteChildrenInTransactionWithGUIDs(folders + deleted, connection: conn)

            // (Re-)insert children in chunks.
            log.debug("Inserting \(children.count) children.")
            try insertStructureIntoTable(TableBookmarksBufferStructure, connection: conn, children: children, maxVars: maxVars)

            // Drop pending deletions of items we just received.
            // In practice that means we have made the choice that we will always
            // discard local deletions if there was a modification or a deletion made remotely.
            log.debug("Deleting \(guids.count) pending deletions.")
            let chunks = chunk(guids, by: BrowserDB.MaxVariableNumber)
            for chunk in chunks {
                let delPendingDeletions = "DELETE FROM \(TablePendingBookmarksDeletions) WHERE id IN \(BrowserDB.varlist(chunk.count))"

                let args: Args = chunk.flatMap { $0 }
                try conn.executeChange(delPendingDeletions, withArgs: args)
            }
        }
    }

    open func doneApplyingRecordsAfterDownload() -> Success {
        self.db.checkpoint()
        return succeed()
    }
}

extension SQLiteBookmarkBufferStorage: BufferItemSource {
    public func getBufferItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        return self.db.getMirrorItemFromTable(TableBookmarksBuffer, guid: guid)
    }

    public func getBufferItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        return self.db.getMirrorItemsFromTable(TableBookmarksBuffer, guids: guids)
    }

    public func getBufferChildrenGUIDsForParent(_ guid: GUID) -> Deferred<Maybe<[GUID]>> {
        return self.getChildrenGUIDsOf(guid)
    }

    public func prefetchBufferItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        log.debug("Not implemented.")
        return succeed()
    }
}

extension BrowserDB {
    fileprivate func getMirrorItemFromTable(_ table: String, guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        let args: Args = [guid]
        let sql = "SELECT * FROM \(table) WHERE guid = ?"
        return self.runQuery(sql, args: args, factory: BookmarkFactory.mirrorItemFactory)
          >>== { cursor in
                guard let item = cursor[0] else {
                    return deferMaybe(DatabaseError(description: "Expected to find \(guid) in \(table) but did not."))
                }
                return deferMaybe(item)
        }
    }

    fileprivate func getMirrorItemsFromTable<T: Collection>(_ table: String, guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        var acc: [GUID: BookmarkMirrorItem] = [:]
        func accumulate(_ args: Args) -> Success {
            let sql = "SELECT * FROM \(table) WHERE guid IN \(BrowserDB.varlist(args.count))"
            return self.runQuery(sql, args: args, factory: BookmarkFactory.mirrorItemFactory)
              >>== { cursor in
                cursor.forEach { row in
                    guard let row = row else { return }    // Oh, Cursor.
                    acc[row.guid] = row
                }
                return succeed()
            }
        }

        let args: Args = guids.map { $0 }
        if args.count < BrowserDB.MaxVariableNumber {
            return accumulate(args) >>> { deferMaybe(acc) }
        }

        let chunks = chunk(args, by: BrowserDB.MaxVariableNumber)
        return walk(chunks.lazy.map { Array($0) }, f: accumulate)
           >>> { deferMaybe(acc) }
    }
}

extension MergedSQLiteBookmarks: BookmarkBufferStorage {
    public func synchronousBufferCount() -> Int? {
        return self.buffer.synchronousBufferCount()
    }

    public func getUpstreamRecordCount() -> Deferred<Int?> {
        return self.buffer.getUpstreamRecordCount()
    }

    public func isEmpty() -> Deferred<Maybe<Bool>> {
        return self.buffer.isEmpty()
    }

    public func applyRecords(_ records: [BookmarkMirrorItem]) -> Success {
        return self.buffer.applyRecords(records)
    }

    public func doneApplyingRecordsAfterDownload() -> Success {
        // It doesn't really matter which one we checkpoint -- they're both backed by the same DB.
        return self.buffer.doneApplyingRecordsAfterDownload()
    }

    public func validate() -> Success {
        return self.buffer.validate()
    }

    public func getBufferedDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>> {
        return self.buffer.getBufferedDeletions()
    }

    public func applyBufferCompletionOp(_ op: BufferCompletionOp, itemSources: ItemSources) -> Success {
        return self.buffer.applyBufferCompletionOp(op, itemSources: itemSources)
    }
}

extension MergedSQLiteBookmarks: BufferItemSource {
    public func getBufferItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        return self.buffer.getBufferItemWithGUID(guid)
    }

    public func getBufferItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        return self.buffer.getBufferItemsWithGUIDs(guids)
    }

    public func getBufferChildrenGUIDsForParent(_ guid: GUID) -> Deferred<Maybe<[GUID]>> {
        return self.buffer.getChildrenGUIDsOf(guid)
    }

    public func prefetchBufferItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        return self.buffer.prefetchBufferItemsWithGUIDs(guids)
    }
}

extension MergedSQLiteBookmarks: MirrorItemSource {
    public func getMirrorItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        return self.local.getMirrorItemWithGUID(guid)
    }

    public func getMirrorItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        return self.local.getMirrorItemsWithGUIDs(guids)
    }

    public func prefetchMirrorItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        return self.local.prefetchMirrorItemsWithGUIDs(guids)
    }
}

extension MergedSQLiteBookmarks: LocalItemSource {
    public func getLocalItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        return self.local.getLocalItemWithGUID(guid)
    }

    public func getLocalItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        return self.local.getLocalItemsWithGUIDs(guids)
    }

    public func prefetchLocalItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        return self.local.prefetchLocalItemsWithGUIDs(guids)
    }
}

extension MergedSQLiteBookmarks: ShareToDestination {
    public func shareItem(_ item: ShareItem) -> Success {
        return self.local.shareItem(item)
    }
}

// Not actually implementing SyncableBookmarks, just a utility for MergedSQLiteBookmarks to do so.
extension SQLiteBookmarks {
    public func isUnchanged() -> Deferred<Maybe<Bool>> {
        return self.db.queryReturnsNoResults("SELECT 1 FROM \(TableBookmarksLocal)")
    }

    // Retrieve all the local bookmarks that are not present remotely in order to avoid merge logic later.
    public func getLocalBookmarksModifications(limit: Int) -> Deferred<Maybe<(deletions: [GUID], additions: [BookmarkMirrorItem])>> {
        let deletionsQuery =
        "SELECT id FROM \(TablePendingBookmarksDeletions) " +
        "LIMIT ?"
        let deletionsArgs: Args = [limit]

        return db.runQuery(deletionsQuery, args: deletionsArgs, factory: StringFactory) >>== {
            let deletedGUIDs = $0.asArray()
            let newLimit = limit - deletedGUIDs.count

            let additionsQuery =
            "SELECT * FROM \(TableBookmarksLocal) AS bookmarks " +
            "WHERE type = \(BookmarkNodeType.bookmark.rawValue) AND sync_status = \(SyncStatus.new.rawValue) AND parentID = ? " +
            "AND NOT EXISTS (SELECT 1 FROM \(TableBookmarksBuffer) buf WHERE buf.guid = bookmarks.guid) " +
            "LIMIT ?"
            let additionsArgs: Args = [BookmarkRoots.MobileFolderGUID, newLimit]

            return self.db.runQuery(additionsQuery, args: additionsArgs, factory: BookmarkFactory.mirrorItemFactory) >>== {
                return deferMaybe((deletedGUIDs, $0.asArray()))
            }
        }
    }

    public func getLocalDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>> {
        let sql =
        "SELECT guid, local_modified FROM \(TableBookmarksLocal) " +
        "WHERE is_deleted = 1"

        return self.db.runQuery(sql, args: nil, factory: { ($0["guid"] as! GUID, $0.getTimestamp("local_modified")!) })
          >>== { deferMaybe($0.asArray()) }
    }
}

extension MergedSQLiteBookmarks: SyncableBookmarks {
    public func isUnchanged() -> Deferred<Maybe<Bool>> {
        return self.local.isUnchanged()
    }

    public func getLocalBookmarksModifications(limit: Int) -> Deferred<Maybe<(deletions: [GUID], additions: [BookmarkMirrorItem])>> {
        return self.local.getLocalBookmarksModifications(limit: limit)
    }

    public func getLocalDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>> {
        return self.local.getLocalDeletions()
    }

    public func treeForMirror() -> Deferred<Maybe<BookmarkTree>> {
        return self.local.treeForMirror()
    }

    public func treesForEdges() -> Deferred<Maybe<(local: BookmarkTree, buffer: BookmarkTree)>> {
        return self.local.treeForLocal() >>== { local in
            return self.local.treeForBuffer() >>== { buffer in
                return deferMaybe((local: local, buffer: buffer))
            }
        }
    }
}

// MARK: - Validation of buffer contents.

// Note that these queries tend to not have exceptions for deletions.
// That's because a record can't be deleted in isolation -- if it's
// deleted its parent should be changed, too -- and so our views will
// correctly reflect that. We'll have updated rows in the structure table,
// and updated values -- and thus a complete override -- for the parent and
// the deleted child.
private let allBufferStructuresReferToRecords = [
"SELECT s.child AS pointee, s.parent AS pointer FROM",
ViewBookmarksBufferStructureOnMirror,
"s LEFT JOIN",
ViewBookmarksBufferOnMirror,
"b ON b.guid = s.child WHERE b.guid IS NULL",
].joined(separator: " ")

private let allNonDeletedBufferRecordsAreInStructure = [
"SELECT b.guid AS missing, b.parentid AS parent FROM",
ViewBookmarksBufferOnMirror, "b LEFT JOIN",
ViewBookmarksBufferStructureOnMirror,
"s ON b.guid = s.child WHERE s.child IS NULL AND",
"b.is_deleted IS 0 AND b.parentid IS NOT '\(BookmarkRoots.RootGUID)'",
].joined(separator: " ")

private let allRecordsAreChildrenOnce = [
"SELECT s.child FROM",
ViewBookmarksBufferStructureOnMirror,
"s INNER JOIN (",
"SELECT child, COUNT(*) AS dupes FROM", ViewBookmarksBufferStructureOnMirror,
"GROUP BY child HAVING dupes > 1",
") i ON s.child = i.child",
].joined(separator: " ")

private let bufferParentidMatchesStructure = [
"SELECT b.guid, b.parentid, s.parent, s.child, s.idx FROM",
TableBookmarksBuffer, "b JOIN", TableBookmarksBufferStructure,
"s ON b.guid = s.child WHERE b.is_deleted IS 0 AND b.parentid IS NOT s.parent",
].joined(separator: " ")

public enum BufferInconsistency {
    case missingValues
    case missingStructure
    case overlappingStructure
    case parentIDDisagreement

    public var query: String {
        switch self {
        case .missingValues:
            return allBufferStructuresReferToRecords
        case .missingStructure:
            return allNonDeletedBufferRecordsAreInStructure
        case .overlappingStructure:
            return allRecordsAreChildrenOnce
        case .parentIDDisagreement:
            return bufferParentidMatchesStructure
        }
    }

    public var trackingEvent: String {
        switch self {
        case .missingValues:
            return "missingvalues"
        case .missingStructure:
            return "missingstructure"
        case .overlappingStructure:
            return "overlappingstructure"
        case .parentIDDisagreement:
            return "parentiddisagreement"
        }
    }

    public var description: String {
        switch self {
        case .missingValues:
            return "Not all buffer structures refer to records."
        case .missingStructure:
            return "Not all buffer records are in structure."
        case .overlappingStructure:
            return "Some buffer structures refer to the same records."
        case .parentIDDisagreement:
            return "Some buffer record parent IDs don't match structure."
        }
    }

    var idsFactory: (SDRow) -> [String] {
        switch self {
        case .missingValues:
            return self.getConcernedIDs(colNames: ["pointee", "pointer"])
        case .missingStructure:
            return self.getConcernedIDs(colNames: ["missing", "parent"])
        case .overlappingStructure:
            return self.getConcernedIDs(colNames: ["child"])
        case .parentIDDisagreement:
            return self.getConcernedIDs(colNames: ["guid", "parentid", "parent", "child"])
        }
    }

    private func getConcernedIDs(colNames: [String]) -> ((SDRow) -> [String]) {
        return { (row: SDRow) in
             colNames.flatMap({ row[$0] as? String})
        }
    }

    public static let all: [BufferInconsistency] = [.missingValues, .missingStructure, .overlappingStructure, .parentIDDisagreement]
}

public struct BufferInvalidError: MaybeErrorType {
    public let description = "Bookmarks buffer contains invalid data"
    public let inconsistencies: [BufferInconsistency: [GUID]]
    public let validationDuration: Int64

    public init(inconsistencies: [BufferInconsistency: [GUID]], validationDuration: Int64) {
        self.inconsistencies = inconsistencies
        self.validationDuration = validationDuration
    }
}

extension SQLiteBookmarkBufferStorage {
    public func validate() -> Success {
        func idsFor(inconsistency inc: BufferInconsistency) -> () -> Deferred<Maybe<(type: BufferInconsistency, ids: [String])>> {
            return {
                self.db.runQuery(inc.query, args: nil, factory: inc.idsFactory)
                    >>== { deferMaybe((type: inc, ids: $0.asArray().reduce([], +))) }
            }
        }

        let start = Date.now()
        let ops = BufferInconsistency.all.map { idsFor(inconsistency: $0) }
        return accumulate(ops) >>== { results in
            var inconsistencies = [BufferInconsistency: [GUID]]()
            results.forEach { type, ids in
                guard !ids.isEmpty else { return }
                inconsistencies[type] = ids
            }

            return inconsistencies.isEmpty ? succeed() :
                deferMaybe(BufferInvalidError(inconsistencies: inconsistencies, validationDuration: Int64(Date.now() - start)))
        }
    }

    public func getBufferedDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>> {
        let sql =
        "SELECT guid, server_modified FROM \(TableBookmarksBuffer) " +
        "WHERE is_deleted = 1"

        return self.db.runQuery(sql, args: nil, factory: { ($0["guid"] as! GUID, $0.getTimestamp("server_modified")!) })
          >>== { deferMaybe($0.asArray()) }
    }
}

extension SQLiteBookmarks {
    fileprivate func structureQueryForTable(_ table: String, structure: String) -> String {
        // We use a subquery so we get back rows for overridden folders, even when their
        // children aren't in the shadowing table.
        let sql =
        "SELECT s.parent AS parent, s.child AS child, COALESCE(m.type, -1) AS type " +
        "FROM \(structure) s LEFT JOIN \(table) m ON s.child = m.guid AND m.is_deleted IS NOT 1 " +
        "ORDER BY s.parent, s.idx ASC"
        return sql
    }

    fileprivate func remainderQueryForTable(_ table: String, structure: String) -> String {
        // This gives us value rows that aren't children of a folder.
        // You might notice that these complementary LEFT JOINs are how you
        // express a FULL OUTER JOIN in sqlite.
        // We exclude folders here because if they have children, they'll appear
        // in the structure query, and if they don't, they'll appear in the bottom
        // half of this query.
        let sql =
        "SELECT m.guid AS guid, m.type AS type " +
        "FROM \(table) m LEFT JOIN \(structure) s ON s.child = m.guid " +
        "WHERE m.is_deleted IS NOT 1 AND m.type IS NOT \(BookmarkNodeType.folder.rawValue) AND s.child IS NULL " +

        "UNION ALL " +

        // This gives us folders with no children.
        "SELECT m.guid AS guid, m.type AS type " +
        "FROM \(table) m LEFT JOIN \(structure) s ON s.parent = m.guid " +
        "WHERE m.is_deleted IS NOT 1 AND m.type IS \(BookmarkNodeType.folder.rawValue) AND s.parent IS NULL "

        return sql
    }

    fileprivate func statusQueryForTable(_ table: String) -> String {
        return "SELECT guid, is_deleted FROM \(table)"
    }

    fileprivate func treeForTable(_ table: String, structure: String, alwaysIncludeRoots includeRoots: Bool) -> Deferred<Maybe<BookmarkTree>> {
        // The structure query doesn't give us non-structural rows -- that is, if you
        // make a value-only change to a record, and it's not otherwise mentioned by
        // way of being a child of a structurally modified folder, it won't appear here at all.
        // It also doesn't give us empty folders, because they have no children.
        // We run a separate query to get those.
        let structureSQL = self.structureQueryForTable(table, structure: structure)
        let remainderSQL = self.remainderQueryForTable(table, structure: structure)
        let statusSQL = self.statusQueryForTable(table)

        func structureFactory(_ row: SDRow) -> StructureRow {
            let typeCode = row["type"] as! Int
            let type = BookmarkNodeType(rawValue: typeCode)   // nil if typeCode is invalid (e.g., -1).
            return (parent: row["parent"] as! GUID, child: row["child"] as! GUID, type: type)
        }

        func nonStructureFactory(_ row: SDRow) -> BookmarkTreeNode {
            let guid = row["guid"] as! GUID
            let typeCode = row["type"] as! Int
            if let type = BookmarkNodeType(rawValue: typeCode) {
                switch type {
                case .folder:
                    return BookmarkTreeNode.folder(guid: guid, children: [])
                default:
                    return BookmarkTreeNode.nonFolder(guid: guid)
                }
            } else {
                return BookmarkTreeNode.unknown(guid: guid)
            }
        }

        func statusFactory(_ row: SDRow) -> (GUID, Bool) {
            return (row["guid"] as! GUID, row.getBoolean("is_deleted"))
        }

        return self.db.runQuery(statusSQL, args: nil, factory: statusFactory)
            >>== { cursor in
                var deleted = Set<GUID>()
                var modified = Set<GUID>()
                cursor.forEach { pair in
                    let (guid, del) = pair!    // Oh, cursor.
                    if del {
                        deleted.insert(guid)
                    } else {
                        modified.insert(guid)
                    }
                }

                return self.db.runQuery(remainderSQL, args: nil, factory: nonStructureFactory)
                    >>== { cursor in
                        let nonFoldersAndEmptyFolders = cursor.asArray()
                        return self.db.runQuery(structureSQL, args: nil, factory: structureFactory)
                            >>== { cursor in
                                let structureRows = cursor.asArray()
                                let tree = BookmarkTree.mappingsToTreeForStructureRows(structureRows, withNonFoldersAndEmptyFolders: nonFoldersAndEmptyFolders, withDeletedRecords: deleted, modifiedRecords: modified, alwaysIncludeRoots: includeRoots)
                                return deferMaybe(tree)
                        }
                }
        }
    }

    public func treeForMirror() -> Deferred<Maybe<BookmarkTree>> {
        return self.treeForTable(TableBookmarksMirror, structure: TableBookmarksMirrorStructure, alwaysIncludeRoots: true)
    }

    public func treeForBuffer() -> Deferred<Maybe<BookmarkTree>> {
        return self.treeForTable(TableBookmarksBuffer, structure: TableBookmarksBufferStructure, alwaysIncludeRoots: false)
    }

    public func treeForLocal() -> Deferred<Maybe<BookmarkTree>> {
        return self.treeForTable(TableBookmarksLocal, structure: TableBookmarksLocalStructure, alwaysIncludeRoots: false)
    }
}

// MARK: - Applying merge operations.

public extension SQLiteBookmarkBufferStorage {
    public func applyBufferCompletionOp(_ op: BufferCompletionOp, itemSources: ItemSources) -> Success {
        log.debug("Marking buffer rows as applied.")
        if op.isNoOp {
            log.debug("Nothing to do.")
            return succeed()
        }

        var queries: [(sql: String, args: Args?)] = []
        op.processedBufferChanges.subsetsOfSize(BrowserDB.MaxVariableNumber).forEach { guids in
            let varlist = BrowserDB.varlist(guids.count)
            let args: Args = guids.map { $0 }
            queries.append((sql: "DELETE FROM \(TableBookmarksBufferStructure) WHERE parent IN \(varlist)", args: args))
            queries.append((sql: "DELETE FROM \(TableBookmarksBuffer) WHERE guid IN \(varlist)", args: args))
        }

        return self.db.run(queries)
    }

    public func getChildrenGUIDsOf(_ guid: GUID) -> Deferred<Maybe<[GUID]>> {
        let sql = "SELECT child FROM \(TableBookmarksBufferStructure) WHERE parent = ? ORDER BY idx ASC"
        let args: Args = [guid]

        return self.db.runQuery(sql, args: args, factory: StringFactory) >>== { deferMaybe($0.asArray()) }
    }
}

extension MergedSQLiteBookmarks {
    public func applyLocalOverrideCompletionOp(_ op: LocalOverrideCompletionOp, itemSources: ItemSources) -> Success {
        log.debug("Applying local op to merged.")
        if op.isNoOp {
            log.debug("Nothing to do.")
            return succeed()
        }

        // This is a little tortured because we want it all to happen in a single transaction.
        // We walk through the accrued work items, applying them in the right order (e.g., structure
        // then value). If at any point we fail, we abort, roll back the transaction by throwing.
        return local.db.transaction { conn -> Void in
            // So we can trample the DB in any order.
            try conn.executeChange("PRAGMA defer_foreign_keys = ON")
            
            log.debug("Deleting \(op.mirrorItemsToDelete.count) mirror items.")

            try op.mirrorItemsToDelete.withSubsetsOfSize(BrowserDB.MaxVariableNumber) { guids in
                let args: Args = guids.map { $0 }
                let varlist = BrowserDB.varlist(guids.count)
                
                let sqlMirrorStructure = "DELETE FROM \(TableBookmarksMirrorStructure) WHERE parent IN \(varlist)"
                try conn.executeChange(sqlMirrorStructure, withArgs: args)
                
                let sqlMirror = "DELETE FROM \(TableBookmarksMirror) WHERE guid IN \(varlist)"
                try conn.executeChange(sqlMirror, withArgs: args)
            }
            
            // Copy from other tables for simplicity.
            // Do this *before* we throw away local and buffer changes!
            // This is one reason why the local override step needs to be processed before the buffer is cleared.
            try op.mirrorValuesToCopyFromBuffer.withSubsetsOfSize(BrowserDB.MaxVariableNumber) { guids in
                let args: Args = guids.map { $0 }
                let varlist = BrowserDB.varlist(guids.count)
                let copySQL = [
                    "INSERT OR REPLACE INTO \(TableBookmarksMirror)",
                    "(guid, type, date_added, parentid, parentName, feedUri, siteUri, pos, title, description,",
                    "bmkUri, tags, keyword, folderName, queryId, server_modified)",
                    "SELECT guid, type, date_added, parentid, parentName, feedUri, siteUri, pos, title, description,",
                    "bmkUri, tags, keyword, folderName, queryId, server_modified",
                    "FROM \(TableBookmarksBuffer)",
                    "WHERE guid IN",
                    varlist
                    ].joined(separator: " ")
                
                try conn.executeChange(copySQL, withArgs: args)
            }
            
            try op.mirrorValuesToCopyFromLocal.withSubsetsOfSize(BrowserDB.MaxVariableNumber) { guids in
                let args: Args = guids.map { $0 }
                let varlist = BrowserDB.varlist(guids.count)
                let copySQL = [
                    "INSERT OR REPLACE INTO \(TableBookmarksMirror)",
                    "(guid, type, date_added, parentid, parentName, feedUri, siteUri, pos, title, description,",
                    "bmkUri, tags, keyword, folderName, queryId, faviconID, server_modified)",
                    "SELECT guid, type, date_added, parentid, parentName, feedUri, siteUri, pos, title, description,",
                    "bmkUri, tags, keyword, folderName, queryId, faviconID,",
                    
                    // This will be fixed up in batches after the initial copy.
                    "0 AS server_modified",
                    "FROM \(TableBookmarksLocal) WHERE guid IN",
                    varlist
                    ].joined(separator: " ")
                
                try conn.executeChange(copySQL, withArgs: args)
            }
            
            try op.modifiedTimes.forEach { (time, guids) in
                // This will never be too big: we upload in chunks
                // smaller than 999!
                precondition(guids.count < BrowserDB.MaxVariableNumber)
                
                log.debug("Swizzling server modified time to \(time) for \(guids.count) GUIDs.")
                let args: Args = guids.map { $0 }
                let varlist = BrowserDB.varlist(guids.count)
                let updateSQL = [
                    "UPDATE \(TableBookmarksMirror) SET server_modified = \(time)",
                    "WHERE guid IN",
                    varlist,
                    ].joined(separator: " ")
                try conn.executeChange(updateSQL, withArgs: args)
            }
            
            log.debug("Marking \(op.processedLocalChanges.count) local changes as processed.")
            try op.processedLocalChanges.withSubsetsOfSize(BrowserDB.MaxVariableNumber) { guids in
                let args: Args = guids.map { $0 }
                let varlist = BrowserDB.varlist(guids.count)
                
                let sqlLocalStructure = "DELETE FROM \(TableBookmarksLocalStructure) WHERE parent IN \(varlist)"
                try conn.executeChange(sqlLocalStructure, withArgs: args)
                
                let sqlLocal = "DELETE FROM \(TableBookmarksLocal) WHERE guid IN \(varlist)"
                try conn.executeChange(sqlLocal, withArgs: args)
                
                // If the values change, we'll handle those elsewhere, but at least we need to mark these as non-overridden.
                let sqlMirrorOverride = "UPDATE \(TableBookmarksMirror) SET is_overridden = 0 WHERE guid IN \(varlist)"
                try conn.executeChange(sqlMirrorOverride, withArgs: args)
            }
            
            if !op.mirrorItemsToUpdate.isEmpty {
                let updateSQL = [
                    "UPDATE \(TableBookmarksMirror) SET",
                    "type = ?, date_added = ?, server_modified = ?, is_deleted = ?,",
                    "hasDupe = ?, parentid = ?, parentName = ?,",
                    "feedUri = ?, siteUri = ?, pos = ?, title = ?,",
                    "description = ?, bmkUri = ?, tags = ?, keyword = ?,",
                    "folderName = ?, queryId = ?, is_overridden = 0",
                    "WHERE guid = ?",
                    ].joined(separator: " ")
                
                try op.mirrorItemsToUpdate.forEach { (_, mirrorItem) in
                    let args = mirrorItem.getUpdateOrInsertArgs()
                    try conn.executeChange(updateSQL, withArgs: args)
                }
            }
            
            if !op.mirrorItemsToInsert.isEmpty {
                let insertSQL = [
                    "INSERT OR IGNORE INTO \(TableBookmarksMirror) (",
                    "type, date_added, server_modified, is_deleted,",
                    "hasDupe, parentid, parentName,",
                    "feedUri, siteUri, pos, title,",
                    "description, bmkUri, tags, keyword,",
                    "folderName, queryId, guid",
                    "VALUES",
                    "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    ].joined(separator: " ")
                
                try op.mirrorItemsToInsert.forEach { (_, mirrorItem) in
                    let args = mirrorItem.getUpdateOrInsertArgs()
                    try conn.executeChange(insertSQL, withArgs: args)
                }
            }
            
            if !op.mirrorStructures.isEmpty {
                let structureRows =
                    op.mirrorStructures.flatMap { (parent, children) in
                        return children.enumerated().map { (idx, child) -> Args in
                            let vals: Args = [parent, child, idx]
                            return vals
                        }
                }
                
                let parents = op.mirrorStructures.map { $0.0 }
                try deleteStructureForGUIDs(parents, fromTable: TableBookmarksMirrorStructure, connection: conn)
                try insertStructureIntoTable(TableBookmarksMirrorStructure, connection: conn, children: structureRows, maxVars: BrowserDB.MaxVariableNumber)
            }
        }
    }

    public func applyBufferUpdatedCompletionOp(_ op: BufferUpdatedCompletionOp) -> Success {
        log.debug("Applying buffer updates.")
        if op.isNoOp {
            log.debug("Nothing to do.")
            return succeed()
        }

        return local.db.transaction { conn -> Void in
            // So we can trample the DB in any order.
            try conn.executeChange("PRAGMA defer_foreign_keys = ON")
            
            try op.deletedValues.withSubsetsOfSize(BrowserDB.MaxVariableNumber) { guids in
                let args: Args = guids.map { $0 }
                let varlist = BrowserDB.varlist(guids.count)
                
                // This will leave the idx column sparse for the buffer children.
                let sqlBufferStructure = "DELETE FROM \(TableBookmarksBufferStructure) WHERE child IN \(varlist)"
                try conn.executeChange(sqlBufferStructure, withArgs: args)
                
                // This will also delete items from the pending deletions table on cascade.
                let sqlBuffer = "DELETE FROM \(TableBookmarksBuffer) WHERE guid IN \(varlist)"
                try conn.executeChange(sqlBuffer, withArgs: args)
            }
            
            let insertSQL = [
                "INSERT OR IGNORE INTO \(TableBookmarksBuffer) (",
                "type, date_added, server_modified, is_deleted,",
                "hasDupe, parentid, parentName,",
                "feedUri, siteUri, pos, title,",
                "description, bmkUri, tags, keyword,",
                "folderName, queryId, guid)",
                "VALUES",
                "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                ].joined(separator: " ")
            
            let args = op.mobileRoot.getUpdateOrInsertArgs()
            try conn.executeChange(insertSQL, withArgs: args)
            
            // We update server_modified in another operation because the first statement is an INSERT OR IGNORE
            // and we can't turn that into a INSERT OR REPLACE because this will cascade delete children
            // in the buffer structure table.
            let updateMobileRootTimeSQL = [
                "UPDATE \(TableBookmarksBuffer) SET server_modified = \(op.modifiedTime)",
                "WHERE guid = ?",
                ].joined(separator: " ")
            try conn.executeChange(updateMobileRootTimeSQL, withArgs: [op.mobileRoot.guid])
            
            try op.bufferValuesToMoveFromLocal.withSubsetsOfSize(BrowserDB.MaxVariableNumber) { guids in
                let args: Args = guids.map { $0 }
                let varlist = BrowserDB.varlist(guids.count)
                
                let copySQL = [
                    "INSERT OR REPLACE INTO \(TableBookmarksBuffer)",
                    "(guid, type, date_added, parentid, parentName, feedUri, siteUri, pos, title, description,",
                    "bmkUri, tags, keyword, folderName, queryId, server_modified)",
                    "SELECT guid, type, date_added, parentid, parentName, feedUri, siteUri, pos, title, description,",
                    "bmkUri, tags, keyword, folderName, queryId,",
                    "\(op.modifiedTime) AS server_modified",
                    "FROM \(TableBookmarksLocal) WHERE guid IN",
                    varlist
                    ].joined(separator: " ")
                try conn.executeChange(copySQL, withArgs: args)
            }
            
            try op.bufferValuesToMoveFromLocal.withSubsetsOfSize(BrowserDB.MaxVariableNumber) { guids in
                let args: Args = guids.map { $0 }
                let varlist = BrowserDB.varlist(guids.count)
                
                // This will leave the idx column sparse for the local children.
                let sqlLocalStructure = "DELETE FROM \(TableBookmarksLocalStructure) WHERE child IN \(varlist)"
                try conn.executeChange(sqlLocalStructure, withArgs: args)
                
                let sqlLocal = "DELETE FROM \(TableBookmarksLocal) WHERE guid IN \(varlist)"
                try conn.executeChange(sqlLocal, withArgs: args)
            }
            
            if op.bufferValuesToMoveFromLocal.count > 0 {
                guard let allChildren = op.mobileRoot.children else {
                    let err = DatabaseError(description: "Absent mobileRoot children. Aborting.")
                    log.error("applyBufferUpdatedCompletionOp(_:) encountered error: \(err.localizedDescription)")
                    throw err
                }
                let offset = allChildren.count - op.bufferValuesToMoveFromLocal.count
                
                let sqlNextIdx = "SELECT (COALESCE(MAX(idx), -1) + 1) AS newIndex FROM \(TableBookmarksBufferStructure) WHERE parent = ?"
                let nextIdxArgs: Args = [BookmarkRoots.MobileFolderGUID]
                let nextIdx = conn.executeQuery(sqlNextIdx, factory: IntFactory, withArgs: nextIdxArgs).asArray()[0]
                
                let toInsertArgs = Array(op.mobileRoot.getChildrenArgs(offset: offset, nextIdx: nextIdx))
                try insertStructureIntoTable(TableBookmarksBufferStructure, connection: conn, children: toInsertArgs, maxVars: BrowserDB.MaxVariableNumber)
            }
        }
    }
}
