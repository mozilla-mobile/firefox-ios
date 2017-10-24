/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

let BookmarksFolderTitleMobile: String = NSLocalizedString("Mobile Bookmarks", tableName: "Storage", comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.")
let BookmarksFolderTitleMenu: String = NSLocalizedString("Bookmarks Menu", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.")
let BookmarksFolderTitleToolbar: String = NSLocalizedString("Bookmarks Toolbar", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.")
let BookmarksFolderTitleUnsorted: String = NSLocalizedString("Unsorted Bookmarks", tableName: "Storage", comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.")

let _TableBookmarks = "bookmarks"                                      // Removed in v12. Kept for migration.
let TableBookmarksMirror = "bookmarksMirror"                           // Added in v9.
let TableBookmarksMirrorStructure = "bookmarksMirrorStructure"         // Added in v10.

let TableBookmarksBuffer = "bookmarksBuffer"                           // Added in v12. bookmarksMirror is renamed to bookmarksBuffer.
let TableBookmarksBufferStructure = "bookmarksBufferStructure"         // Added in v12.
let TableBookmarksLocal = "bookmarksLocal"                             // Added in v12. Supersedes 'bookmarks'.
let TableBookmarksLocalStructure = "bookmarksLocalStructure"           // Added in v12.

let TablePendingBookmarksDeletions = "pending_deletions"               // Added in v28.

let TableFavicons = "favicons"
let TableHistory = "history"
let TableCachedTopSites = "cached_top_sites"
let TablePinnedTopSites = "pinned_top_sites"
let TableDomains = "domains"
let TableVisits = "visits"
let TableFaviconSites = "favicon_sites"
let TableQueuedTabs = "queue"
let TableSyncCommands = "commands"
let TableClients = "clients"
let TableTabs = "tabs"

let TableActivityStreamBlocklist = "activity_stream_blocklist"
let TablePageMetadata = "page_metadata"
let TableHighlights = "highlights"

let TableRemoteDevices = "remote_devices" // Added in v29.

let ViewBookmarksBufferOnMirror = "view_bookmarksBuffer_on_mirror"
let ViewBookmarksBufferWithDeletionsOnMirror = "view_bookmarksBuffer_with_deletions_on_mirror"
let ViewBookmarksBufferStructureOnMirror = "view_bookmarksBufferStructure_on_mirror"
let ViewBookmarksLocalOnMirror = "view_bookmarksLocal_on_mirror"
let ViewBookmarksLocalStructureOnMirror = "view_bookmarksLocalStructure_on_mirror"
let ViewAllBookmarks = "view_all_bookmarks"
let ViewAwesomebarBookmarks = "view_awesomebar_bookmarks"
let ViewAwesomebarBookmarksWithIcons = "view_awesomebar_bookmarks_with_favicons"

let ViewHistoryVisits = "view_history_visits"
let ViewWidestFaviconsForSites = "view_favicons_widest"
let ViewHistoryIDsWithWidestFavicons = "view_history_id_favicon"
let ViewIconForURL = "view_icon_for_url"

let IndexHistoryShouldUpload = "idx_history_should_upload"
let IndexVisitsSiteIDDate = "idx_visits_siteID_date"                   // Removed in v6.
let IndexVisitsSiteIDIsLocalDate = "idx_visits_siteID_is_local_date"   // Added in v6.
let IndexBookmarksMirrorStructureParentIdx = "idx_bookmarksMirrorStructure_parent_idx"   // Added in v10.
let IndexBookmarksLocalStructureParentIdx = "idx_bookmarksLocalStructure_parent_idx"     // Added in v12.
let IndexBookmarksBufferStructureParentIdx = "idx_bookmarksBufferStructure_parent_idx"   // Added in v12.
let IndexBookmarksMirrorStructureChild = "idx_bookmarksMirrorStructure_child"            // Added in v14.
let IndexPageMetadataCacheKey = "idx_page_metadata_cache_key_uniqueindex" // Added in v19
let IndexPageMetadataSiteURL = "idx_page_metadata_site_url_uniqueindex" // Added in v21

private let AllTables: [String] = [
    TableDomains,
    TableFavicons,
    TableFaviconSites,

    TableHistory,
    TableVisits,
    TableCachedTopSites,

    TableBookmarksBuffer,
    TableBookmarksBufferStructure,
    TableBookmarksLocal,
    TableBookmarksLocalStructure,
    TableBookmarksMirror,
    TableBookmarksMirrorStructure,
    TablePendingBookmarksDeletions,
    TableQueuedTabs,

    TableActivityStreamBlocklist,
    TablePageMetadata,
    TableHighlights,
    TablePinnedTopSites,
    TableRemoteDevices,

    TableSyncCommands,
    TableClients,
    TableTabs,
]

private let AllViews: [String] = [
    ViewHistoryIDsWithWidestFavicons,
    ViewWidestFaviconsForSites,
    ViewIconForURL,
    ViewBookmarksBufferOnMirror,
    ViewBookmarksBufferWithDeletionsOnMirror,
    ViewBookmarksBufferStructureOnMirror,
    ViewBookmarksLocalOnMirror,
    ViewBookmarksLocalStructureOnMirror,
    ViewAllBookmarks,
    ViewAwesomebarBookmarks,
    ViewAwesomebarBookmarksWithIcons,
    ViewHistoryVisits,
]

private let AllIndices: [String] = [
    IndexHistoryShouldUpload,
    IndexVisitsSiteIDIsLocalDate,
    IndexBookmarksBufferStructureParentIdx,
    IndexBookmarksLocalStructureParentIdx,
    IndexBookmarksMirrorStructureParentIdx,
    IndexBookmarksMirrorStructureChild,
    IndexPageMetadataCacheKey,
    IndexPageMetadataSiteURL,
]

private let AllTablesIndicesAndViews: [String] = AllViews + AllIndices + AllTables

private let log = Logger.syncLogger

/**
 * The monolithic class that manages the inter-related history etc. tables.
 * We rely on SQLiteHistory having initialized the favicon table first.
 */
open class BrowserSchema: Schema {
    static let DefaultVersion = 34    // Bug 1409777.

    public var name: String { return "BROWSER" }
    public var version: Int { return BrowserSchema.DefaultVersion }

    let sqliteVersion: Int32
    let supportsPartialIndices: Bool

    public init() {
        let v = sqlite3_libversion_number()
        self.sqliteVersion = v
        self.supportsPartialIndices = v >= 3008000          // 3.8.0.
        let ver = String(cString: sqlite3_libversion())
        log.info("SQLite version: \(ver) (\(v)).")
    }

    func run(_ db: SQLiteDBConnection, sql: String, args: Args? = nil) -> Bool {
        do {
            try db.executeChange(sql, withArgs: args)
        } catch let err as NSError {
            log.error("Error running SQL in BrowserSchema: \(err.localizedDescription)")
            log.error("SQL was \(sql)")
            return false
        }

        return true
    }

    // TODO: transaction.
    func run(_ db: SQLiteDBConnection, queries: [(String, Args?)]) -> Bool {
        for (sql, args) in queries {
            if !run(db, sql: sql, args: args) {
                return false
            }
        }
        return true
    }

    func run(_ db: SQLiteDBConnection, queries: [String]) -> Bool {
        for sql in queries {
            if !run(db, sql: sql) {
                return false
            }
        }
        return true
    }

    func runValidQueries(_ db: SQLiteDBConnection, queries: [(String?, Args?)]) -> Bool {
        for (sql, args) in queries {
            if let sql = sql {
                if !run(db, sql: sql, args: args) {
                    return false
                }
            }
        }
        return true
    }

    func runValidQueries(_ db: SQLiteDBConnection, queries: [String?]) -> Bool {
        return self.run(db, queries: optFilter(queries))
    }

    func prepopulateRootFolders(_ db: SQLiteDBConnection) -> Bool {
        let type = BookmarkNodeType.folder.rawValue
        let now = Date.nowNumber()
        let status = SyncStatus.new.rawValue

        let localArgs: Args = [
            BookmarkRoots.RootID, BookmarkRoots.RootGUID, type, now, BookmarkRoots.RootGUID, status, now,
            BookmarkRoots.MobileID, BookmarkRoots.MobileFolderGUID, type, now, BookmarkRoots.RootGUID, status, now,
            BookmarkRoots.MenuID, BookmarkRoots.MenuFolderGUID, type, now, BookmarkRoots.RootGUID, status, now,
            BookmarkRoots.ToolbarID, BookmarkRoots.ToolbarFolderGUID, type, now, BookmarkRoots.RootGUID, status, now,
            BookmarkRoots.UnfiledID, BookmarkRoots.UnfiledFolderGUID, type, now, BookmarkRoots.RootGUID, status, now,
        ]

        // Compute these args using the sequence in RootChildren, rather than hard-coding.
        var idx = 0
        var structureArgs = Args()
        structureArgs.reserveCapacity(BookmarkRoots.RootChildren.count * 3)
        BookmarkRoots.RootChildren.forEach { guid in
            structureArgs.append(BookmarkRoots.RootGUID)
            structureArgs.append(guid)
            structureArgs.append(idx)
            idx += 1
        }

        // Note that we specify an empty title and parentName for these records. We should
        // never need a parentName -- we don't use content-based reconciling or
        // reparent these -- and we'll use the current locale's string, retrieved
        // via titleForSpecialGUID, if necessary.

        let local =
        "INSERT INTO \(TableBookmarksLocal) " +
        "(id, guid, type, date_added, parentid, title, parentName, sync_status, local_modified) VALUES " +
        Array(repeating: "(?, ?, ?, ?, ?, '', '', ?, ?)", count: BookmarkRoots.RootChildren.count + 1).joined(separator: ", ")

        let structure =
        "INSERT INTO \(TableBookmarksLocalStructure) (parent, child, idx) VALUES " +
        Array(repeating: "(?, ?, ?)", count: BookmarkRoots.RootChildren.count).joined(separator: ", ")

        return self.run(db, queries: [(local, localArgs), (structure, structureArgs)])
    }

    let topSitesTableCreate =
        "CREATE TABLE IF NOT EXISTS \(TableCachedTopSites) (" +
            "historyID INTEGER, " +
            "url TEXT NOT NULL, " +
            "title TEXT NOT NULL, " +
            "guid TEXT NOT NULL UNIQUE, " +
            "domain_id INTEGER, " +
            "domain TEXT NO NULL, " +
            "localVisitDate REAL, " +
            "remoteVisitDate REAL, " +
            "localVisitCount INTEGER, " +
            "remoteVisitCount INTEGER, " +
            "iconID INTEGER, " +
            "iconURL TEXT, " +
            "iconDate REAL, " +
            "iconType INTEGER, " +
            "iconWidth INTEGER, " +
            "frecencies REAL" +
        ")"

    let pinnedTopSitesTableCreate =
        "CREATE TABLE IF NOT EXISTS \(TablePinnedTopSites) (" +
            "historyID INTEGER, " +
            "url TEXT NOT NULL UNIQUE, " +
            "title TEXT, " +
            "guid TEXT, " +
            "pinDate REAL, " +
            "domain TEXT NOT NULL " +
        ")"

    let domainsTableCreate =
        "CREATE TABLE IF NOT EXISTS \(TableDomains) (" +
           "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
           "domain TEXT NOT NULL UNIQUE, " +
           "showOnTopSites TINYINT NOT NULL DEFAULT 1" +
       ")"

    let queueTableCreate =
        "CREATE TABLE IF NOT EXISTS \(TableQueuedTabs) (" +
            "url TEXT NOT NULL UNIQUE, " +
            "title TEXT" +
        ") "

    let syncCommandsTableCreate =
        "CREATE TABLE IF NOT EXISTS \(TableSyncCommands) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "client_guid TEXT NOT NULL, " +
            "value TEXT NOT NULL" +
        ")"

    let clientsTableCreate =
        "CREATE TABLE IF NOT EXISTS \(TableClients) (" +
            "guid TEXT PRIMARY KEY, " +
            "name TEXT NOT NULL, " +
            "modified INTEGER NOT NULL, " +
            "type TEXT, " +
            "formfactor TEXT, " +
            "os TEXT, " +
            "version TEXT, " +
            "fxaDeviceId TEXT" +
        ")"

    let tabsTableCreate =
        "CREATE TABLE IF NOT EXISTS \(TableTabs) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "client_guid TEXT REFERENCES clients(guid) ON DELETE CASCADE, " +
            "url TEXT NOT NULL, " +
            "title TEXT, " +
            "history TEXT, " +
            "last_used INTEGER" +
        ")"

    let activityStreamBlocklistCreate =
        "CREATE TABLE IF NOT EXISTS \(TableActivityStreamBlocklist) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "url TEXT NOT NULL UNIQUE, " +
            "created_at DATETIME DEFAULT CURRENT_TIMESTAMP " +
        ") "

    let pageMetadataCreate =
        "CREATE TABLE IF NOT EXISTS \(TablePageMetadata) (" +
            "id INTEGER PRIMARY KEY, " +
            "cache_key LONGVARCHAR UNIQUE, " +
            "site_url TEXT, " +
            "media_url LONGVARCHAR, " +
            "title TEXT, " +
            "type VARCHAR(32), " +
            "description TEXT, " +
            "provider_name TEXT, " +
            "created_at DATETIME DEFAULT CURRENT_TIMESTAMP, " +
            "expired_at LONG" +
    ") "

    let highlightsCreate =
        "CREATE TABLE IF NOT EXISTS \(TableHighlights) (" +
            "historyID INTEGER PRIMARY KEY," +
            "cache_key LONGVARCHAR," +
            "url TEXT," +
            "title TEXT," +
            "guid TEXT," +
            "visitCount INTEGER," +
            "visitDate DATETIME," +
            "is_bookmarked INTEGER" +
    ") "

    let indexPageMetadataCacheKeyCreate =
    "CREATE UNIQUE INDEX IF NOT EXISTS \(IndexPageMetadataCacheKey) ON page_metadata (cache_key)"

    let indexPageMetadataSiteURLCreate =
    "CREATE UNIQUE INDEX IF NOT EXISTS \(IndexPageMetadataSiteURL) ON page_metadata (site_url)"

    let iconColumns = ", faviconID INTEGER REFERENCES \(TableFavicons)(id) ON DELETE SET NULL"
    let mirrorColumns = ", is_overridden TINYINT NOT NULL DEFAULT 0"

    let serverColumns = ", server_modified INTEGER NOT NULL" +    // Milliseconds.
                        ", hasDupe TINYINT NOT NULL DEFAULT 0"    // Boolean, 0 (false) if deleted.

    let localColumns = ", local_modified INTEGER" +            // Can be null. Client clock. In extremis only.
                       ", sync_status TINYINT NOT NULL"        // SyncStatus enum. Set when changed or created.

    func getBookmarksTableCreationStringForTable(_ table: String, withAdditionalColumns: String="") -> String {
        // The stupid absence of naming conventions here is thanks to pre-Sync Weave. Sorry.
        // For now we have the simplest possible schema: everything in one.
        let sql =
        "CREATE TABLE IF NOT EXISTS \(table) " +

        // Shared fields.
        "( id INTEGER PRIMARY KEY AUTOINCREMENT" +
        ", guid TEXT NOT NULL UNIQUE" +
        ", type TINYINT NOT NULL" +                    // Type enum.
        ", date_added INTEGER" +

        // Record/envelope metadata that'll allow us to do merges.
        ", is_deleted TINYINT NOT NULL DEFAULT 0" +    // Boolean

        ", parentid TEXT" +                            // GUID
        ", parentName TEXT" +

        // Type-specific fields. These should be NOT NULL in many cases, but we're going
        // for a sparse schema, so this'll do for now. Enforce these in the application code.
        ", feedUri TEXT, siteUri TEXT" +               // LIVEMARKS
        ", pos INT" +                                  // SEPARATORS
        ", title TEXT, description TEXT" +             // FOLDERS, BOOKMARKS, QUERIES
        ", bmkUri TEXT, tags TEXT, keyword TEXT" +     // BOOKMARKS, QUERIES
        ", folderName TEXT, queryId TEXT" +            // QUERIES
        withAdditionalColumns +
        ", CONSTRAINT parentidOrDeleted CHECK (parentid IS NOT NULL OR is_deleted = 1)" +
        ", CONSTRAINT parentNameOrDeleted CHECK (parentName IS NOT NULL OR is_deleted = 1)" +
        ")"

        return sql
    }

    /**
     * We need to explicitly store what's provided by the server, because we can't rely on
     * referenced child nodes to exist yet!
     */
    func getBookmarksStructureTableCreationStringForTable(_ table: String, referencingMirror mirror: String) -> String {
        let sql =
        "CREATE TABLE IF NOT EXISTS \(table) " +
        "( parent TEXT NOT NULL REFERENCES \(mirror)(guid) ON DELETE CASCADE" +
        ", child TEXT NOT NULL" +      // Should be the GUID of a child.
        ", idx INTEGER NOT NULL" +     // Should advance from 0.
        ")"

        return sql
    }

    fileprivate let bufferBookmarksView =
    "CREATE VIEW \(ViewBookmarksBufferOnMirror) AS " +
    "SELECT" +
    "  -1 AS id" +
    ", mirror.guid AS guid" +
    ", mirror.type AS type" +
    ", mirror.date_added AS date_added" +
    ", mirror.is_deleted AS is_deleted" +
    ", mirror.parentid AS parentid" +
    ", mirror.parentName AS parentName" +
    ", mirror.feedUri AS feedUri" +
    ", mirror.siteUri AS siteUri" +
    ", mirror.pos AS pos" +
    ", mirror.title AS title" +
    ", mirror.description AS description" +
    ", mirror.bmkUri AS bmkUri" +
    ", mirror.keyword AS keyword" +
    ", mirror.folderName AS folderName" +
    ", null AS faviconID" +
    ", 0 AS is_overridden" +

    // LEFT EXCLUDING JOIN to get mirror records that aren't in the buffer.
    // We don't have an is_overridden flag to help us here.
    " FROM \(TableBookmarksMirror) mirror LEFT JOIN" +
    " \(TableBookmarksBuffer) buffer ON mirror.guid = buffer.guid" +
    " WHERE buffer.guid IS NULL" +
    " UNION ALL " +
    "SELECT" +
    "  -1 AS id" +
    ", guid" +
    ", type" +
    ", date_added" +
    ", is_deleted" +
    ", parentid" +
    ", parentName" +
    ", feedUri" +
    ", siteUri" +
    ", pos" +
    ", title" +
    ", description" +
    ", bmkUri" +
    ", keyword" +
    ", folderName" +
    ", null AS faviconID" +
    ", 1 AS is_overridden" +
    " FROM \(TableBookmarksBuffer) WHERE is_deleted IS 0"

    fileprivate let bufferBookmarksWithDeletionsView =
    "CREATE VIEW \(ViewBookmarksBufferWithDeletionsOnMirror) AS " +
    "SELECT" +
    "  -1 AS id" +
    ", mirror.guid AS guid" +
    ", mirror.type AS type" +
    ", mirror.date_added AS date_added" +
    ", mirror.is_deleted AS is_deleted" +
    ", mirror.parentid AS parentid" +
    ", mirror.parentName AS parentName" +
    ", mirror.feedUri AS feedUri" +
    ", mirror.siteUri AS siteUri" +
    ", mirror.pos AS pos" +
    ", mirror.title AS title" +
    ", mirror.description AS description" +
    ", mirror.bmkUri AS bmkUri" +
    ", mirror.keyword AS keyword" +
    ", mirror.folderName AS folderName" +
    ", null AS faviconID" +
    ", 0 AS is_overridden" +

    // LEFT EXCLUDING JOIN to get mirror records that aren't in the buffer.
    // We don't have an is_overridden flag to help us here.
    " FROM \(TableBookmarksMirror) mirror LEFT JOIN" +
    " \(TableBookmarksBuffer) buffer ON mirror.guid = buffer.guid" +
    " WHERE buffer.guid IS NULL" +
    " UNION ALL " +
    "SELECT" +
    "  -1 AS id" +
    ", guid" +
    ", type" +
    ", date_added" +
    ", is_deleted" +
    ", parentid" +
    ", parentName" +
    ", feedUri" +
    ", siteUri" +
    ", pos" +
    ", title" +
    ", description" +
    ", bmkUri" +
    ", keyword" +
    ", folderName" +
    ", null AS faviconID" +
    ", 1 AS is_overridden" +
    " FROM \(TableBookmarksBuffer) WHERE is_deleted IS 0" +
    " AND NOT EXISTS (SELECT 1 FROM \(TablePendingBookmarksDeletions) deletions WHERE deletions.id = guid)"

    // TODO: phrase this without the subselect…
    fileprivate let bufferBookmarksStructureView =
    // We don't need to exclude deleted parents, because we drop those from the structure
    // table when we see them.
    "CREATE VIEW \(ViewBookmarksBufferStructureOnMirror) AS " +
    "SELECT parent, child, idx, 1 AS is_overridden FROM \(TableBookmarksBufferStructure) " +
    "UNION ALL " +

    // Exclude anything from the mirror that's present in the buffer -- dynamic is_overridden.
    "SELECT parent, child, idx, 0 AS is_overridden FROM \(TableBookmarksMirrorStructure) " +
    "LEFT JOIN \(TableBookmarksBuffer) ON parent = guid WHERE guid IS NULL"

    fileprivate let localBookmarksView =
    "CREATE VIEW \(ViewBookmarksLocalOnMirror) AS " +
    "SELECT -1 AS id, guid, type, date_added, is_deleted, parentid, parentName, feedUri," +
    "   siteUri, pos, title, description, bmkUri, folderName, faviconID, NULL AS local_modified, server_modified, 0 AS is_overridden " +
    "FROM \(TableBookmarksMirror) WHERE is_overridden IS NOT 1 " +
    "UNION ALL " +
    "SELECT -1 AS id, guid, type, date_added, is_deleted, parentid, parentName, feedUri, siteUri, pos, title, description, bmkUri, folderName, faviconID," +
    "   local_modified, NULL AS server_modified, 1 AS is_overridden " +
    "FROM \(TableBookmarksLocal) WHERE is_deleted IS NOT 1"

    // TODO: phrase this without the subselect…
    fileprivate let localBookmarksStructureView =
    "CREATE VIEW \(ViewBookmarksLocalStructureOnMirror) AS " +
    "SELECT parent, child, idx, 1 AS is_overridden FROM \(TableBookmarksLocalStructure) " +
    "WHERE " +
    "((SELECT is_deleted FROM \(TableBookmarksLocal) WHERE guid = parent) IS NOT 1) " +
    "UNION ALL " +
    "SELECT parent, child, idx, 0 AS is_overridden FROM \(TableBookmarksMirrorStructure) " +
    "WHERE " +
    "((SELECT is_overridden FROM \(TableBookmarksMirror) WHERE guid = parent) IS NOT 1) "

    // This view exists only to allow for text searching of URLs and titles in the awesomebar.
    // As such, we cheat a little: we include buffer, non-overridden mirror, and local.
    // Usually this will be indistinguishable from a more sophisticated approach, and it's way
    // easier.
    fileprivate let allBookmarksView =
    "CREATE VIEW \(ViewAllBookmarks) AS " +
    "SELECT guid, bmkUri AS url, title, description, faviconID FROM " +
    "\(TableBookmarksMirror) WHERE " +
    "type = \(BookmarkNodeType.bookmark.rawValue) AND is_overridden IS 0 AND is_deleted IS 0 " +
    "UNION ALL " +
    "SELECT guid, bmkUri AS url, title, description, faviconID FROM " +
    "\(TableBookmarksLocal) WHERE " +
    "type = \(BookmarkNodeType.bookmark.rawValue) AND is_deleted IS 0 " +
    "UNION ALL " +
    "SELECT guid, bmkUri AS url, title, description, -1 AS faviconID FROM " +
    "\(TableBookmarksBuffer) bb WHERE " +
    "bb.type = \(BookmarkNodeType.bookmark.rawValue) AND bb.is_deleted IS 0 " +

    // Exclude pending bookmark deletions.
    "AND NOT EXISTS (SELECT 1 FROM \(TablePendingBookmarksDeletions) AS pd WHERE pd.id = bb.guid)"

    // This exists only to allow upgrade from old versions. We have view dependencies, so
    // we can't simply skip creating ViewAllBookmarks. Here's a stub.
    fileprivate let oldAllBookmarksView =
        "CREATE VIEW \(ViewAllBookmarks) AS " +
            "SELECT guid, bmkUri AS url, title, description, faviconID FROM " +
            "\(TableBookmarksMirror) WHERE " +
            "type = \(BookmarkNodeType.bookmark.rawValue) AND is_overridden IS 0 AND is_deleted IS 0"

    // This smushes together remote and local visits. So it goes.
    fileprivate let historyVisitsView =
    "CREATE VIEW \(ViewHistoryVisits) AS " +
    "SELECT h.url AS url, MAX(v.date) AS visitDate, h.domain_id AS domain_id FROM " +
    "\(TableHistory) h JOIN \(TableVisits) v ON v.siteID = h.id " +
    "GROUP BY h.id"

    // Join all bookmarks against history to find the most recent visit.
    // visits.
    fileprivate let awesomebarBookmarksView =
    "CREATE VIEW \(ViewAwesomebarBookmarks) AS " +
    "SELECT b.guid AS guid, b.url AS url, b.title AS title, " +
    "b.description AS description, b.faviconID AS faviconID, " +
    "h.visitDate AS visitDate " +
    "FROM \(ViewAllBookmarks) b " +
    "LEFT JOIN " +
    "\(ViewHistoryVisits) h ON b.url = h.url"

    fileprivate let awesomebarBookmarksWithIconsView =
    "CREATE VIEW \(ViewAwesomebarBookmarksWithIcons) AS " +
    "SELECT b.guid AS guid, b.url AS url, b.title AS title, " +
    "b.description AS description, b.visitDate AS visitDate, " +
    "f.id AS iconID, f.url AS iconURL, f.date AS iconDate, " +
    "f.type AS iconType, f.width AS iconWidth " +
    "FROM \(ViewAwesomebarBookmarks) b " +
    "LEFT JOIN " +
    "\(TableFavicons) f ON f.id = b.faviconID"

    fileprivate let pendingBookmarksDeletions =
    "CREATE TABLE IF NOT EXISTS \(TablePendingBookmarksDeletions) (" +
    "id TEXT PRIMARY KEY REFERENCES \(TableBookmarksBuffer)(guid) ON DELETE CASCADE" +
    ")"

    fileprivate let remoteDevices =
    "CREATE TABLE IF NOT EXISTS \(TableRemoteDevices) (" +
    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
    "guid TEXT UNIQUE NOT NULL, " +
    "name TEXT NOT NULL, " +
    "type TEXT NOT NULL, " +
    "is_current_device INTEGER NOT NULL, " +
    "date_created INTEGER NOT NULL, " + // Timestamps in ms.
    "date_modified INTEGER NOT NULL, " +
    "last_access_time INTEGER" +
    ")"

    public func create(_ db: SQLiteDBConnection) -> Bool {
        let favicons =
        "CREATE TABLE IF NOT EXISTS \(TableFavicons) (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "url TEXT NOT NULL UNIQUE, " +
        "width INTEGER, " +
        "height INTEGER, " +
        "type INTEGER NOT NULL, " +
        "date REAL NOT NULL" +
        ") "

        let history =
        "CREATE TABLE IF NOT EXISTS \(TableHistory) (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "guid TEXT NOT NULL UNIQUE, " +       // Not null, but the value might be replaced by the server's.
        "url TEXT UNIQUE, " +                 // May only be null for deleted records.
        "title TEXT NOT NULL, " +
        "server_modified INTEGER, " +         // Can be null. Integer milliseconds.
        "local_modified INTEGER, " +          // Can be null. Client clock. In extremis only.
        "is_deleted TINYINT NOT NULL, " +     // Boolean. Locally deleted.
        "should_upload TINYINT NOT NULL, " +  // Boolean. Set when changed or visits added.
        "domain_id INTEGER REFERENCES \(TableDomains)(id) ON DELETE CASCADE, " +
        "CONSTRAINT urlOrDeleted CHECK (url IS NOT NULL OR is_deleted = 1)" +
        ")"

        // Right now we don't need to track per-visit deletions: Sync can't
        // represent them! See Bug 1157553 Comment 6.
        // We flip the should_upload flag on the history item when we add a visit.
        // If we ever want to support logic like not bothering to sync if we added
        // and then rapidly removed a visit, then we need an 'is_new' flag on each visit.
        let visits =
        "CREATE TABLE IF NOT EXISTS \(TableVisits) (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "siteID INTEGER NOT NULL REFERENCES \(TableHistory)(id) ON DELETE CASCADE, " +
        "date REAL NOT NULL, " +           // Microseconds since epoch.
        "type INTEGER NOT NULL, " +
        "is_local TINYINT NOT NULL, " +    // Some visits are local. Some are remote ('mirrored'). This boolean flag is the split.
        "UNIQUE (siteID, date, type) " +
        ") "

        let indexShouldUpload: String
        if self.supportsPartialIndices {
            // There's no point tracking rows that are not flagged for upload.
            indexShouldUpload =
            "CREATE INDEX IF NOT EXISTS \(IndexHistoryShouldUpload) " +
            "ON \(TableHistory) (should_upload) WHERE should_upload = 1"
        } else {
            indexShouldUpload =
            "CREATE INDEX IF NOT EXISTS \(IndexHistoryShouldUpload) " +
            "ON \(TableHistory) (should_upload)"
        }

        let indexSiteIDDate =
        "CREATE INDEX IF NOT EXISTS \(IndexVisitsSiteIDIsLocalDate) " +
        "ON \(TableVisits) (siteID, is_local, date)"

        let faviconSites =
        "CREATE TABLE IF NOT EXISTS \(TableFaviconSites) (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "siteID INTEGER NOT NULL REFERENCES \(TableHistory)(id) ON DELETE CASCADE, " +
        "faviconID INTEGER NOT NULL REFERENCES \(TableFavicons)(id) ON DELETE CASCADE, " +
        "UNIQUE (siteID, faviconID) " +
        ") "

        let widestFavicons =
        "CREATE VIEW IF NOT EXISTS \(ViewWidestFaviconsForSites) AS " +
        "SELECT " +
        "\(TableFaviconSites).siteID AS siteID, " +
        "\(TableFavicons).id AS iconID, " +
        "\(TableFavicons).url AS iconURL, " +
        "\(TableFavicons).date AS iconDate, " +
        "\(TableFavicons).type AS iconType, " +
        "MAX(\(TableFavicons).width) AS iconWidth " +
        "FROM \(TableFaviconSites), \(TableFavicons) WHERE " +
        "\(TableFaviconSites).faviconID = \(TableFavicons).id " +
        "GROUP BY siteID "

        let historyIDsWithIcon =
        "CREATE VIEW IF NOT EXISTS \(ViewHistoryIDsWithWidestFavicons) AS " +
        "SELECT \(TableHistory).id AS id, " +
        "iconID, iconURL, iconDate, iconType, iconWidth " +
        "FROM \(TableHistory) " +
        "LEFT OUTER JOIN " +
        "\(ViewWidestFaviconsForSites) ON history.id = \(ViewWidestFaviconsForSites).siteID "

        let iconForURL =
        "CREATE VIEW IF NOT EXISTS \(ViewIconForURL) AS " +
        "SELECT history.url AS url, icons.iconID AS iconID FROM " +
        "\(TableHistory), \(ViewWidestFaviconsForSites) AS icons WHERE " +
        "\(TableHistory).id = icons.siteID "

        // Locally we track faviconID.
        // Local changes end up in the mirror, so we track it there too.
        // The buffer and the mirror additionally track some server metadata.
        let bookmarksLocal = getBookmarksTableCreationStringForTable(TableBookmarksLocal, withAdditionalColumns: self.localColumns + self.iconColumns)
        let bookmarksLocalStructure = getBookmarksStructureTableCreationStringForTable(TableBookmarksLocalStructure, referencingMirror: TableBookmarksLocal)
        let bookmarksBuffer = getBookmarksTableCreationStringForTable(TableBookmarksBuffer, withAdditionalColumns: self.serverColumns)
        let bookmarksBufferStructure = getBookmarksStructureTableCreationStringForTable(TableBookmarksBufferStructure, referencingMirror: TableBookmarksBuffer)
        let bookmarksMirror = getBookmarksTableCreationStringForTable(TableBookmarksMirror, withAdditionalColumns: self.serverColumns + self.mirrorColumns + self.iconColumns)
        let bookmarksMirrorStructure = getBookmarksStructureTableCreationStringForTable(TableBookmarksMirrorStructure, referencingMirror: TableBookmarksMirror)

        let indexLocalStructureParentIdx = "CREATE INDEX IF NOT EXISTS \(IndexBookmarksLocalStructureParentIdx) " +
            "ON \(TableBookmarksLocalStructure) (parent, idx)"
        let indexBufferStructureParentIdx = "CREATE INDEX IF NOT EXISTS \(IndexBookmarksBufferStructureParentIdx) " +
            "ON \(TableBookmarksBufferStructure) (parent, idx)"
        let indexMirrorStructureParentIdx = "CREATE INDEX IF NOT EXISTS \(IndexBookmarksMirrorStructureParentIdx) " +
            "ON \(TableBookmarksMirrorStructure) (parent, idx)"
        let indexMirrorStructureChild = "CREATE INDEX IF NOT EXISTS \(IndexBookmarksMirrorStructureChild) " +
            "ON \(TableBookmarksMirrorStructure) (child)"

        let queries: [String] = [
            // Tables.
            self.domainsTableCreate,
            history,
            favicons,
            visits,
            bookmarksBuffer,
            bookmarksBufferStructure,
            bookmarksLocal,
            bookmarksLocalStructure,
            bookmarksMirror,
            bookmarksMirrorStructure,
            self.pendingBookmarksDeletions,
            faviconSites,
            widestFavicons,
            historyIDsWithIcon,
            iconForURL,
            pageMetadataCreate,
            pinnedTopSitesTableCreate,
            highlightsCreate,
            self.remoteDevices,
            activityStreamBlocklistCreate,
            indexPageMetadataSiteURLCreate,
            indexPageMetadataCacheKeyCreate,
            self.queueTableCreate,
            self.topSitesTableCreate,
            syncCommandsTableCreate,
            clientsTableCreate,
            tabsTableCreate,

            // Indices.
            indexBufferStructureParentIdx,
            indexLocalStructureParentIdx,
            indexMirrorStructureParentIdx,
            indexMirrorStructureChild,
            indexShouldUpload,
            indexSiteIDDate,

            // Views.
            self.localBookmarksView,
            self.localBookmarksStructureView,
            self.bufferBookmarksView,
            self.bufferBookmarksWithDeletionsView,
            self.bufferBookmarksStructureView,
            allBookmarksView,
            historyVisitsView,
            awesomebarBookmarksView,
            awesomebarBookmarksWithIconsView,
        ]

        assert(queries.count == AllTablesIndicesAndViews.count, "Did you forget to add your table, index, or view to the list?")

        log.debug("Creating \(queries.count) tables, views, and indices.")

        return self.run(db, queries: queries) &&
               self.prepopulateRootFolders(db)
    }

    public func update(_ db: SQLiteDBConnection, from: Int) -> Bool {
        let to = self.version
        if from == to {
            log.debug("Skipping update from \(from) to \(to).")
            return true
        }

        if from == 0 {

            // If we're upgrading from `0`, it is likely that we have not yet switched
            // from tracking the schema version using `tableList` to `PRAGMA user_version`.
            // This will write the *previous* version number from `tableList` into
            // `PRAGMA user_version` if necessary in addition to upgrading the schema of
            // some of the old tables that were previously managed separately.
            if self.migrateFromSchemaTableIfNeeded(db) {
                let version = db.version
                
                // If the database is now properly reporting a `user_version`, it may
                // still need to be upgraded further to get to the current version of
                // the schema. So, let's simply call this `update()` function a second
                // time to handle any remaining post-v31 migrations.
                if version > 0 {
                    return self.update(db, from: version)
                }
            }

            // Otherwise, this is likely an upgrade from before Bug 1160399, so
            // let's drop and re-create.
            log.debug("Updating schema \(self.name) from zero. Assuming drop and recreate.")
            return drop(db) && create(db)
        }

        if from > to {
            // This is likely an upgrade from before Bug 1160399.
            log.debug("Downgrading browser tables. Assuming drop and recreate.")
            return drop(db) && create(db)
        }

        log.debug("Updating schema \(self.name) from \(from) to \(to).")

        if from < 4 && to >= 4 {
            return drop(db) && create(db)
        }

        if from < 5 && to >= 5 {
            if !self.run(db, sql: self.queueTableCreate) {
                return false
            }
        }

        if from < 6 && to >= 6 {
            if !self.run(db, queries: [
                "DROP INDEX IF EXISTS \(IndexVisitsSiteIDDate)",
                "CREATE INDEX IF NOT EXISTS \(IndexVisitsSiteIDIsLocalDate) ON \(TableVisits) (siteID, is_local, date)",
                self.domainsTableCreate,
                "ALTER TABLE \(TableHistory) ADD COLUMN domain_id INTEGER REFERENCES \(TableDomains)(id) ON DELETE CASCADE",
            ]) {
                return false
            }

            let urls = db.executeQuery("SELECT DISTINCT url FROM \(TableHistory) WHERE url IS NOT NULL",
                                       factory: { $0["url"] as! String })
            if !fillDomainNamesFromCursor(urls, db: db) {
                return false
            }
        }

        if from < 8 && to == 8 {
            // Nothing to do: we're just shifting the favicon table to be owned by this class.
            return true
        }

        if from < 9 && to >= 9 {
            if !self.run(db, sql: getBookmarksTableCreationStringForTable(TableBookmarksMirror)) {
                return false
            }
        }

        if from < 10 && to >= 10 {
            if !self.run(db, sql: getBookmarksStructureTableCreationStringForTable(TableBookmarksMirrorStructure, referencingMirror: TableBookmarksMirror)) {
                return false
            }

            let indexStructureParentIdx = "CREATE INDEX IF NOT EXISTS \(IndexBookmarksMirrorStructureParentIdx) " +
                                          "ON \(TableBookmarksMirrorStructure) (parent, idx)"
            if !self.run(db, sql: indexStructureParentIdx) {
                return false
            }
        }

        if from < 11 && to >= 11 {
            if !self.run(db, sql: self.topSitesTableCreate) {
                return false
            }
        }

        if from < 12 && to >= 12 {
            let bookmarksLocal = getBookmarksTableCreationStringForTable(TableBookmarksLocal, withAdditionalColumns: self.localColumns + self.iconColumns)
            let bookmarksLocalStructure = getBookmarksStructureTableCreationStringForTable(TableBookmarksLocalStructure, referencingMirror: TableBookmarksLocal)
            let bookmarksMirror = getBookmarksTableCreationStringForTable(TableBookmarksMirror, withAdditionalColumns: self.serverColumns + self.mirrorColumns + self.iconColumns)
            let bookmarksMirrorStructure = getBookmarksStructureTableCreationStringForTable(TableBookmarksMirrorStructure, referencingMirror: TableBookmarksMirror)

            let indexLocalStructureParentIdx = "CREATE INDEX IF NOT EXISTS \(IndexBookmarksLocalStructureParentIdx) " +
                "ON \(TableBookmarksLocalStructure) (parent, idx)"
            let indexBufferStructureParentIdx = "CREATE INDEX IF NOT EXISTS \(IndexBookmarksBufferStructureParentIdx) " +
                "ON \(TableBookmarksBufferStructure) (parent, idx)"
            let indexMirrorStructureParentIdx = "CREATE INDEX IF NOT EXISTS \(IndexBookmarksMirrorStructureParentIdx) " +
                "ON \(TableBookmarksMirrorStructure) (parent, idx)"

            let prep = [
                // Drop indices.
                "DROP INDEX IF EXISTS idx_bookmarksMirrorStructure_parent_idx",

                // Rename the old mirror tables to buffer.
                // The v11 one is the same shape as the current buffer table.
                "ALTER TABLE \(TableBookmarksMirror) RENAME TO \(TableBookmarksBuffer)",
                "ALTER TABLE \(TableBookmarksMirrorStructure) RENAME TO \(TableBookmarksBufferStructure)",

                // Create the new mirror and local tables.
                bookmarksLocal,
                bookmarksMirror,
                bookmarksLocalStructure,
                bookmarksMirrorStructure,
            ]

            // Only migrate bookmarks. The only folders are our roots, and we'll create those later.
            // There should be nothing else in the table, and no structure.
            // Our old bookmarks table didn't have creation date, so we use the current timestamp.
            let modified = Date.now()
            let status = SyncStatus.new.rawValue

            // We don't specify a title, expecting it to be generated on the fly, because we're smarter than Android.
            // We also don't migrate the 'id' column; we'll generate new ones that won't conflict with our roots.
            let migrateArgs: Args = [BookmarkRoots.MobileFolderGUID]
            let migrateLocal =
            "INSERT INTO \(TableBookmarksLocal) " +
            "(guid, type, bmkUri, title, faviconID, local_modified, sync_status, parentid, parentName) " +
            "SELECT guid, type, url AS bmkUri, title, faviconID, " +
            "\(modified) AS local_modified, \(status) AS sync_status, ?, '' " +
            "FROM \(_TableBookmarks) WHERE type IS \(BookmarkNodeType.bookmark.rawValue)"

            // Create structure for our migrated bookmarks.
            // In order to get contiguous positions (idx), we first insert everything we just migrated under
            // Mobile Bookmarks into a temporary table, then use rowid as our idx.

            let temporaryTable =
            "CREATE TEMPORARY TABLE children AS " +
            "SELECT guid FROM \(_TableBookmarks) WHERE " +
            "type IS \(BookmarkNodeType.bookmark.rawValue) ORDER BY id ASC"

            let createStructure =
            "INSERT INTO \(TableBookmarksLocalStructure) (parent, child, idx) " +
            "SELECT ? AS parent, guid AS child, (rowid - 1) AS idx FROM children"

            let migrate: [(String, Args?)] = [
                (migrateLocal, migrateArgs),
                (temporaryTable, nil),
                (createStructure, migrateArgs),

                // Drop the temporary table.
                ("DROP TABLE children", nil),

                // Drop the old bookmarks table.
                ("DROP TABLE \(_TableBookmarks)", nil),

                // Create indices for each structure table.
                (indexBufferStructureParentIdx, nil),
                (indexLocalStructureParentIdx, nil),
                (indexMirrorStructureParentIdx, nil),
            ]

            if !self.run(db, queries: prep) ||
               !self.prepopulateRootFolders(db) ||
               !self.run(db, queries: migrate) {
                return false
            }
            // TODO: trigger a sync?
        }

        // Add views for the overlays.
        if from < 14 && to >= 14 {
            let indexMirrorStructureChild =
            "CREATE INDEX IF NOT EXISTS \(IndexBookmarksMirrorStructureChild) " +
            "ON \(TableBookmarksMirrorStructure) (child)"
            if !self.run(db, queries: [
                self.bufferBookmarksView,
                self.bufferBookmarksStructureView,
                self.localBookmarksView,
                self.localBookmarksStructureView,
                indexMirrorStructureChild]) {
                return false
            }
        }

        if from == 14 && to >= 15 {
            // We screwed up some of the views. Recreate them.
            if !self.run(db, queries: [
                "DROP VIEW IF EXISTS \(ViewBookmarksBufferStructureOnMirror)",
                "DROP VIEW IF EXISTS \(ViewBookmarksLocalStructureOnMirror)",
                "DROP VIEW IF EXISTS \(ViewBookmarksBufferOnMirror)",
                "DROP VIEW IF EXISTS \(ViewBookmarksLocalOnMirror)",
                self.bufferBookmarksView,
                self.bufferBookmarksStructureView,
                self.localBookmarksView,
                self.localBookmarksStructureView]) {
                return false
            }
        }

        if from < 16 && to >= 16 {
            if !self.run(db, queries: [
                oldAllBookmarksView,         // Replaced in v30. The new one is not compatible here.
                historyVisitsView,
                awesomebarBookmarksView,     // … but this depends on ViewAllBookmarks.
                awesomebarBookmarksWithIconsView]) {
                return false
            }
        }

        if from < 17 && to >= 17 {
            if !self.run(db, queries: [
                // Adds the local_modified, server_modified times to the local bookmarks view
                "DROP VIEW IF EXISTS \(ViewBookmarksLocalOnMirror)",
                self.localBookmarksView]) {
                return false
            }
        }

        if from < 18 && to >= 18 {
            if !self.run(db, queries: [
                // Adds the Activity Stream blocklist table
                activityStreamBlocklistCreate]) {
                return false
            }
        }

        if from < 19 && to >= 19 {
            if !self.run(db, queries: [
                // Adds tables/indicies for metadata content
                pageMetadataCreate,
                indexPageMetadataCacheKeyCreate]) {
                return false
            }
        }

        if from < 20 && to >= 20 {
            if !self.run(db, queries: [
                "DROP VIEW IF EXISTS \(ViewBookmarksBufferOnMirror)",
                self.bufferBookmarksView]) {
                return false
            }
        }

        if from < 21 && to >= 21 {
            if !self.run(db, queries: [
                "DROP VIEW IF EXISTS \(ViewHistoryVisits)",
                self.historyVisitsView,
                indexPageMetadataSiteURLCreate]) {
                return false
            }
        }

        // Someone upgrading from v21 will get these tables anyway.
        // So, there's no need to create them only to be dropped and
        // re-created at v27 anyway.
        // if from < 22 && to >= 22 {
        //     if !self.run(db, queries: [
        //         "DROP TABLE IF EXISTS \(TablePageMetadata)",
        //         pageMetadataCreate,
        //         indexPageMetadataCacheKeyCreate,
        //         indexPageMetadataSiteURLCreate]) {
        //         return false
        //     }
        // }
        //
        // if from < 23 && to >= 23 {
        //     if !self.run(db, queries: [
        //         highlightsCreate]) {
        //         return false
        //     }
        // }
        //
        // if from < 24 && to >= 24 {
        //     if !self.run(db, queries: [
        //         // We can safely drop the highlights cache table since it gets cleared on every invalidate anyways.
        //         "DROP TABLE IF EXISTS \(TableHighlights)",
        //         highlightsCreate
        //     ]) {
        //         return false
        //     }
        // }

        // Someone upgrading from v21 will get this table anyway.
        // So, there's no need to create it only to be dropped and
        // re-created at v26 anyway.
        // if from < 25 && to >= 25 {
        //     if !self.run(db, queries: [
        //         pinnedTopSitesTableCreate
        //         ]) {
        //         return false
        //     }
        // }

        if from < 26 && to >= 26 {
            if !self.run(db, queries: [
                // The old pin table was never released so we can safely drop
                "DROP TABLE IF EXISTS \(TablePinnedTopSites)",
                pinnedTopSitesTableCreate
                ]) {
                return false
            }
        }

        if from < 27 && to >= 27 {
            if !self.run(db, queries: [
                "DROP TABLE IF EXISTS \(TablePageMetadata)",
                "DROP TABLE IF EXISTS \(TableHighlights)",
                pageMetadataCreate,
                indexPageMetadataCacheKeyCreate,
                indexPageMetadataSiteURLCreate,
                highlightsCreate
                ]) {
                return false
            }
        }

        if from < 28 && to >= 28 {
            if !self.run(db, queries: [
                self.pendingBookmarksDeletions,
                self.bufferBookmarksWithDeletionsView
            ]) {
                return false
            }
        }

        if from < 29 && to >= 29 {
            if !self.run(db, queries: [
                self.remoteDevices
            ]) {
                return false
            }
        }

        if from < 30 && to >= 30 {
            // We changed this view as a follow-up to the above in order to exclude buffer
            // deletions from the bookmarked set.
            if !self.run(db, queries: [
                "DROP VIEW IF EXISTS \(ViewAllBookmarks)",
                allBookmarksView
            ]) {
                return false
            }
        }

        // NOTE: These tables should have already existed in prior
        // versions, but were managed separately via the SchemaTable.
        // Here we create them if they don't already exist to handle
        // cases where we are creating a brand new DB.
        if from < 31 && to >= 31 {
            if !self.run(db, queries: [
                syncCommandsTableCreate,
                clientsTableCreate,
                tabsTableCreate
                ]) {
                return false
            }
        }

        if from < 32 && to >= 32 {
            var queries: [String] = []
            // If upgrading from < 12 these tables are created with that column already present.
            if from > 12 {
                queries.append(contentsOf: [
                    "ALTER TABLE \(TableBookmarksLocal) ADD date_added INTEGER",
                    "ALTER TABLE \(TableBookmarksMirror) ADD date_added INTEGER",
                    "ALTER TABLE \(TableBookmarksBuffer) ADD date_added INTEGER"
                ])
            }
            queries.append(contentsOf: [
                "UPDATE \(TableBookmarksLocal) SET date_added = local_modified",
                "UPDATE \(TableBookmarksMirror) SET date_added = server_modified"
            ])
            if !self.run(db, queries: queries) {
                return false
            }
        }

        if from < 33 && to >= 33 {
            if !self.run(db, queries: [
                "DROP VIEW IF EXISTS \(ViewBookmarksBufferOnMirror)",
                "DROP VIEW IF EXISTS \(ViewBookmarksBufferWithDeletionsOnMirror)",
                "DROP VIEW IF EXISTS \(ViewBookmarksLocalOnMirror)",
                self.bufferBookmarksView,
                self.bufferBookmarksWithDeletionsView,
                self.localBookmarksView
                ]) {
                return false
            }
        }

        if from < 34 && to >= 34 {
            // Drop over-large items from the database, and truncate
            // over-long titles.
            // We do this once, and only for local bookmarks: if they
            // already escaped, then it's better to let them be.
            // Hard-code values here both for simplicity and to make
            // migrations predictable.
            // We don't need to worry about description: we never wrote it.
            if !self.run(db, queries: [
                "DELETE FROM \(TableHistory) WHERE is_deleted = 0 AND length(url) > 65536",
                "DELETE FROM \(TablePageMetadata) WHERE length(site_url) > 65536",
                "DELETE FROM \(TableBookmarksLocal) WHERE is_deleted = 0 AND length(bmkUri) > 65536",
                "UPDATE \(TableBookmarksLocal) SET title = substr(title, 1, 4096)" +
                "  WHERE is_deleted = 0 AND length(title) > 4096",
                ]) {
                return false
            }
        }

        return true
    }
    
    fileprivate func migrateFromSchemaTableIfNeeded(_ db: SQLiteDBConnection) -> Bool {
        log.info("Checking if schema table migration is needed.")

        // If `PRAGMA user_version` is v31 or later, we don't need to do anything here.
        guard db.version < 31 else {
            return true
        }

        // Query for the existence of the `tableList` table to determine if we are
        // migrating from an older DB version or if this is just a brand new DB.
        let sqliteMasterCursor = db.executeQueryUnsafe("SELECT COUNT(*) AS number FROM sqlite_master WHERE type = 'table' AND name = 'tableList'", factory: IntFactory, withArgs: [] as Args)

        let tableListTableExists = sqliteMasterCursor[0] == 1
        sqliteMasterCursor.close()

        // If `tableList` still exists in this DB, then we need to continue to check if
        // any table-specific migrations are required before removing it. Otherwise, if
        // `tableList` does not exist, it is likely due to this being a brand new DB and
        // no additional steps need to be taken at this point.
        guard tableListTableExists else {
            return true
        }

        // If we are unable to migrate the `clients` table from the schema table, we
        // have failed and cannot continue.
        guard migrateClientsTableFromSchemaTableIfNeeded(db) != .failure else {
            return false
        }

        // Get the *previous* schema version (prior to v31) specified in `tableList`
        // before dropping it.
        let previousVersionCursor = db.executeQueryUnsafe("SELECT version FROM tableList WHERE name = 'BROWSER'", factory: IntFactory, withArgs: [] as Args)

        let previousVersion = previousVersionCursor[0] ?? 0
        previousVersionCursor.close()

        // No other intermediate migrations are needed for the remaining tables and
        // we have already captured the *previous* schema version specified in
        // `tableList`, so we can now safely drop it.
        log.info("Schema table migrations complete; Dropping 'tableList' table.")

        let sql = "DROP TABLE IF EXISTS tableList"
        do {
            try db.executeChange(sql)
        } catch let err as NSError {
            Sentry.shared.sendWithStacktrace(message: "Error dropping tableList table", tag: SentryTag.browserDB, severity: .error, description: "\(err.localizedDescription)")
            return false
        }

        // Lastly, write the *previous* schema version (prior to v31) to the database
        // using `PRAGMA user_version = ?`.
        do {
            try db.setVersion(previousVersion)
        } catch let err as NSError {
            Sentry.shared.sendWithStacktrace(message: "Error setting database version", tag: SentryTag.browserDB, severity: .error, description: "\(err.localizedDescription)")
            return false
        }
        
        return true
    }

    // Performs the intermediate migrations for the `clients` table that were previously
    // being handled by the schema table. This should update older versions of the `clients`
    // table prior to v31. If the `clients` table is able to be successfully migrated, this
    // will return `.success`. If no migration is required because either the `clients` table
    // is already at v31 or it does not exist yet at all, this will return `.skipped`.
    // Otherwise, if the `clients` table migration is needed and an error was encountered, we
    // return `.failure`.
    fileprivate func migrateClientsTableFromSchemaTableIfNeeded(_ db: SQLiteDBConnection) -> SchemaUpgradeResult {
        // Query for the existence of the `clients` table to determine if we are
        // migrating from an older DB version or if this is just a brand new DB.
        let sqliteMasterCursor = db.executeQueryUnsafe("SELECT COUNT(*) AS number FROM sqlite_master WHERE type = 'table' AND name = '\(TableClients)'", factory: IntFactory, withArgs: [] as Args)
        
        let clientsTableExists = sqliteMasterCursor[0] == 1
        sqliteMasterCursor.close()
        
        guard clientsTableExists else {
            return .skipped
        }
        
        // Check if intermediate migrations are necessary for the 'clients' table.
        let previousVersionCursor = db.executeQueryUnsafe("SELECT version FROM tableList WHERE name = '\(TableClients)'", factory: IntFactory, withArgs: [] as Args)
        
        let previousClientsTableVersion = previousVersionCursor[0] ?? 0
        previousVersionCursor.close()
        
        guard previousClientsTableVersion > 0 && previousClientsTableVersion <= 3 else {
            return .skipped
        }
        
        log.info("Migrating '\(TableClients)' table from version \(previousClientsTableVersion).")
        
        if previousClientsTableVersion < 2 {
            let sql = "ALTER TABLE \(TableClients) ADD COLUMN version TEXT"
            do {
                try db.executeChange(sql)
            } catch let err as NSError {
                log.error("Error altering \(TableClients) table: \(err.localizedDescription); SQL was \(sql)")
                let extra = ["table": "\(TableClients)", "errorDescription": "\(err.localizedDescription)", "sql": "\(sql)"]
                Sentry.shared.sendWithStacktrace(message: "Error altering table", tag: SentryTag.browserDB, severity: .error, extra: extra)
                return .failure
            }
        }
        
        if previousClientsTableVersion < 3 {
            let sql = "ALTER TABLE \(TableClients) ADD COLUMN fxaDeviceId TEXT"
            do {
                try db.executeChange(sql)
            } catch let err as NSError {
                log.error("Error altering \(TableClients) table: \(err.localizedDescription); SQL was \(sql)")
                let extra = ["table": "\(TableClients)", "errorDescription": "\(err.localizedDescription)", "sql": "\(sql)"]
                Sentry.shared.sendWithStacktrace(message: "Error altering table", tag: SentryTag.browserDB, severity: .error, extra: extra)
                return .failure
            }
        }
        
        return .success
    }
    
    fileprivate func fillDomainNamesFromCursor(_ cursor: Cursor<String>, db: SQLiteDBConnection) -> Bool {
        if cursor.count == 0 {
            return true
        }

        // URL -> hostname, flattened to make args.
        var pairs = Args()
        pairs.reserveCapacity(cursor.count * 2)
        for url in cursor {
            if let url = url, let host = url.asURL?.normalizedHost {
                pairs.append(url)
                pairs.append(host)
            }
        }
        cursor.close()

        let tmpTable = "tmp_hostnames"
        let table = "CREATE TEMP TABLE \(tmpTable) (url TEXT NOT NULL UNIQUE, domain TEXT NOT NULL, domain_id INT)"
        if !self.run(db, sql: table, args: nil) {
            log.error("Can't create temporary table. Unable to migrate domain names. Top Sites is likely to be broken.")
            return false
        }

        // Now insert these into the temporary table. Chunk by an even number, for obvious reasons.
        let chunks = chunk(pairs, by: BrowserDB.MaxVariableNumber - (BrowserDB.MaxVariableNumber % 2))
        for chunk in chunks {
            let ins = "INSERT INTO \(tmpTable) (url, domain) VALUES " +
                      Array<String>(repeating: "(?, ?)", count: chunk.count / 2).joined(separator: ", ")
            if !self.run(db, sql: ins, args: Array(chunk)) {
                log.error("Couldn't insert domains into temporary table. Aborting migration.")
                return false
            }
        }

        // Now make those into domains.
        let domains = "INSERT OR IGNORE INTO \(TableDomains) (domain) SELECT DISTINCT domain FROM \(tmpTable)"

        // … and fill that temporary column.
        let domainIDs = "UPDATE \(tmpTable) SET domain_id = (SELECT id FROM \(TableDomains) WHERE \(TableDomains).domain = \(tmpTable).domain)"

        // Update the history table from the temporary table.
        let updateHistory = "UPDATE \(TableHistory) SET domain_id = (SELECT domain_id FROM \(tmpTable) WHERE \(tmpTable).url = \(TableHistory).url)"

        // Clean up.
        let dropTemp = "DROP TABLE \(tmpTable)"

        // Now run these.
        if !self.run(db, queries: [domains,
                                   domainIDs,
                                   updateHistory,
                                   dropTemp]) {
            log.error("Unable to migrate domains.")
            return false
        }

        return true
    }

    public func drop(_ db: SQLiteDBConnection) -> Bool {
        log.debug("Dropping all browser tables.")
        let additional = [
            "DROP TABLE IF EXISTS faviconSites" // We renamed it to match naming convention.
        ]

        let views = AllViews.map { "DROP VIEW IF EXISTS \($0)" }
        let indices = AllIndices.map { "DROP INDEX IF EXISTS \($0)" }
        let tables = AllTables.map { "DROP TABLE IF EXISTS \($0)" }
        let queries = Array([views, indices, tables, additional].joined())
        return self.run(db, queries: queries)
    }
}
