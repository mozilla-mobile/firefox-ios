/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared

private let log = Logger.syncLogger
private let desktopBookmarksLabel: String = NSLocalizedString("Desktop Bookmarks", tableName: "BookmarkPanel", comment: "The folder name for the virtual folder that contains all desktop bookmarks.")

public enum Direction {
    case buffer
    case local

    var structureTable: String {
        switch self {
        case .local:
            return TableBookmarksLocalStructure
        case .buffer:
            return TableBookmarksBufferStructure
        }
    }

    var valueTable: String {
        switch self {
        case .local:
            return TableBookmarksLocal
        case .buffer:
            return TableBookmarksBuffer
        }
    }

    var valueView: String {
        switch self {
        case .local:
            return ViewBookmarksLocalOnMirror
        case .buffer:
            return ViewBookmarksBufferOnMirror
        }
    }

    var structureView: String {
        switch self {
        case .local:
            return ViewBookmarksLocalStructureOnMirror
        case .buffer:
            return ViewBookmarksBufferStructureOnMirror
        }
    }
}

public protocol KeywordSearchSource {
    func getURLForKeywordSearch(_ keyword: String) -> Deferred<Maybe<String>>
}

open class SQLiteBookmarksModelFactory: BookmarksModelFactory {
    fileprivate let bookmarks: SQLiteBookmarks
    fileprivate let direction: Direction

    public init(bookmarks: SQLiteBookmarks, direction: Direction) {
        self.bookmarks = bookmarks
        self.direction = direction
    }

    fileprivate func withDifferentDirection(_ direction: Direction) -> SQLiteBookmarksModelFactory {
        if self.direction == direction {
            return self
        }
        return SQLiteBookmarksModelFactory(bookmarks: self.bookmarks, direction: direction)
    }

    fileprivate func getChildrenWithParent(_ parentGUID: GUID, excludingGUIDs: [GUID]?=nil, includeIcon: Bool) -> Deferred<Maybe<Cursor<BookmarkNode>>> {
        return self.bookmarks.getChildrenWithParent(parentGUID, direction: self.direction, excludingGUIDs: excludingGUIDs, includeIcon: includeIcon)
    }

    fileprivate func getRootChildren() -> Deferred<Maybe<Cursor<BookmarkNode>>> {
        return self.getChildrenWithParent(BookmarkRoots.RootGUID, excludingGUIDs: [BookmarkRoots.RootGUID], includeIcon: true)
    }

    fileprivate func getChildren(_ guid: String) -> Deferred<Maybe<Cursor<BookmarkNode>>> {
        return self.getChildrenWithParent(guid, includeIcon: true)
    }

    func folderForGUID(_ guid: GUID, title: String) -> Deferred<Maybe<BookmarkFolder>> {
        return self.getChildren(guid)
            >>== { cursor in

            if cursor.status == .failure {
                return deferMaybe(DatabaseError(description: "Couldn't get children: \(cursor.statusMessage)."))
            }

            return deferMaybe(SQLiteBookmarkFolder(guid: guid, title: title, children: cursor))
        }
    }

    fileprivate func modelWithRoot(_ root: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        return deferMaybe(BookmarksModel(modelFactory: self, root: root))
    }

    open func modelForFolder(_ guid: String, title: String) -> Deferred<Maybe<BookmarksModel>> {
        if guid == BookmarkRoots.MobileFolderGUID {
            return self.modelForRoot()
        }

        if guid == BookmarkRoots.FakeDesktopFolderGUID {
            return self.modelForDesktopBookmarks()
        }

        let outputTitle = titleForSpecialGUID(guid) ?? title
        return self.folderForGUID(guid, title: outputTitle)
          >>== self.modelWithRoot
    }

    open func modelForFolder(_ folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(folder.guid, title: folder.title)
    }

    open func modelForFolder(_ guid: String) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(guid, title: "")
    }

    open func modelForRoot() -> Deferred<Maybe<BookmarksModel>> {
        log.debug("Getting model for root.")
        let getFolder = self.folderForGUID(BookmarkRoots.MobileFolderGUID, title: BookmarksFolderTitleMobile)
        if self.direction == .buffer {
            return getFolder >>== self.modelWithRoot
        }

        // Return a virtual model containing "Desktop bookmarks" prepended to the local mobile bookmarks.
        return getFolder >>== { folder in
            self.extendWithDesktopBookmarksFolder(folder, factory: self)
        }
    }

    open var nullModel: BookmarksModel {
        let children = Cursor<BookmarkNode>(status: .failure, msg: "Null model")
        let folder = SQLiteBookmarkFolder(guid: "Null", title: "Null", children: children)
        return BookmarksModel(modelFactory: self, root: folder)
    }

    open func isBookmarked(_ url: String) -> Deferred<Maybe<Bool>> {
        return self.bookmarks.isBookmarked(url, direction: self.direction)
    }

    open func removeByURL(_ url: String) -> Success {
        if self.direction == Direction.buffer {
            return deferMaybe(DatabaseError(description: "Refusing to remove URL from buffer in model."))
        }

        // Find all of the records for the provided URL. Don't bother with
        // any that are already deleted!
        return self.bookmarks.nonDeletedGUIDsForURL(url)
          >>== self.bookmarks.removeGUIDs
    }

    open func removeByGUID(_ guid: GUID) -> Success {
        if self.direction == Direction.buffer {
            return deferMaybe(DatabaseError(description: "Refusing to remove GUID from buffer in model."))
        }

        log.debug("removeByGUID: \(guid)")
        return self.bookmarks.removeGUIDs([guid])
    }

    func hasDesktopBookmarks() -> Deferred<Maybe<Bool>> {
        // This is very lazy, but it has the nice property of keeping Desktop Bookmarks visible
        // for a while after you mark the last desktop child as deleted.
        let parents: Args = [
            // Local.
            BookmarkRoots.MenuFolderGUID,
            BookmarkRoots.ToolbarFolderGUID,
            BookmarkRoots.UnfiledFolderGUID,

            // Mirror.
            BookmarkRoots.MenuFolderGUID,
            BookmarkRoots.ToolbarFolderGUID,
            BookmarkRoots.UnfiledFolderGUID,
        ]

        let sql =
        "SELECT 1 FROM \(self.direction.structureTable) WHERE parent IN (?, ?, ?)" +
        " UNION ALL " +
        "SELECT 1 FROM \(TableBookmarksMirrorStructure) WHERE parent IN (?, ?, ?)" +
        " LIMIT 1"

        return self.bookmarks.db.queryReturnsResults(sql, args: parents)
    }

    func getDesktopRoots() -> Deferred<Maybe<Cursor<BookmarkNode>>> {
        if self.direction == .buffer {
            // The buffer never includes the Places root, so we look one level deeper.
            // Because this is a special-case overlay, we include Mobile Bookmarks here --
            // that'll show bookmarks from other mobile devices.
            return self.bookmarks.getRecordsWithGUIDs(BookmarkRoots.RootChildren, direction: self.direction, includeIcon: false)
        }

        // We deliberately exclude the mobile folder, because we're inverting the containment
        // relationship here.
        let exclude = [BookmarkRoots.MobileFolderGUID, BookmarkRoots.RootGUID]
        return self.getChildrenWithParent(BookmarkRoots.RootGUID, excludingGUIDs: exclude, includeIcon: false)
    }

    /**
     * Prepend the provided mobile bookmarks folder with a single folder.
     * The prepended folder is "Desktop Bookmarks". It contains mirrored folders.
     */
    open func extendWithDesktopBookmarksFolder(_ mobile: BookmarkFolder, factory: BookmarksModelFactory) -> Deferred<Maybe<BookmarksModel>> {

        func onlyMobile() -> Deferred<Maybe<BookmarksModel>> {
            // No desktop bookmarks.
            log.debug("No desktop bookmarks. Only showing mobile.")
            return deferMaybe(BookmarksModel(modelFactory: factory, root: mobile))
        }

        return self.hasDesktopBookmarks() >>== { yes in
            if !yes {
                return onlyMobile()
            }

            return self.getDesktopRoots() >>== { cursor in
                if cursor.count == 0 {
                    // This shouldn't occur.
                    return onlyMobile()
                }

                let desktop = self.folderForDesktopBookmarksCursor(cursor)
                let prepended = PrependedBookmarkFolder(main: mobile, prepend: desktop)
                return deferMaybe(BookmarksModel(modelFactory: factory, root: prepended))
            }
        }
    }

    fileprivate func modelForDesktopBookmarks() -> Deferred<Maybe<BookmarksModel>> {
        return self.getDesktopRoots() >>== { cursor in
            let desktop = self.folderForDesktopBookmarksCursor(cursor)
            return deferMaybe(BookmarksModel(modelFactory: self, root: desktop))
        }
    }

    fileprivate func folderForDesktopBookmarksCursor(_ cursor: Cursor<BookmarkNode>) -> SQLiteBookmarkFolder {
        return SQLiteBookmarkFolder(guid: BookmarkRoots.FakeDesktopFolderGUID, title: desktopBookmarksLabel, children: cursor)
    }
}

private func isEditableExpression(_ direction: Direction) -> String {
    if direction == .buffer {
        return "0"
    }

    return "SELECT exists( " +
           "   SELECT exists(SELECT 1 FROM \(TableBookmarksBuffer)) AS hasBuffer, exists(SELECT 1 FROM \(TableBookmarksMirror)) AS hasMirror " +
           "   WHERE hasBuffer IS 0 OR hasMirror IS 0" +
           ")"
}

extension SQLiteBookmarks {

    fileprivate func getRecordsWithGUIDs(_ guids: [GUID], direction: Direction, includeIcon: Bool) -> Deferred<Maybe<Cursor<BookmarkNode>>> {

        let args: Args = guids
        let varlist = BrowserDB.varlist(args.count)
        let values =
        "SELECT -1 AS id, guid, type, is_deleted, parentid, parentName, feedUri, pos, title, bmkUri, siteUri, folderName, faviconID, (\(isEditableExpression(direction))) AS isEditable " +
        "FROM \(direction.valueView) WHERE guid IN \(varlist) AND NOT is_deleted"

        let withIcon = [
            "SELECT bookmarks.id AS id, bookmarks.guid AS guid, bookmarks.type AS type,",
            "       bookmarks.is_deleted AS is_deleted,",
            "       bookmarks.parentid AS parentid, bookmarks.parentName AS parentName,",
            "       bookmarks.feedUri AS feedUri, bookmarks.pos AS pos, title AS title,",
            "       bookmarks.bmkUri AS bmkUri, bookmarks.siteUri AS siteUri,",
            "       bookmarks.folderName AS folderName,",
            "       bookmarks.isEditable AS isEditable,",
            "       favicons.url AS iconURL, favicons.date AS iconDate, favicons.type AS iconType",
            "FROM (", values, ") AS bookmarks",
            "LEFT OUTER JOIN favicons ON bookmarks.faviconID = favicons.id",
            "ORDER BY title ASC",
            ].joined(separator: " ")

        let sql = (includeIcon ? withIcon : values) + " ORDER BY title ASC"
        return self.db.runQuery(sql, args: args, factory: BookmarkFactory.factory)
    }

    /**
     * Return the children of the provided parent.
     * Rows are ordered by positional index.
     * This method is aware of is_overridden and deletion, using local override structure by preference.
     * Note that a folder can be empty locally; we thus use the flag rather than looking at the structure itself.
     */
    func getChildrenWithParent(_ parentGUID: GUID, direction: Direction, excludingGUIDs: [GUID]?=nil, includeIcon: Bool) -> Deferred<Maybe<Cursor<BookmarkNode>>> {

        precondition((excludingGUIDs ?? []).count < 100, "Sanity bound for the number of GUIDs we can exclude.")

        let valueView = direction.valueView
        let structureView = direction.structureView

        let structure =
        "SELECT parent, child AS guid, idx FROM \(structureView) " +
        "WHERE parent = ?"

        let values =
        "SELECT -1 AS id, guid, type, is_deleted, parentid, parentName, feedUri, pos, title, bmkUri, siteUri, folderName, faviconID, (\(isEditableExpression(direction))) AS isEditable " +
        "FROM \(valueView)"

        // We exclude queries and dynamic containers, because we can't
        // usefully display them.
        let typeQuery = BookmarkNodeType.query.rawValue
        let typeDynamic = BookmarkNodeType.dynamicContainer.rawValue
        let typeFilter = " vals.type NOT IN (\(typeQuery), \(typeDynamic))"

        let args: Args
        let exclusion: String
        if let excludingGUIDs = excludingGUIDs {
            args = ([parentGUID] + excludingGUIDs).map { $0 }
            exclusion = "\(typeFilter) AND vals.guid NOT IN " + BrowserDB.varlist(excludingGUIDs.count)
        } else {
            args = [parentGUID]
            exclusion = typeFilter
        }

        let fleshed =
        "SELECT vals.id AS id, vals.guid AS guid, vals.type AS type, vals.is_deleted AS is_deleted, " +
        "       vals.parentid AS parentid, vals.parentName AS parentName, vals.feedUri AS feedUri, " +
        "       vals.siteUri AS siteUri," +
        "       vals.pos AS pos, vals.title AS title, vals.bmkUri AS bmkUri, vals.folderName AS folderName, " +
        "       vals.faviconID AS faviconID, " +
        "       vals.isEditable AS isEditable, " +
        "       structure.idx AS idx, " +
        "       structure.parent AS _parent " +
        "FROM (\(structure)) AS structure JOIN (\(values)) AS vals " +
        "ON vals.guid = structure.guid " +
        "WHERE " + exclusion

        let withIcon =
        "SELECT bookmarks.id AS id, bookmarks.guid AS guid, bookmarks.type AS type, " +
        "       bookmarks.is_deleted AS is_deleted, " +
        "       bookmarks.parentid AS parentid, bookmarks.parentName AS parentName, " +
        "       bookmarks.feedUri AS feedUri, bookmarks.siteUri AS siteUri, " +
        "       bookmarks.pos AS pos, title AS title, " +
        "       bookmarks.bmkUri AS bmkUri, bookmarks.folderName AS folderName, " +
        "       bookmarks.idx AS idx, bookmarks._parent AS _parent, " +
        "       bookmarks.isEditable AS isEditable, " +
        "       favicons.url AS iconURL, favicons.date AS iconDate, favicons.type AS iconType " +
        "FROM (\(fleshed)) AS bookmarks " +
        "LEFT OUTER JOIN favicons ON bookmarks.faviconID = favicons.id"

        let sql = (includeIcon ? withIcon : fleshed) + " ORDER BY idx ASC"
        return self.db.runQuery(sql, args: args, factory: BookmarkFactory.factory)
    }

    // This is only used from tests.
    func clearBookmarks() -> Success {
        log.warning("CALLING clearBookmarks -- this should only be used from tests.")
        return self.db.run([
            ("DELETE FROM \(TableBookmarksLocal) WHERE parentid IS NOT ?", [BookmarkRoots.RootGUID]),
            self.favicons.getCleanupCommands()
        ])
    }

    public func removeGUIDs(_ guids: [GUID]) -> Success {
        log.debug("removeGUIDs: \(guids)")

        // Override any parents that aren't already overridden. We're about to remove some
        // of their children.
        return self.overrideParentsOfGUIDs(guids)

        // Find, recursively, any children of the provided GUIDs. This will only be the case
        // if you specify folders. This is a special case because we're removing *all*
        // children, so we don't need to do the reindexing dance.
           >>> { self.deleteChildrenOfGUIDs(guids) }

        // Override any records that aren't already overridden.
           >>> { self.overrideGUIDs(guids) }

        // Then delete the already-overridden records. We do this one at a time in order
        // to get indices correct in edge cases. (We do bulk-delete their children
        // one layer at a time, at least.)
           >>> { walk(guids, f: self.removeLocalByGUID) }
    }

    fileprivate func nonDeletedGUIDsForURL(_ url: String) -> Deferred<Maybe<([GUID])>> {
        let sql = "SELECT DISTINCT guid FROM \(ViewBookmarksLocalOnMirror) WHERE bmkUri = ? AND is_deleted = 0"
        let args: Args = [url]

        return self.db.runQuery(sql, args: args, factory: { $0[0] as! GUID }) >>== { guids in
            return deferMaybe(guids.asArray())
        }
    }

    fileprivate func overrideParentsOfGUIDs(_ guids: [GUID]) -> Success {
        log.debug("Overriding parents of \(guids).")

        // TODO: Yes, this can be done in one go.
        let getParentsSQL =
        "SELECT DISTINCT parent FROM \(ViewBookmarksLocalStructureOnMirror) " +
        "WHERE child IN \(BrowserDB.varlist(guids.count)) AND is_overridden = 0"
        let getParentsArgs: Args = guids

        return self.db.runQuery(getParentsSQL, args: getParentsArgs, factory: { $0[0] as! GUID })
            >>== { parentsCursor in
                let parents = parentsCursor.asArray()
                log.debug("Overriding parents: \(parents).")
                let (sql, args) = self.getSQLToOverrideFolders(parents, atModifiedTime: Date.now())
                return self.db.run(sql.map { ($0, args) })
        }
    }

    fileprivate func overrideGUIDs(_ guids: [GUID]) -> Success {
        log.debug("Overriding GUIDs: \(guids).")
        let (sql, args) = self.getSQLToOverrideNonFolders(guids, atModifiedTime: Date.now())
        return self.db.run(sql.map { ($0, args) })
    }

    // Recursive.
    fileprivate func deleteChildrenOfGUIDs(_ guids: [GUID]) -> Success {
        if guids.isEmpty {
            return succeed()
        }

        precondition(BookmarkRoots.All.intersection(guids).isEmpty, "You can't even touch the roots for removal.")

        log.debug("Deleting children of \(guids).")

        let topArgs: Args = guids
        let topVarlist = BrowserDB.varlist(topArgs.count)
        let query =
        "SELECT child FROM \(ViewBookmarksLocalStructureOnMirror) " +
        "WHERE parent IN \(topVarlist)"

        // We're deleting whole folders, so we don't need to worry about indices.
        return self.db.runQuery(query, args: topArgs, factory: { $0[0] as! GUID })
            >>== { children in
                let childGUIDs = children.asArray()
                log.debug("… children of \(guids) are \(childGUIDs).")

                if childGUIDs.isEmpty {
                    log.debug("No children; nothing more to do.")
                    return succeed()
                }

                let childArgs: Args = childGUIDs
                let childVarlist = BrowserDB.varlist(childArgs.count)

                // Mirror the children if they're not already.
                // We use the non-folder version of this query because we're recursively
                // destroying structure right after this, so there's no point cloning the
                // mirror structure.
                // Then delete the children's children, so we don't leave orphans. This is
                // recursive, so by the time this succeeds we know that all of these records
                // have no remaining children.
                let (overrideSQL, overrideArgs) = self.getSQLToOverrideNonFolders(childGUIDs, atModifiedTime: Date.now())

                return self.deleteChildrenOfGUIDs(childGUIDs)
                    >>> { self.db.run(overrideSQL.map { ($0, overrideArgs) }) }
                    >>> {
                        // Delete the children themselves.

                        // Remove each child from structure. We use the top list to save effort.
                        let deleteStructure =
                        "DELETE FROM \(TableBookmarksLocalStructure) WHERE parent IN \(topVarlist)"

                        // If a bookmark is New, delete it outright.
                        let deleteNew =
                        "DELETE FROM \(TableBookmarksLocal) WHERE guid IN \(childVarlist) AND sync_status = \(SyncStatus.new.rawValue)"

                        // If a bookmark is Changed, mark it as deleted and bump its modified time.
                        let markChanged = self.getMarkDeletedSQLWithWhereFragment("guid IN \(childVarlist)")

                        return self.db.run([
                            (deleteStructure, topArgs),
                            (deleteNew, childArgs),
                            (markChanged, childArgs),
                        ])
                }
        }
    }

    fileprivate func getMarkDeletedSQLWithWhereFragment(_ whereFragment: String) -> String {
        let sql =
        "UPDATE \(TableBookmarksLocal) SET" +
        "  is_deleted = 1" +
        ", local_modified = \(Date.now())" +
        ", bmkUri = NULL" +
        ", feedUri = NULL" +
        ", siteUri = NULL" +
        ", pos = NULL" +
        ", title = NULL" +
        ", tags = NULL" +
        ", keyword = NULL" +
        ", description = NULL" +
        ", parentid = NULL" +
        ", parentName = NULL" +
        ", folderName = NULL" +
        ", queryId = NULL" +
        " WHERE \(whereFragment) AND sync_status = \(SyncStatus.changed.rawValue)"

        return sql
    }
    /**
     * This depends on the record's parent already being overridden if necessary.
     */
    fileprivate func removeLocalByGUID(_ guid: GUID) -> Success {
        let args: Args = [guid]

        // Find the index we're currently occupying.
        let previousIndexSubquery = "SELECT idx FROM \(TableBookmarksLocalStructure) WHERE child = ?"

        // Fix up the indices of subsequent siblings.
        let updateIndices =
        "UPDATE \(TableBookmarksLocalStructure) SET idx = (idx - 1) WHERE idx > (\(previousIndexSubquery))"

        // If the bookmark is New, delete it outright.
        let deleteNew =
        "DELETE FROM \(TableBookmarksLocal) WHERE guid = ? AND sync_status = \(SyncStatus.new.rawValue)"

        // If the bookmark is Changed, mark it as deleted and bump its modified time.
        let markChanged = self.getMarkDeletedSQLWithWhereFragment("guid = ?")

        // Its parent must be either New or Changed, so we don't need to re-mirror it.
        // TODO: bump the parent's modified time, because the child list changed?

        // Now delete from structure.
        let deleteStructure =
        "DELETE FROM \(TableBookmarksLocalStructure) WHERE child = ?"

        return self.db.run([
            (updateIndices, args),
            (deleteNew, args),
            (markChanged, args),
            (deleteStructure, args),
        ])
    }
}

class SQLiteBookmarkFolder: BookmarkFolder {
    fileprivate let cursor: Cursor<BookmarkNode>
    override var count: Int {
        return cursor.count
    }

    override subscript(index: Int) -> BookmarkNode {
        let bookmark = cursor[index]
        return bookmark! as BookmarkNode
    }

    init(guid: String, title: String, children: Cursor<BookmarkNode>) {
        self.cursor = children
        super.init(guid: guid, title: title)
    }

    override func removeItemWithGUID(_ guid: GUID) -> BookmarkFolder? {
        let without = cursor.asArray().filter { $0.guid != guid }
        return MemoryBookmarkFolder(guid: self.guid, title: self.title, children: without)
    }
}

class BookmarkFactory {
    fileprivate class func addIcon(_ bookmark: BookmarkNode, row: SDRow) {
        // TODO: share this logic with SQLiteHistory.
        if let faviconURL = row["iconURL"] as? String,
           let date = row["iconDate"] as? Double,
           let faviconType = row["iconType"] as? Int,
           let type = IconType(rawValue: faviconType) {
                bookmark.favicon = Favicon(url: faviconURL,
                                           date: Date(timeIntervalSince1970: date),
                                           type: type)
        }
    }

    fileprivate class func livemarkFactory(_ row: SDRow) -> BookmarkItem {
        let id = row["id"] as! Int
        let guid = row["guid"] as! String
        let url = row["siteUri"] as! String
        let title = row["title"] as? String ?? "Livemark"       // TODO
        let isEditable = row.getBoolean("isEditable")           // Defaults to false.
        let bookmark = BookmarkItem(guid: guid, title: title, url: url, isEditable: isEditable)
        bookmark.id = id
        BookmarkFactory.addIcon(bookmark, row: row)
        return bookmark
    }

    // We ignore queries altogether inside the model factory.
    fileprivate class func queryFactory(_ row: SDRow) -> BookmarkItem {
        log.warning("Creating a BookmarkItem from a query. This is almost certainly unexpected.")
        let id = row["id"] as! Int
        let guid = row["guid"] as! String
        let title = row["title"] as? String ?? SQLiteBookmarks.defaultItemTitle
        let isEditable = row.getBoolean("isEditable")           // Defaults to false.
        let bookmark = BookmarkItem(guid: guid, title: title, url: "about:blank", isEditable: isEditable)
        bookmark.id = id
        BookmarkFactory.addIcon(bookmark, row: row)
        return bookmark
    }

    fileprivate class func separatorFactory(_ row: SDRow) -> BookmarkSeparator {
        let id = row["id"] as! Int
        let guid = row["guid"] as! String
        let separator = BookmarkSeparator(guid: guid)
        separator.id = id
        return separator
    }

    fileprivate class func itemFactory(_ row: SDRow) -> BookmarkItem {
        let id = row["id"] as! Int
        let guid = row["guid"] as! String
        let url = row["bmkUri"] as! String
        let title = row["title"] as? String ?? url
        let isEditable = row.getBoolean("isEditable")           // Defaults to false.
        let bookmark = BookmarkItem(guid: guid, title: title, url: url, isEditable: isEditable)
        bookmark.id = id
        BookmarkFactory.addIcon(bookmark, row: row)
        return bookmark
    }

    fileprivate class func folderFactory(_ row: SDRow) -> BookmarkFolder {
        let id = row["id"] as! Int
        let guid = row["guid"] as! String
        let isEditable = row.getBoolean("isEditable")           // Defaults to false.
        let title = titleForSpecialGUID(guid) ??
                    row["title"] as? String ??
                    SQLiteBookmarks.defaultFolderTitle

        let folder = BookmarkFolder(guid: guid, title: title, isEditable: isEditable)
        folder.id = id
        BookmarkFactory.addIcon(folder, row: row)
        return folder
    }

    class func factory(_ row: SDRow) -> BookmarkNode {
        if let typeCode = row["type"] as? Int, let type = BookmarkNodeType(rawValue: typeCode) {
            switch type {
            case .bookmark:
                return itemFactory(row)
            case .dynamicContainer:
                // This should never be hit: we exclude dynamic containers from our models.
                fallthrough
            case .folder:
                return folderFactory(row)
            case .separator:
                return separatorFactory(row)
            case .livemark:
                return livemarkFactory(row)
            case .query:
                // This should never be hit: we exclude queries from our models.
                return queryFactory(row)
            }
        }
        assert(false, "Invalid bookmark data.")
        return itemFactory(row)     // This will fail, but it keeps the compiler happy.
    }

    // N.B., doesn't include children!
    class func mirrorItemFactory(_ row: SDRow) -> BookmarkMirrorItem {
        // TODO
        // let id = row["id"] as! Int

        let guid = row["guid"] as! GUID
        let typeCode = row["type"] as! Int
        let is_deleted = row.getBoolean("is_deleted")
        let parentid = row["parentid"] as? GUID
        let parentName = row["parentName"] as? String
        let feedUri = row["feedUri"] as? String
        let siteUri = row["siteUri"] as? String
        let pos = row["pos"] as? Int
        let title = row["title"] as? String
        let description = row["description"] as? String
        let bmkUri = row["bmkUri"] as? String
        let tags = row["tags"] as? String
        let keyword = row["keyword"] as? String
        let folderName = row["folderName"] as? String
        let queryId = row["queryId"] as? String

        // Local and mirror only.
        let faviconID = row["faviconID"] as? Int

        // Local only.
        let local_modified = row.getTimestamp("local_modified")

        // Mirror and buffer.
        let server_modified = row.getTimestamp("server_modified")
        let hasDupe = row.getBoolean("hasDupe")

        // Mirror only. TODO
        //let is_overridden = row.getBoolean("is_overridden")

        // Use the struct initializer directly. Yes, this doesn't validate as strongly as
        // using the static constructors, but it'll be as valid as the contents of the DB.
        let type = BookmarkNodeType(rawValue: typeCode)!

        // This one might really be missing (it's local-only), so do this the hard way.
        let syncStatus: SyncStatus?
        if let s = row["sync_status"] as? Int {
            syncStatus = SyncStatus(rawValue: s)
        } else {
            syncStatus = nil
        }
        let item = BookmarkMirrorItem(guid: guid, type: type, serverModified: server_modified ?? 0,
                                      isDeleted: is_deleted, hasDupe: hasDupe, parentID: parentid, parentName: parentName,
                                      feedURI: feedUri, siteURI: siteUri,
                                      pos: pos,
                                      title: title, description: description,
                                      bookmarkURI: bmkUri, tags: tags, keyword: keyword,
                                      folderName: folderName, queryID: queryId,
                                      children: nil,
                                      faviconID: faviconID, localModified: local_modified,
                                      syncStatus: syncStatus)
        return item
    }
}

extension SQLiteBookmarks: SearchableBookmarks {
    public func bookmarksByURL(_ url: URL) -> Deferred<Maybe<Cursor<BookmarkItem>>> {
        let inner =
        "SELECT id, type, guid, bmkUri, title, faviconID FROM \(TableBookmarksLocal) " +
        "WHERE " +
        "type = \(BookmarkNodeType.bookmark.rawValue) AND is_deleted IS NOT 1 AND bmkUri = ? " +
        "UNION ALL " +
        "SELECT id, type, guid, bmkUri, title, faviconID FROM \(TableBookmarksMirror) " +
        "WHERE " +
        "type = \(BookmarkNodeType.bookmark.rawValue) AND is_overridden IS NOT 1 AND is_deleted IS NOT 1 AND bmkUri = ? "

        let sql =
        "SELECT bookmarks.id AS id, bookmarks.type AS type, guid, bookmarks.bmkUri AS bmkUri, title, " +
        "favicons.url AS iconURL, favicons.date AS iconDate, favicons.type AS iconType " +
        "FROM (\(inner)) AS bookmarks " +
        "LEFT OUTER JOIN favicons ON bookmarks.faviconID = favicons.id"

        let u = url.absoluteString
        let args: Args = [u, u]
        return db.runQuery(sql, args: args, factory: BookmarkFactory.itemFactory)
    }
}

extension SQLiteBookmarks {
    // We're in sync (even partially) if the mirror is non-empty.
    // We can show fallback desktop bookmarks if the mirror is empty and the buffer contains
    // children of the roots.
    func hasOnlyUnmergedRemoteBookmarks() -> Deferred<Maybe<Bool>> {
        let parents: Args = [
            BookmarkRoots.MenuFolderGUID,
            BookmarkRoots.ToolbarFolderGUID,
            BookmarkRoots.UnfiledFolderGUID,
            BookmarkRoots.MobileFolderGUID,
        ]
        let sql = [
            "SELECT",
            "not exists(SELECT 1 FROM \(TableBookmarksMirror))",
            "AND",
            "exists(SELECT 1 FROM \(TableBookmarksBufferStructure) WHERE parent IN (?, ?, ?, ?))",
            ].joined(separator: " ")
        return self.db.runQuery(sql, args: parents, factory: { $0[0] as! Int == 1 })
            >>== { row in
                guard row.status == .success,
                    let result = row[0] else {
                        // if the query did not succeed, we should return false so that we can use local bookmarks
                        return deferMaybe(false)
                }
                return deferMaybe(result)
        }
    }
}

// It's a factory where the root contains Desktop Bookmarks from the buffer, and
// mobile bookmarks from local.
open class UnsyncedBookmarksFallbackModelFactory: BookmarksModelFactory {
    let localFactory: SQLiteBookmarksModelFactory
    let bufferFactory: SQLiteBookmarksModelFactory

    init(bookmarks: SQLiteBookmarks) {
        // This relies on SQLiteBookmarks being the storage for both directions.
        self.localFactory = SQLiteBookmarksModelFactory(bookmarks: bookmarks, direction: .local)
        self.bufferFactory = SQLiteBookmarksModelFactory(bookmarks: bookmarks, direction: .buffer)
    }

    open func modelForFolder(_ folder: BookmarkFolder) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(folder.guid, title: folder.title)
    }

    open func modelForFolder(_ guid: GUID) -> Deferred<Maybe<BookmarksModel>> {
        return self.modelForFolder(guid, title: "")
    }

    open func modelForFolder(_ guid: GUID, title: String) -> Deferred<Maybe<BookmarksModel>> {
        if guid == BookmarkRoots.MobileFolderGUID {
            return self.modelForRoot()
        }

        if guid == BookmarkRoots.FakeDesktopFolderGUID {
            return self.bufferFactory.modelForFolder(guid, title: title)
        }

        return self.localFactory.modelForFolder(guid, title: title)
    }

    open func modelForRoot() -> Deferred<Maybe<BookmarksModel>> {
        log.debug("Getting model for fallback root.")
        // Return a virtual model containing "Desktop bookmarks" prepended to the local mobile bookmarks.
        return self.localFactory.folderForGUID(BookmarkRoots.MobileFolderGUID, title: BookmarksFolderTitleMobile)
            >>== { folder in
            return self.bufferFactory.getDesktopRoots() >>== { cursor in
                let desktop = self.bufferFactory.folderForDesktopBookmarksCursor(cursor)
                let prepended = PrependedBookmarkFolder(main: folder, prepend: desktop)
                return deferMaybe(BookmarksModel(modelFactory: self, root: prepended))
            }
        }
    }

    // Whenever async construction is necessary, we fall into a pattern of needing
    // a placeholder that behaves correctly for the period between kickoff and set.
    open var nullModel: BookmarksModel {
        let children = Cursor<BookmarkNode>(status: .failure, msg: "Null model")
        let folder = SQLiteBookmarkFolder(guid: "Null", title: "Null", children: children)
        return BookmarksModel(modelFactory: self, root: folder)
    }

    open func isBookmarked(_ url: String) -> Deferred<Maybe<Bool>> {
        // We don't include buffer items in this check, because we can't un-star them!
        return self.localFactory.isBookmarked(url)
    }

    open func removeByGUID(_ guid: GUID) -> Success {
        return self.localFactory.removeByGUID(guid)
    }

    open func removeByURL(_ url: String) -> Success {
        return self.localFactory.removeByURL(url)
    }
}

open class MergedSQLiteBookmarks: BookmarksModelFactorySource, KeywordSearchSource {
    let local: SQLiteBookmarks
    let buffer: SQLiteBookmarkBufferStorage

    // Figuring out our factory can require hitting the DB, so this is async.
    // Note that we check *every time* -- we don't want to get stuck in a dead
    // end when you might sync soon.
    open var modelFactory: Deferred<Maybe<BookmarksModelFactory>> {
        return self.local.hasOnlyUnmergedRemoteBookmarks() >>== { yes in
            if yes {
                log.debug("Only unmerged remote bookmarks; using fallback factory.")
                return deferMaybe(UnsyncedBookmarksFallbackModelFactory(bookmarks: self.local))
            }
            log.debug("Using local+mirror bookmark factory.")
            return self.local.modelFactory
        }
    }

    public init(db: BrowserDB) {
        self.local = SQLiteBookmarks(db: db)
        self.buffer = SQLiteBookmarkBufferStorage(db: db)
    }

    open func getURLForKeywordSearch(_ keyword: String) -> Deferred<Maybe<String>> {
        return self.local.getURLForKeywordSearch(keyword)
    }
}
