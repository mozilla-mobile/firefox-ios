/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

let BookmarksFolderTitleMobile = NSLocalizedString("Mobile Bookmarks", tableName: "Storage", comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.")
let BookmarksFolderTitleMenu = NSLocalizedString("Bookmarks Menu", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.")
let BookmarksFolderTitleToolbar = NSLocalizedString("Bookmarks Toolbar", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.")
let BookmarksFolderTitleUnsorted = NSLocalizedString("Unsorted Bookmarks", tableName: "Storage", comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.")

let _TableBookmarks = "bookmarks"                                      // Removed in v12. Kept for migration.
let TableBookmarksMirror = "bookmarksMirror"                           // Added in v9.
let TableBookmarksMirrorStructure = "bookmarksMirrorStructure"         // Added in v10.

let TableBookmarksBuffer = "bookmarksBuffer"                           // Added in v12. bookmarksMirror is renamed to bookmarksBuffer.
let TableBookmarksBufferStructure = "bookmarksBufferStructure"         // Added in v12.
let TableBookmarksLocal = "bookmarksLocal"                             // Added in v12. Supersedes 'bookmarks'.
let TableBookmarksLocalStructure = "bookmarksLocalStructure"           // Added in v12.

let TableFavicons = "favicons"
let TableHistory = "history"
let TableCachedTopSites = "cached_top_sites"
let TableDomains = "domains"
let TableVisits = "visits"
let TableFaviconSites = "favicon_sites"
let TableQueuedTabs = "queue"

let ViewWidestFaviconsForSites = "view_favicons_widest"
let ViewHistoryIDsWithWidestFavicons = "view_history_id_favicon"
let ViewIconForURL = "view_icon_for_url"

let IndexHistoryShouldUpload = "idx_history_should_upload"
let IndexVisitsSiteIDDate = "idx_visits_siteID_date"                   // Removed in v6.
let IndexVisitsSiteIDIsLocalDate = "idx_visits_siteID_is_local_date"   // Added in v6.
let IndexBookmarksMirrorStructureParentIdx = "idx_bookmarksMirrorStructure_parent_idx"   // Added in v10.
let IndexBookmarksLocalStructureParentIdx = "idx_bookmarksLocalStructure_parent_idx"     // Added in v12.
let IndexBookmarksBufferStructureParentIdx = "idx_bookmarksBufferStructure_parent_idx"   // Added in v12.

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

    TableQueuedTabs,
]

private let AllViews: [String] = [
    ViewHistoryIDsWithWidestFavicons,
    ViewWidestFaviconsForSites,
    ViewIconForURL,
]

private let AllIndices: [String] = [
    IndexHistoryShouldUpload,
    IndexVisitsSiteIDIsLocalDate,
    IndexBookmarksBufferStructureParentIdx,
    IndexBookmarksLocalStructureParentIdx,
    IndexBookmarksMirrorStructureParentIdx,
]

private let AllTablesIndicesAndViews: [String] = AllViews + AllIndices + AllTables

private let log = Logger.syncLogger

/**
 * The monolithic class that manages the inter-related history etc. tables.
 * We rely on SQLiteHistory having initialized the favicon table first.
 */
public class BrowserTable: Table {
    static let DefaultVersion = 12

    // TableInfo fields.
    var name: String { return "BROWSER" }
    var version: Int { return BrowserTable.DefaultVersion }

    let sqliteVersion: Int32
    let supportsPartialIndices: Bool

    public init() {
        let v = sqlite3_libversion_number()
        self.sqliteVersion = v
        self.supportsPartialIndices = v >= 3008000          // 3.8.0.
        let ver = String.fromCString(sqlite3_libversion())!
        log.info("SQLite version: \(ver) (\(v)).")
    }

    func run(db: SQLiteDBConnection, sql: String, args: Args? = nil) -> Bool {
        let err = db.executeChange(sql, withArgs: args)
        if err != nil {
            log.error("Error running SQL in BrowserTable. \(err?.localizedDescription)")
            log.error("SQL was \(sql)")
        }
        return err == nil
    }

    // TODO: transaction.
    func run(db: SQLiteDBConnection, queries: [(String, Args?)]) -> Bool {
        for (sql, args) in queries {
            if !run(db, sql: sql, args: args) {
                return false
            }
        }
        return true
    }

    func run(db: SQLiteDBConnection, queries: [String]) -> Bool {
        for sql in queries {
            if !run(db, sql: sql) {
                return false
            }
        }
        return true
    }

    func runValidQueries(db: SQLiteDBConnection, queries: [(String?, Args?)]) -> Bool {
        for (sql, args) in queries {
            if let sql = sql {
                if !run(db, sql: sql, args: args) {
                    return false
                }
            }
        }
        return true
    }

    func runValidQueries(db: SQLiteDBConnection, queries: [String?]) -> Bool {
        return self.run(db, queries: optFilter(queries))
    }

    func prepopulateRootFolders(db: SQLiteDBConnection) -> Bool {
        let type = BookmarkNodeType.Folder.rawValue
        let now = NSDate.nowNumber()
        let status = SyncStatus.New.rawValue

        let localArgs: Args = [
            BookmarkRoots.RootID,    BookmarkRoots.RootGUID,          type, BookmarkRoots.RootGUID, status, now,
            BookmarkRoots.MobileID,  BookmarkRoots.MobileFolderGUID,  type, BookmarkRoots.RootGUID, status, now,
            BookmarkRoots.MenuID,    BookmarkRoots.MenuFolderGUID,    type, BookmarkRoots.RootGUID, status, now,
            BookmarkRoots.ToolbarID, BookmarkRoots.ToolbarFolderGUID, type, BookmarkRoots.RootGUID, status, now,
            BookmarkRoots.UnfiledID, BookmarkRoots.UnfiledFolderGUID, type, BookmarkRoots.RootGUID, status, now,
        ]

        let structureArgs: Args = [
            BookmarkRoots.RootGUID, BookmarkRoots.MenuFolderGUID,    0,
            BookmarkRoots.RootGUID, BookmarkRoots.ToolbarFolderGUID, 1,
            BookmarkRoots.RootGUID, BookmarkRoots.UnfiledFolderGUID, 2,
            BookmarkRoots.RootGUID, BookmarkRoots.MobileFolderGUID,  3,
        ]

        // Note that we specify an empty title and parentName for these records. We should
        // never need a parentName -- we don't use content-based reconciling or
        // reparent these -- and we'll use the current locale's string, retrieved
        // via titleForSpecialGUID, if necessary.

        let local =
        "INSERT INTO \(TableBookmarksLocal) " +
        "(id, guid, type, parentid, title, parentName, sync_status, local_modified) VALUES" +
        "  (?, ?, ?, ?, '', '', ?, ?)" +    // Root
        ", (?, ?, ?, ?, '', '', ?, ?)" +    // Mobile
        ", (?, ?, ?, ?, '', '', ?, ?)" +    // Menu
        ", (?, ?, ?, ?, '', '', ?, ?)" +    // Toolbar
        ", (?, ?, ?, ?, '', '', ?, ?)"      // Unsorted

        let structure =
        "INSERT INTO \(TableBookmarksLocalStructure) (parent, child, idx) VALUES" +
        "  (?, ?, ?)" +      // Menu
        ", (?, ?, ?)" +      // Toolbar
        ", (?, ?, ?)" +      // Unsorted
        ", (?, ?, ?)"        // Mobile

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

    let iconColumns = ", faviconID INTEGER REFERENCES \(TableFavicons)(id) ON DELETE SET NULL"
    let mirrorColumns = ", is_overridden TINYINT NOT NULL DEFAULT 0"

    let serverColumns = ", server_modified INTEGER NOT NULL" +    // Milliseconds.
                        ", hasDupe TINYINT NOT NULL DEFAULT 0"    // Boolean, 0 (false) if deleted.

    let localColumns = ", local_modified INTEGER" +            // Can be null. Client clock. In extremis only.
                       ", sync_status TINYINT "                // SyncStatus enum. Set when changed or created.

    func getBookmarksTableCreationStringForTable(table: String, withAdditionalColumns: String="") -> String {
        // The stupid absence of naming conventions here is thanks to pre-Sync Weave. Sorry.
        // For now we have the simplest possible schema: everything in one.
        let sql =
        "CREATE TABLE IF NOT EXISTS \(table) " +

        // Shared fields.
        "( id INTEGER PRIMARY KEY AUTOINCREMENT" +
        ", guid TEXT NOT NULL UNIQUE" +
        ", type TINYINT NOT NULL" +                    // Type enum. TODO: BookmarkNodeType needs to be extended.

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
    func getBookmarksStructureTableCreationStringForTable(table: String, referencingMirror mirror: String) -> String {
        // TODO: index me.
        let sql =
        "CREATE TABLE IF NOT EXISTS \(table) " +
        "( parent TEXT NOT NULL REFERENCES \(mirror)(guid) ON DELETE CASCADE" +
        ", child TEXT NOT NULL" +      // Should be the GUID of a child.
        ", idx INTEGER NOT NULL" +     // Should advance from 0.
        ")"

        return sql
    }

    func create(db: SQLiteDBConnection) -> Bool {
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

        let queries: [String] = [
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
            indexBufferStructureParentIdx,
            indexLocalStructureParentIdx,
            indexMirrorStructureParentIdx,
            faviconSites,
            indexShouldUpload,
            indexSiteIDDate,
            widestFavicons,
            historyIDsWithIcon,
            iconForURL,
            self.queueTableCreate,
            self.topSitesTableCreate,
        ]

        assert(queries.count == AllTablesIndicesAndViews.count, "Did you forget to add your table, index, or view to the list?")

        log.debug("Creating \(queries.count) tables, views, and indices.")

        return self.run(db, queries: queries) &&
               self.prepopulateRootFolders(db)
    }

    func updateTable(db: SQLiteDBConnection, from: Int) -> Bool {
        let to = BrowserTable.DefaultVersion
        if from == to {
            log.debug("Skipping update from \(from) to \(to).")
            return true
        }

        if from == 0 {
            // This is likely an upgrade from before Bug 1160399.
            log.debug("Updating browser tables from zero. Assuming drop and recreate.")
            return drop(db) && create(db)
        }

        if from > to {
            // This is likely an upgrade from before Bug 1160399.
            log.debug("Downgrading browser tables. Assuming drop and recreate.")
            return drop(db) && create(db)
        }

        log.debug("Updating browser tables from \(from) to \(to).")

        if from < 4 && to >= 4 {
            return drop(db) && create(db)
        }

        if from < 5 && to >= 5  {
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
            let modified = NSDate.now()
            let status = SyncStatus.New.rawValue

            // We don't specify a title, expecting it to be generated on the fly, because we're smarter than Android.
            // We also don't migrate the 'id' column; we'll generate new ones that won't conflict with our roots.
            let migrateArgs: Args = [BookmarkRoots.MobileFolderGUID]
            let migrateLocal =
            "INSERT INTO \(TableBookmarksLocal) " +
            "(guid, type, bmkUri, title, faviconID, local_modified, sync_status, parentid, parentName) " +
            "SELECT guid, type, url AS bmkUri, title, faviconID, " +
            "\(modified) AS local_modified, \(status) AS sync_status, ?, '' " +
            "FROM \(_TableBookmarks) WHERE type IS \(BookmarkNodeType.Bookmark.rawValue)"

            // Create structure for our migrated bookmarks.
            // In order to get contiguous numeric row IDs, we first insert everything we just migrated under
            // Mobile Bookmarks into a temporary table, then use rowid as our idx.

            let temporaryTable =
            "CREATE TEMPORARY TABLE children AS " +
            "SELECT guid FROM \(_TableBookmarks) WHERE " +
            "type IS \(BookmarkNodeType.Bookmark.rawValue) ORDER BY id ASC"

            let createStructure =
            "INSERT INTO \(TableBookmarksLocalStructure) (parent, child, idx) " +
            "SELECT ? AS parent, guid AS child, rowid AS idx FROM children"

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
                (indexMirrorStructureParentIdx, nil)
            ]

            if !self.run(db, queries: prep) ||
               !self.prepopulateRootFolders(db) ||
               !self.run(db, queries: migrate) {
                return false
            }
            // TODO: trigger a sync?
        }

        return true
    }

    private func fillDomainNamesFromCursor(cursor: Cursor<String>, db: SQLiteDBConnection) -> Bool {
        if cursor.count == 0 {
            return true
        }

        // URL -> hostname, flattened to make args.
        var pairs = Args()
        pairs.reserveCapacity(cursor.count * 2)
        for url in cursor {
            if let url = url, host = url.asURL?.normalizedHost() {
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
                      Array<String>(count: chunk.count / 2, repeatedValue: "(?, ?)").joinWithSeparator(", ")
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

    /**
     * The Table mechanism expects to be able to check if a 'table' exists. In our (ab)use
     * of Table, that means making sure that any of our tables and views exist.
     * We do that by fetching all tables from sqlite_master with matching names, and verifying
     * that we get back more than one.
     * Note that we don't check for views -- trust to luck.
     */
    func exists(db: SQLiteDBConnection) -> Bool {
        return db.tablesExist(AllTables)
    }

    func drop(db: SQLiteDBConnection) -> Bool {
        log.debug("Dropping all browser tables.")
        let additional = [
            "DROP TABLE IF EXISTS faviconSites" // We renamed it to match naming convention.
        ]

        let views = AllViews.map { "DROP VIEW IF EXISTS \($0)" }
        let indices = AllIndices.map { "DROP INDEX IF EXISTS \($0)" }
        let tables = AllTables.map { "DROP TABLE IF EXISTS \($0)" }
        let queries = Array([views, indices, tables, additional].flatten())
        return self.run(db, queries: queries)
    }
}
