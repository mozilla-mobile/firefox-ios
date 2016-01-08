/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.syncLogger

extension SQLiteBookmarks {
    func getSQLToOverrideFolder(folder: GUID, atModifiedTime modified: Timestamp) -> (sql: [String], args: Args) {
        return self.getSQLToOverrideFolders([folder], atModifiedTime: modified)
    }

    func getSQLToOverrideFolders(folders: [GUID], atModifiedTime modified: Timestamp) -> (sql: [String], args: Args) {
        if folders.isEmpty {
            return (sql: [], args: [])
        }

        let vars = BrowserDB.varlist(folders.count)
        let args: Args = folders.map { $0 as AnyObject }

        // Copy it to the local table.
        // Most of these will be NULL, because we're only dealing with folders,
        // and typically only the Mobile Bookmarks root.
        let overrideSQL = "INSERT OR IGNORE INTO \(TableBookmarksLocal) " +
                          "(guid, type, bmkUri, title, parentid, parentName, feedUri, siteUri, pos," +
                          " description, tags, keyword, folderName, queryId, is_deleted, " +
                          " local_modified, sync_status, faviconID) " +
                          "SELECT guid, type, bmkUri, title, parentid, parentName, " +
                          "feedUri, siteUri, pos, description, tags, keyword, folderName, queryId, " +
                          "is_deleted, " +
                          "\(modified) AS local_modified, \(SyncStatus.Changed.rawValue) AS sync_status, faviconID " +
                          "FROM \(TableBookmarksMirror) WHERE guid IN \(vars)"

        // Copy its mirror structure.
        let dropSQL = "DELETE FROM \(TableBookmarksLocalStructure) WHERE parent IN \(vars)"
        let copySQL = "INSERT INTO \(TableBookmarksLocalStructure) " +
                      "SELECT * FROM \(TableBookmarksMirrorStructure) WHERE parent IN \(vars)"

        // Mark as overridden.
        let markSQL = "UPDATE \(TableBookmarksMirror) SET is_overridden = 1 WHERE guid IN \(vars)"
        return (sql: [overrideSQL, dropSQL, copySQL, markSQL], args: args)
    }

    func getSQLToOverrideNonFolders(records: [GUID], atModifiedTime modified: Timestamp) -> (sql: [String], args: Args) {
        log.info("Getting SQL to override \(records).")
        if records.isEmpty {
            return (sql: [], args: [])
        }

        let vars = BrowserDB.varlist(records.count)
        let args: Args = records.map { $0 as AnyObject }

        // Copy any that aren't overridden to the local table.
        let overrideSQL =
        "INSERT OR IGNORE INTO \(TableBookmarksLocal) " +
        "(guid, type, bmkUri, title, parentid, parentName, feedUri, siteUri, pos," +
        " description, tags, keyword, folderName, queryId, is_deleted, " +
        " local_modified, sync_status, faviconID) " +
        "SELECT guid, type, bmkUri, title, parentid, parentName, " +
        "feedUri, siteUri, pos, description, tags, keyword, folderName, queryId, " +
        "is_deleted, " +
        "\(modified) AS local_modified, \(SyncStatus.Changed.rawValue) AS sync_status, faviconID " +
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
    func insertBookmarkInTransaction(deferred: Success, url: NSURL, title: String, favicon: Favicon?, intoFolder parent: GUID, withTitle parentTitle: String)(conn: SQLiteDBConnection, inout err: NSError?) -> Bool {

        log.debug("Begun bookmark transaction on thread \(NSThread.currentThread())")

        // Keep going if this returns true.
        func change(sql: String, args: Args?, desc: String) -> Bool {
            err = conn.executeChange(sql, withArgs: args)
            if let err = err {
                log.error(desc)
                deferred.fillIfUnfilled(Maybe(failure: DatabaseError(err: err)))
                return false
            }
            return true
        }

        let urlString = url.absoluteString
        let newGUID = Bytes.generateGUID()
        let now = NSDate.now()
        let parentArgs: Args = [parent]

        //// Insert the new bookmark and icon without touching structure.
        var args: Args = [
            newGUID,
            BookmarkNodeType.Bookmark.rawValue,
            urlString,
            title,
            parent,
            parentTitle,
            NSDate.nowNumber(),
            SyncStatus.New.rawValue,
        ]

        let faviconID: Int?

        // Insert the favicon.
        if let icon = favicon {
            faviconID = self.favicons.insertOrUpdate(conn, obj: icon)
        } else {
            faviconID = nil
        }

        log.debug("Inserting bookmark with GUID \(newGUID) and specified icon \(faviconID).")

        // If the caller didn't provide an icon (and they usually don't!),
        // do a reverse lookup in history. We use a view to make this simple.
        let iconValue: String
        if let faviconID = faviconID {
            iconValue = "?"
            args.append(faviconID)
        } else {
            iconValue = "(SELECT iconID FROM \(ViewIconForURL) WHERE url = ?)"
            args.append(urlString)
        }

        let insertSQL = "INSERT INTO \(TableBookmarksLocal) " +
                        "(guid, type, bmkUri, title, parentid, parentName, local_modified, sync_status, faviconID) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, \(iconValue))"
        if !change(insertSQL, args: args, desc: "Error inserting \(newGUID).") {
            return false
        }

        let bumpParentStatus = { (status: Int) -> Bool in
            let bumpSQL = "UPDATE \(TableBookmarksLocal) SET sync_status = \(status), local_modified = \(now) WHERE guid = ?"
            return change(bumpSQL, args: parentArgs, desc: "Error bumping \(parent)'s modified time.")
        }


        func overrideParentMirror() -> Bool {
            // We do this slightly tortured work so that we can reuse these queries
            // in a different context.
            let (sql, args) = getSQLToOverrideFolder(parent, atModifiedTime: now)
            var generator = sql.generate()
            while let query = generator.next() {
                if !change(query, args: args, desc: "Error running overriding query.") {
                    return false
                }
            }
            return true
        }

        //// Make sure our parent is overridden and appropriately bumped.
        // See discussion here: <https://github.com/mozilla/firefox-ios/commit/2041f1bbde430de29aefb803aae54ed26db47d23#commitcomment-14572312>
        // Note that this isn't as obvious as you might think. We must:
        let localStatusFactory: SDRow -> (Int, Bool) = { row in
            let status = row["sync_status"] as! Int
            let deleted = (row["is_deleted"] as! Int) != 0
            return (status, deleted)
        }

        let overriddenFactory: SDRow -> Bool = { row in
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
                deferred.fillIfUnfilled(Maybe(failure: DatabaseError(description: "Folder \(parent) doesn't exist in either mirror or local.")))
                return false
            }
            // * Mark the parent folder as overridden if necessary.
            //   Overriding the parent involves copying the parent's structure, so that
            //   we can amend it, but also the parent's row itself so that we know it's
            //   changed.
            overrideParentMirror()
        } else {
            let (status, deleted) = localStatus!
            if deleted {
                log.error("Trying to insert into deleted local folder.")
                deferred.fillIfUnfilled(Maybe(failure: DatabaseError(description: "Local folder \(parent) is deleted.")))
                return false
            }

            // * Bump the overridden parent's modified time. We already copied its
            //   structure and values, and if it's in the local table it'll either
            //   already be New or Changed.

            if let syncStatus = SyncStatus(rawValue: status) {
                switch syncStatus {
                case .Synced:
                    log.debug("We don't expect folders to ever be marked as Synced.")
                    if !bumpParentStatus(SyncStatus.Changed.rawValue) {
                        return false
                    }
                case .New:
                    fallthrough
                case .Changed:
                    // Leave it marked as new or changed, but bump the timestamp.
                    if !bumpParentStatus(syncStatus.rawValue) {
                        return false
                    }
                }
            } else {
                log.warning("Local folder marked with unknown state \(status). This should never occur.")
                if !bumpParentStatus(SyncStatus.Changed.rawValue) {
                    return false
                }
            }
        }

        /// Add the new bookmark as a child in the modified local structure.
        // We always append the new row: after insertion, the new item will have the largest index.
        let newIndex = "(SELECT (COALESCE(MAX(idx), -1) + 1) AS newIndex FROM \(TableBookmarksLocalStructure) WHERE parent = ?)"
        let structureSQL = "INSERT INTO \(TableBookmarksLocalStructure) (parent, child, idx) " +
                           "VALUES (?, ?, \(newIndex))"
        let structureArgs: Args = [parent, newGUID, parent]

        if !change(structureSQL, args: structureArgs, desc: "Error adding new item \(newGUID) to local structure.") {
            return false
        }

        log.debug("Wrapped up bookmark transaction on thread \(NSThread.currentThread())")

        /// Fill the deferred and commit the transaction.
        deferred.fill(Maybe(success: ()))
        return true
    }

    /**
     * Assumption: the provided folder GUID exists in either the local table or the mirror table.
     */
    func insertBookmark(url: NSURL, title: String, favicon: Favicon?, intoFolder parent: GUID, withTitle parentTitle: String) -> Success {
        log.debug("Inserting bookmark task on thread \(NSThread.currentThread())")
        let deferred = Success()

        var error: NSError?
        let inTransaction = self.insertBookmarkInTransaction(deferred, url: url, title: title, favicon: favicon, intoFolder: parent, withTitle: parentTitle)
        error = self.db.transaction(synchronous: false, err: &error, callback: inTransaction)

        log.debug("Returning deferred on thread \(NSThread.currentThread())")
        return deferred
    }
}

private extension BookmarkMirrorItem {
    func getChildrenArgs() -> [Args] {
        // Only folders have children, and we manage roots ourselves.
        if self.type != .Folder ||
           self.guid == BookmarkRoots.RootGUID {
            return []
        }
        let parent = self.guid
        var idx = 0
        return self.children?.map { child in
            let ret: Args = [parent, child, idx++]
            return ret
        } ?? []
    }

    func getUpdateOrInsertArgs() -> Args {
        let args: Args = [
            self.type.rawValue,
            NSNumber(unsignedLongLong: self.serverModified),
            self.isDeleted ? 1 : 0,
            self.hasDupe ? 1 : 0,
            self.parentID,
            self.parentName,
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

/**
 * This stores incoming records in a buffer.
 * When appropriate, the buffer is merged with the mirror and local storage
 * in the DB.
 */
public class SQLiteBookmarkBufferStorage: BookmarkBufferStorage {
    let db: BrowserDB

    public init(db: BrowserDB) {
        self.db = db
    }

    /**
     * Remove child records for any folders that've been deleted or are empty.
     */
    private func deleteChildrenInTransactionWithGUIDs(guids: [GUID], connection: SQLiteDBConnection, withMaxVars maxVars: Int=BrowserDB.MaxVariableNumber) -> NSError? {
        log.debug("Deleting \(guids.count) parents from buffer structure table.")
        let chunks = chunk(guids, by: maxVars)
        for chunk in chunks {
            let inList = Array<String>(count: chunk.count, repeatedValue: "?").joinWithSeparator(", ")
            let delStructure = "DELETE FROM \(TableBookmarksBufferStructure) WHERE parent IN (\(inList))"

            let args: Args = chunk.flatMap { $0 as AnyObject }
            if let error = connection.executeChange(delStructure, withArgs: args) {
                log.error("Updating mirror structure: \(error.description).")
                return error
            }
        }
        return nil
    }

    public func isEmpty() -> Deferred<Maybe<Bool>> {
        return self.db.queryReturnsNoResults("SELECT 1 FROM \(TableBookmarksBuffer)")
    }

    /**
     * This is a little gnarly because our DB access layer is rough.
     * Within a single transaction, we walk the list of items, attempting to update
     * and inserting if the update failed. (TODO: batch the inserts!)
     * Once we've added all of the records, we flatten all of their children
     * into big arg lists and hard-update the structure table.
     */
    public func applyRecords(records: [BookmarkMirrorItem]) -> Success {
        return self.applyRecords(records, withMaxVars: BrowserDB.MaxVariableNumber)
    }

    public func applyRecords(records: [BookmarkMirrorItem], withMaxVars maxVars: Int) -> Success {
        let deferred = Deferred<Maybe<()>>(defaultQueue: dispatch_get_main_queue())

        let deleted = records.filter { $0.isDeleted }.map { $0.guid }
        let values = records.map { $0.getUpdateOrInsertArgs() }
        let children = records.filter { !$0.isDeleted }.flatMap { $0.getChildrenArgs() }
        let folders = records.filter { $0.type == BookmarkNodeType.Folder }.map { $0.guid }

        var err: NSError?
        self.db.transaction(&err) { (conn, err) -> Bool in
            // These have the same values in the same order.
            let update =
            "UPDATE \(TableBookmarksBuffer) SET " +
            "type = ?, server_modified = ?, is_deleted = ?, " +
            "hasDupe = ?, parentid = ?, parentName = ?, " +
            "feedUri = ?, siteUri = ?, pos = ?, title = ?, " +
            "description = ?, bmkUri = ?, tags = ?, keyword = ?, " +
            "folderName = ?, queryId = ? " +
            "WHERE guid = ?"

            let insert =
            "INSERT OR IGNORE INTO \(TableBookmarksBuffer) " +
            "(type, server_modified, is_deleted, hasDupe, parentid, parentName, " +
             "feedUri, siteUri, pos, title, description, bmkUri, tags, keyword, folderName, queryId, guid) " +
            "VALUES " +
            "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

            for args in values {
                if let error = conn.executeChange(update, withArgs: args) {
                    log.error("Updating mirror in buffer: \(error.description).")
                    err = error
                    deferred.fill(Maybe(failure: DatabaseError(err: error)))
                    return false
                }

                if conn.numberOfRowsModified > 0 {
                    continue
                }

                if let error = conn.executeChange(insert, withArgs: args) {
                    log.error("Inserting mirror into buffer: \(error.description).")
                    err = error
                    deferred.fill(Maybe(failure: DatabaseError(err: error)))
                    return false
                }
            }

            // Delete existing structure for any folders we've seen. We always trust the folders,
            // not the children's parent pointers, so we do this here: we'll insert their current
            // children right after, when we process the child structure rows.
            // We only drop the child structure for deleted folders, not the record itself.
            // Deleted records stay in the buffer table so that we know about the deletion
            // when we do a real sync!

            log.debug("\(folders.count) folders and \(deleted.count) deleted maybe-folders to drop from buffer structure table.")

            if let error = self.deleteChildrenInTransactionWithGUIDs(folders + deleted, connection: conn) {
                deferred.fill(Maybe(failure: DatabaseError(err: error)))
                return false
            }

            // (Re-)insert children in chunks.
            log.debug("Inserting \(children.count) children.")
            if !children.isEmpty {
                // Insert the new structure rows. This uses three vars per row.
                let maxRowsPerInsert: Int = maxVars / 3
                let chunks = chunk(children, by: maxRowsPerInsert)
                for chunk in chunks {
                    log.verbose("Inserting \(chunk.count)…")
                    let childArgs: Args = chunk.flatMap { $0 }   // Flatten [[a, b, c], [...]] into [a, b, c, ...].
                    let ins = "INSERT INTO \(TableBookmarksBufferStructure) (parent, child, idx) VALUES " +
                              Array<String>(count: chunk.count, repeatedValue: "(?, ?, ?)").joinWithSeparator(", ")
                    log.debug("Inserting \(chunk.count) records (out of \(children.count)).")
                    if let error = conn.executeChange(ins, withArgs: childArgs) {
                        log.error("Updating buffer structure: \(error.description).")
                        err = error
                        deferred.fill(Maybe(failure: DatabaseError(err: error)))
                        return false
                    }
                }
            }

            if err == nil {
                deferred.fillIfUnfilled(Maybe(success: ()))
                return true
            }

            deferred.fillIfUnfilled(Maybe(failure: DatabaseError(err: err)))
            return false
        }

        return deferred
    }

    public func doneApplyingRecordsAfterDownload() -> Success {
        self.db.checkpoint()
        return succeed()
    }
}

public class MergedSQLiteBookmarks {
    let local: SQLiteBookmarks
    let buffer: SQLiteBookmarkBufferStorage

    public init(db: BrowserDB) {
        self.local = SQLiteBookmarks(db: db)
        self.buffer = SQLiteBookmarkBufferStorage(db: db)
    }
}

extension MergedSQLiteBookmarks: BookmarkBufferStorage {
    public func isEmpty() -> Deferred<Maybe<Bool>> {
        return self.buffer.isEmpty()
    }

    public func applyRecords(records: [BookmarkMirrorItem]) -> Success {
        return self.buffer.applyRecords(records)
    }

    public func doneApplyingRecordsAfterDownload() -> Success {
        // It doesn't really matter which one we checkpoint -- they're both backed by the same DB.
        return self.buffer.doneApplyingRecordsAfterDownload()
    }

    public func validate() -> Success {
        return self.buffer.validate()
    }
}

extension MergedSQLiteBookmarks: ShareToDestination {
    public func shareItem(item: ShareItem) {
        self.local.shareItem(item)
    }
}

extension MergedSQLiteBookmarks: BookmarksModelFactory {
    public func modelForFolder(folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        return self.local.modelForFolder(folder)
    }

    public func modelForFolder(guid: String) -> Deferred<Maybe<BookmarksModel>> {
        return self.local.modelForFolder(guid)
    }

    public func modelForFolder(guid: String, title: String) -> Deferred<Maybe<BookmarksModel>> {
        return self.local.modelForFolder(guid, title: title)
    }

    public func modelForRoot() -> Deferred<Maybe<BookmarksModel>> {
        return self.local.modelForRoot()
    }

    // Whenever async construction is necessary, we fall into a pattern of needing
    // a placeholder that behaves correctly for the period between kickoff and set.
    public var nullModel: BookmarksModel {
        return self.local.nullModel
    }

    public func isBookmarked(url: String) -> Deferred<Maybe<Bool>> {
        return self.local.isBookmarked(url)
    }

    public func removeByGUID(guid: GUID) -> Success {
        log.debug("removeByGUID: \(guid)")
        return self.local.removeByGUID(guid)
    }

    public func removeByURL(url: String) -> Success {
        return self.local.removeByURL(url)
    }

    func clearBookmarks() -> Success {
        return self.local.clearBookmarks()
    }
}

// Not actually implementing SyncableBookmarks, just a utility for MergedSQLiteBookmarks to do so.
extension SQLiteBookmarks {
    public func isUnchanged() -> Deferred<Maybe<Bool>> {
        return self.db.queryReturnsNoResults("SELECT 1 FROM \(TableBookmarksLocal)")
    }
}

extension MergedSQLiteBookmarks: SyncableBookmarks {
    public func isUnchanged() -> Deferred<Maybe<Bool>> {
        return self.local.isUnchanged()
    }
}


// MARK: - Validation of buffer contents.

private let allBufferStructuresReferToRecords =
"SELECT s.child AS pointee, s.parent AS pointer FROM " +
"\(ViewBookmarksBufferStructureOnMirror) s LEFT JOIN \(ViewBookmarksBufferOnMirror) b " +
"ON b.guid = s.child WHERE b.guid IS NULL"

private let allNonDeletedBufferRecordsAreInStructure =
"SELECT b.guid AS missing, b.parentid AS parent FROM " +
"\(ViewBookmarksBufferOnMirror) b LEFT JOIN \(ViewBookmarksBufferStructureOnMirror) s " +
"ON b.guid = s.child " +
"WHERE s.child IS NULL AND " +
"b.is_deleted IS 0 AND " +
"b.parentid IS NOT '\(BookmarkRoots.RootGUID)'"

private let allRecordsAreChildrenOnce =
"SELECT s.child FROM \(ViewBookmarksBufferStructureOnMirror) s " +
"INNER JOIN (" +
"SELECT child, COUNT(*) AS dupes FROM \(ViewBookmarksBufferStructureOnMirror) " +
"GROUP BY child HAVING dupes > 1" +
") i ON s.child = i.child"

private let bufferParentidMatchesStructure =
"SELECT b.guid, b.parentid, s.parent, s.child, s.idx FROM " +
"\(TableBookmarksBuffer) b JOIN \(TableBookmarksBufferStructure) s " +
"ON b.guid = s.child " +
"WHERE b.parentid IS NOT s.parent"

extension SQLiteBookmarkBufferStorage {
    public func validate() -> Success {
        func yup(message: String) -> Bool -> Success {
            return { truth in
                guard truth else {
                    log.warning(message)
                    return deferMaybe(DatabaseError(description: message))
                }
                return succeed()
            }
        }

        return [
            (allBufferStructuresReferToRecords, "Not all buffer structures refer to records. Buffer is inconsistent."),
            (allNonDeletedBufferRecordsAreInStructure, "Not all buffer records are in structure. Buffer is inconsistent."),
            (allRecordsAreChildrenOnce, "Some buffer structures refer to the same records. Buffer is inconsistent."),
            (bufferParentidMatchesStructure, "Some buffer records don't match structure. Buffer is inconsistent."),
        ].map { (query, message) in
            return self.db.queryReturnsNoResults(query) >>== yup(message)
        }.allSucceed()
    }
}