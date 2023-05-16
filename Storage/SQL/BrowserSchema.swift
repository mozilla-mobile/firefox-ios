// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

let TableBookmarksMirror = "bookmarksMirror"                           // Added in v9.
let TableBookmarksMirrorStructure = "bookmarksMirrorStructure"         // Added in v10.

let TableBookmarksBuffer = "bookmarksBuffer"                           // Added in v12. bookmarksMirror is renamed to bookmarksBuffer.
let TableBookmarksBufferStructure = "bookmarksBufferStructure"         // Added in v12.
let TableBookmarksLocal = "bookmarksLocal"                             // Added in v12. Supersedes 'bookmarks'.
let TableBookmarksLocalStructure = "bookmarksLocalStructure"           // Added in v12.

let TablePendingBookmarksDeletions = "pending_deletions"               // Added in v28.

let TableFavicons = "favicons"
let TableHistory = "history"
let TableHistoryFTS = "history_fts"                                    // Added in v35.
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
let TableFaviconSiteURLs = "favicon_site_urls"

let MatViewAwesomebarBookmarksWithFavicons = "matview_awesomebar_bookmarks_with_favicons"

let IndexHistoryShouldUpload = "idx_history_should_upload"
let IndexVisitsSiteIDDate = "idx_visits_siteID_date"                   // Removed in v6.
let IndexVisitsSiteIDIsLocalDate = "idx_visits_siteID_is_local_date"   // Added in v6.
let IndexBookmarksMirrorStructureParentIdx = "idx_bookmarksMirrorStructure_parent_idx"   // Added in v10.
let IndexBookmarksLocalStructureParentIdx = "idx_bookmarksLocalStructure_parent_idx"     // Added in v12.
let IndexBookmarksBufferStructureParentIdx = "idx_bookmarksBufferStructure_parent_idx"   // Added in v12.
let IndexBookmarksMirrorStructureChild = "idx_bookmarksMirrorStructure_child"            // Added in v14.
let IndexPageMetadataCacheKey = "idx_page_metadata_cache_key_uniqueindex" // Added in v19
let IndexPageMetadataSiteURL = "idx_page_metadata_site_url_uniqueindex" // Added in v21

let TriggerHistoryBeforeUpdate = "t_history_beforeupdate" // Added in v35
let TriggerHistoryBeforeDelete = "t_history_beforedelete" // Added in v35
let TriggerHistoryAfterUpdate = "t_history_afterupdate" // Added in v35
let TriggerHistoryAfterInsert = "t_history_afterinsert" // Added in v35

private let AllTables: [String] = [
    TableDomains,
    TableFavicons,
    TableFaviconSites,

    TableHistory,
    TableHistoryFTS,
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
    TableFaviconSiteURLs,

    MatViewAwesomebarBookmarksWithFavicons,
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

private let AllTriggers: [String] = [
    TriggerHistoryBeforeUpdate,
    TriggerHistoryBeforeDelete,
    TriggerHistoryAfterUpdate,
    TriggerHistoryAfterInsert,
]

private let AllTablesIndicesTriggersAndViews: [String] = AllTriggers + AllIndices + AllTables

/**
 * The monolithic class that manages the inter-related history etc. tables.
 * We rely on BrowserDBSQLite having initialized the favicon table first.
 */
open class BrowserSchema: Schema {
    static let DefaultVersion = 41
    private var logger: Logger

    public var name: String { return "BROWSER" }
    public var version: Int { return BrowserSchema.DefaultVersion }

    let sqliteVersion: Int32
    let supportsPartialIndices: Bool

    public init(logger: Logger = DefaultLogger.shared) {
        let v = sqlite3_libversion_number()
        self.sqliteVersion = v
        self.supportsPartialIndices = v >= 3008000          // 3.8.0.
        let ver = String(cString: sqlite3_libversion())
        self.logger = logger
        logger.log("Init SQLite version: \(ver) (\(v)).",
                   level: .debug,
                   category: .setup)
    }

    func run(_ db: SQLiteDBConnection, sql: String, args: Args? = nil) -> Bool {
        do {
            try db.executeChange(sql, withArgs: args)
        } catch let err as NSError {
            logger.log("Error running SQL in BrowserSchema: \(err.localizedDescription) with \(sql)",
                       level: .warning,
                       category: .storage)
            return false
        }

        return true
    }

    // TODO: transaction.
    func run(_ db: SQLiteDBConnection, queries: [(String, Args?)]) -> Bool {
        for (sql, args) in queries where !run(db, sql: sql, args: args) {
                return false
        }
        return true
    }

    func run(_ db: SQLiteDBConnection, queries: [String]) -> Bool {
        for sql in queries where !run(db, sql: sql) {
            return false
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
        let type = 2 // "folder"
        let now = Date.nowNumber()
        let status = 2 // "new"

        let localArgs: Args = [
            0, BookmarkRoots.RootGUID, type, now, BookmarkRoots.RootGUID, status, now,
            1, BookmarkRoots.MobileFolderGUID, type, now, BookmarkRoots.RootGUID, status, now,
            2, BookmarkRoots.MenuFolderGUID, type, now, BookmarkRoots.RootGUID, status, now,
            3, BookmarkRoots.ToolbarFolderGUID, type, now, BookmarkRoots.RootGUID, status, now,
            4, BookmarkRoots.UnfiledFolderGUID, type, now, BookmarkRoots.RootGUID, status, now,
        ]

        // Compute these args using the sequence in RootChildren, rather than hard-coding.
        var idx = 0
        var structureArgs = Args()
        let rootChildren: [GUID] = [
            BookmarkRoots.MenuFolderGUID,
            BookmarkRoots.ToolbarFolderGUID,
            BookmarkRoots.UnfiledFolderGUID,
            BookmarkRoots.MobileFolderGUID,
        ]
        structureArgs.reserveCapacity(rootChildren.count * 3)
        rootChildren.forEach { guid in
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
            "INSERT INTO bookmarksLocal (id, guid, type, date_added, parentid, title, parentName, sync_status, local_modified) VALUES " +
            Array(repeating: "(?, ?, ?, ?, ?, '', '', ?, ?)", count: rootChildren.count + 1).joined(separator: ", ")

        let structure =
            "INSERT INTO bookmarksLocalStructure (parent, child, idx) VALUES " +
            Array(repeating: "(?, ?, ?)", count: rootChildren.count).joined(separator: ", ")

        return self.run(db, queries: [(local, localArgs), (structure, structureArgs)])
    }

    let topSitesTableCreate = """
        CREATE TABLE IF NOT EXISTS cached_top_sites (
            historyID INTEGER,
            url TEXT NOT NULL,
            title TEXT NOT NULL,
            guid TEXT NOT NULL UNIQUE,
            domain_id INTEGER,
            domain TEXT NO NULL,
            localVisitDate REAL,
            remoteVisitDate REAL,
            localVisitCount INTEGER,
            remoteVisitCount INTEGER,
            iconID INTEGER,
            iconURL TEXT,
            iconDate REAL,
            iconType INTEGER,
            iconWidth INTEGER,
            frecencies REAL
        )
        """

    let pinnedTopSitesTableCreate = """
        CREATE TABLE IF NOT EXISTS pinned_top_sites (
            historyID INTEGER,
            url TEXT NOT NULL UNIQUE,
            title TEXT,
            guid TEXT,
            pinDate REAL,
            domain TEXT NOT NULL
        )
        """

    let domainsTableCreate = """
        CREATE TABLE IF NOT EXISTS domains (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            domain TEXT NOT NULL UNIQUE,
            showOnTopSites TINYINT NOT NULL DEFAULT 1
        )
        """

    let queueTableCreate = """
        CREATE TABLE IF NOT EXISTS queue (
            url TEXT NOT NULL UNIQUE,
            title TEXT
        )
        """

    let syncCommandsTableCreate = """
        CREATE TABLE IF NOT EXISTS commands (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_guid TEXT NOT NULL,
            value TEXT NOT NULL
        )
        """

    let clientsTableCreate = """
        CREATE TABLE IF NOT EXISTS clients (
            guid TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            modified INTEGER NOT NULL,
            type TEXT,
            formfactor TEXT,
            os TEXT,
            version TEXT,
            fxaDeviceId TEXT
        )
        """

    let tabsTableCreate = """
        CREATE TABLE IF NOT EXISTS tabs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_guid TEXT REFERENCES clients(guid) ON DELETE CASCADE,
            url TEXT NOT NULL,
            title TEXT,
            history TEXT,
            last_used INTEGER
        )
        """

    let activityStreamBlocklistCreate = """
        CREATE TABLE IF NOT EXISTS activity_stream_blocklist (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL UNIQUE,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
        """

    let pageMetadataCreate = """
        CREATE TABLE IF NOT EXISTS page_metadata (
            id INTEGER PRIMARY KEY,
            cache_key LONGVARCHAR UNIQUE,
            site_url TEXT,
            media_url LONGVARCHAR,
            title TEXT,
            type VARCHAR(32),
            description TEXT,
            provider_name TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            expired_at LONG
        )
        """

    let highlightsCreate = """
        CREATE TABLE IF NOT EXISTS highlights (
            historyID INTEGER PRIMARY KEY,
            cache_key LONGVARCHAR,
            url TEXT,
            title TEXT,
            guid TEXT,
            visitCount INTEGER,
            visitDate DATETIME,
            is_bookmarked INTEGER
        )
        """

    let awesomebarBookmarksWithFaviconsCreate = """
        CREATE TABLE IF NOT EXISTS matview_awesomebar_bookmarks_with_favicons (
            guid TEXT,
            url TEXT,
            title TEXT,
            description TEXT,
            visitDate DATETIME,
            iconID INTEGER,
            iconURL TEXT,
            iconDate REAL,
            iconType INTEGER,
            iconWidth INTEGER
        )
        """

    let faviconSiteURLsCreate = """
        CREATE TABLE favicon_site_urls (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            site_url TEXT NOT NULL,
            faviconID INTEGER NOT NULL REFERENCES favicons(id) ON DELETE CASCADE,
            UNIQUE (site_url, faviconID)
        )
        """

    // We create an external content FTS4 table here that essentially creates
    // an FTS index of the existing content in the `history` table. This table
    // does not duplicate the content already in `history`, but it does need to
    // be incrementally updated after the initial "rebuild" using triggers in
    // order to stay in sync.
    let historyFTSCreate =
        "CREATE VIRTUAL TABLE \(TableHistoryFTS) USING fts4(content=\"\(TableHistory)\", url, title)"

    // This query rebuilds the FTS index of the `history_fts` table.
    let historyFTSRebuild =
        "INSERT INTO \(TableHistoryFTS)(\(TableHistoryFTS)) VALUES ('rebuild')"

    let indexPageMetadataCacheKeyCreate =
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_page_metadata_cache_key_uniqueindex ON page_metadata (cache_key)"

    let indexPageMetadataSiteURLCreate =
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_page_metadata_site_url_uniqueindex ON page_metadata (site_url)"

    let iconColumns = ", faviconID INTEGER REFERENCES favicons(id) ON DELETE SET NULL"
    let mirrorColumns = ", is_overridden TINYINT NOT NULL DEFAULT 0"

    let serverColumns = """
        -- Milliseconds.
        , server_modified INTEGER NOT NULL
        -- Boolean, 0 (false) if deleted.
        , hasDupe TINYINT NOT NULL DEFAULT 0
        """

    let localColumns = """
        -- Can be null. Client clock. In extremis only.
        , local_modified INTEGER
        -- SyncStatus enum. Set when changed or created.
        , sync_status TINYINT NOT NULL
        """

    func getBookmarksTableCreationStringForTable(_ table: String, withAdditionalColumns: String="") -> String {
        // The stupid absence of naming conventions here is thanks to pre-Sync Weave. Sorry.
        // For now we have the simplest possible schema: everything in one.
        let sql = """
            CREATE TABLE IF NOT EXISTS \(table) (
                -- Shared fields.
                  id INTEGER PRIMARY KEY AUTOINCREMENT
                , guid TEXT NOT NULL UNIQUE
                -- Type enum.
                , type TINYINT NOT NULL
                , date_added INTEGER

                -- Record/envelope metadata that'll allow us to do merges.
                -- Boolean
                , is_deleted TINYINT NOT NULL DEFAULT 0
                -- GUID
                , parentid TEXT
                , parentName TEXT

                -- Type-specific fields. These should be NOT NULL in many cases, but we're going
                -- for a sparse schema, so this'll do for now. Enforce these in the application code.
                -- LIVEMARKS
                , feedUri TEXT, siteUri TEXT
                -- SEPARATORS
                , pos INT
                -- FOLDERS, BOOKMARKS, QUERIES
                , title TEXT, description TEXT
                -- BOOKMARKS, QUERIES
                , bmkUri TEXT, tags TEXT, keyword TEXT
                -- QUERIES
                , folderName TEXT, queryId TEXT
                \(withAdditionalColumns)
                , CONSTRAINT parentidOrDeleted CHECK (parentid IS NOT NULL OR is_deleted = 1)
                , CONSTRAINT parentNameOrDeleted CHECK (parentName IS NOT NULL OR is_deleted = 1)
            )
            """

        return sql
    }

    /**
     * We need to explicitly store what's provided by the server, because we can't rely on
     * referenced child nodes to exist yet!
     */
    func getBookmarksStructureTableCreationStringForTable(_ table: String, referencingMirror mirror: String) -> String {
        let sql = """
            CREATE TABLE IF NOT EXISTS \(table) (
                parent TEXT NOT NULL REFERENCES \(mirror)(guid) ON DELETE CASCADE,
                -- Should be the GUID of a child.
                child TEXT NOT NULL,
                -- Should advance from 0.
                idx INTEGER NOT NULL
            )
            """

        return sql
    }

    // These triggers are used to keep the FTS index of the `history` table
    // in-sync after the initial "rebuild". The source for these triggers comes
    // directly from the SQLite documentation on maintaining external content FTS4
    // tables:
    // https://www.sqlite.org/fts3.html#_external_content_fts4_tables_
    fileprivate let historyBeforeUpdateTrigger = """
        CREATE TRIGGER \(TriggerHistoryBeforeUpdate) BEFORE UPDATE ON \(TableHistory) BEGIN
          DELETE FROM \(TableHistoryFTS) WHERE docid=old.rowid;
        END
        """
    fileprivate let historyBeforeDeleteTrigger = """
        CREATE TRIGGER \(TriggerHistoryBeforeDelete) BEFORE DELETE ON \(TableHistory) BEGIN
          DELETE FROM \(TableHistoryFTS) WHERE docid=old.rowid;
        END
        """
    fileprivate let historyAfterUpdateTrigger = """
        CREATE TRIGGER \(TriggerHistoryAfterUpdate) AFTER UPDATE ON \(TableHistory) BEGIN
          INSERT INTO \(TableHistoryFTS)(docid, url, title) VALUES (new.rowid, new.url, new.title);
        END
        """
    fileprivate let historyAfterInsertTrigger = """
        CREATE TRIGGER \(TriggerHistoryAfterInsert) AFTER INSERT ON \(TableHistory) BEGIN
          INSERT INTO \(TableHistoryFTS)(docid, url, title) VALUES (new.rowid, new.url, new.title);
        END
        """

    fileprivate let pendingBookmarksDeletions = """
        CREATE TABLE IF NOT EXISTS pending_deletions (
            id TEXT PRIMARY KEY REFERENCES bookmarksBuffer(guid) ON DELETE CASCADE
        )
        """

    fileprivate let remoteDevices = """
        CREATE TABLE IF NOT EXISTS remote_devices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            guid TEXT UNIQUE NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            is_current_device INTEGER NOT NULL,
            -- Timestamps in ms.
            date_created INTEGER NOT NULL,
            date_modified INTEGER NOT NULL,
            last_access_time INTEGER,
            availableCommands TEXT
        )
        """

    public func create(_ db: SQLiteDBConnection) -> Bool {
        let favicons = """
            CREATE TABLE IF NOT EXISTS favicons (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                url TEXT NOT NULL UNIQUE,
                width INTEGER,
                height INTEGER,
                type INTEGER NOT NULL,
                date REAL NOT NULL
            )
            """

        let history = """
            CREATE TABLE IF NOT EXISTS history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                -- Not null, but the value might be replaced by the server's.
                guid TEXT NOT NULL UNIQUE,
                -- May only be null for deleted records.
                url TEXT UNIQUE,
                title TEXT NOT NULL,
                -- Can be null. Integer milliseconds.
                server_modified INTEGER,
                -- Can be null. Client clock. In extremis only.
                local_modified INTEGER,
                -- Boolean. Locally deleted.
                is_deleted TINYINT NOT NULL,
                -- Boolean. Set when changed or visits added.
                should_upload TINYINT NOT NULL,
                domain_id INTEGER REFERENCES domains(id) ON DELETE CASCADE,
                CONSTRAINT urlOrDeleted CHECK (url IS NOT NULL OR is_deleted = 1)
            )
            """

        // Right now we don't need to track per-visit deletions: Sync can't
        // represent them! See Bug 1157553 Comment 6.
        // We flip the should_upload flag on the history item when we add a visit.
        // If we ever want to support logic like not bothering to sync if we added
        // and then rapidly removed a visit, then we need an 'is_new' flag on each visit.
        let visits = """
            CREATE TABLE IF NOT EXISTS visits (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE,
                -- Microseconds since epoch.
                date REAL NOT NULL,
                type INTEGER NOT NULL,
                -- Some visits are local. Some are remote ('mirrored'). This boolean flag is the split.
                is_local TINYINT NOT NULL,
                UNIQUE (siteID, date, type)
            )
            """

        let indexShouldUpload: String
        if self.supportsPartialIndices {
            // There's no point tracking rows that are not flagged for upload.
            indexShouldUpload = """
                CREATE INDEX IF NOT EXISTS idx_history_should_upload
                ON history (should_upload) WHERE should_upload = 1
                """
        } else {
            indexShouldUpload = """
                CREATE INDEX IF NOT EXISTS idx_history_should_upload
                ON history (should_upload)
                """
        }

        let indexSiteIDDate = """
            CREATE INDEX IF NOT EXISTS idx_visits_siteID_is_local_date
            ON visits (siteID, is_local, date)
            """

        let faviconSites = """
            CREATE TABLE IF NOT EXISTS favicon_sites (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE,
                faviconID INTEGER NOT NULL REFERENCES favicons(id) ON DELETE CASCADE,
                UNIQUE (siteID, faviconID)
            )
            """

        // Locally we track faviconID.
        // Local changes end up in the mirror, so we track it there too.
        // The buffer and the mirror additionally track some server metadata.
        let bookmarksLocal = getBookmarksTableCreationStringForTable(TableBookmarksLocal, withAdditionalColumns: self.localColumns + self.iconColumns)
        let bookmarksLocalStructure = getBookmarksStructureTableCreationStringForTable(TableBookmarksLocalStructure, referencingMirror: TableBookmarksLocal)
        let bookmarksBuffer = getBookmarksTableCreationStringForTable(TableBookmarksBuffer, withAdditionalColumns: self.serverColumns)
        let bookmarksBufferStructure = getBookmarksStructureTableCreationStringForTable(TableBookmarksBufferStructure, referencingMirror: TableBookmarksBuffer)
        let bookmarksMirror = getBookmarksTableCreationStringForTable(TableBookmarksMirror, withAdditionalColumns: self.serverColumns + self.mirrorColumns + self.iconColumns)
        let bookmarksMirrorStructure = getBookmarksStructureTableCreationStringForTable(TableBookmarksMirrorStructure, referencingMirror: TableBookmarksMirror)

        let indexLocalStructureParentIdx = """
            CREATE INDEX IF NOT EXISTS idx_bookmarksLocalStructure_parent_idx
            ON bookmarksLocalStructure (parent, idx)
            """
        let indexBufferStructureParentIdx = """
            CREATE INDEX IF NOT EXISTS idx_bookmarksBufferStructure_parent_idx
            ON bookmarksBufferStructure (parent, idx)
            """
        let indexMirrorStructureParentIdx = """
            CREATE INDEX IF NOT EXISTS idx_bookmarksMirrorStructure_parent_idx
            ON bookmarksMirrorStructure (parent, idx)
            """
        let indexMirrorStructureChild = """
            CREATE INDEX IF NOT EXISTS idx_bookmarksMirrorStructure_child
            ON bookmarksMirrorStructure (child)
            """

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
            historyFTSCreate,
            faviconSiteURLsCreate,

            // "Materialized Views" (Tables)
            awesomebarBookmarksWithFaviconsCreate,

            // Indices.
            indexBufferStructureParentIdx,
            indexLocalStructureParentIdx,
            indexMirrorStructureParentIdx,
            indexMirrorStructureChild,
            indexShouldUpload,
            indexSiteIDDate,

            // Triggers.
            historyBeforeUpdateTrigger,
            historyBeforeDeleteTrigger,
            historyAfterUpdateTrigger,
            historyAfterInsertTrigger,
        ]

        if queries.count != AllTablesIndicesTriggersAndViews.count {
            logger.log("Did you forget to add your table, index, trigger, or view to the list?",
                       level: .warning,
                       category: .storage)
        }
        assert(queries.count == AllTablesIndicesTriggersAndViews.count, "Did you forget to add your table, index, trigger, or view to the list?")

        logger.log("Creating \(queries.count) tables, views, triggers, and indices.",
                   level: .debug,
                   category: .storage)

        return self.run(db, queries: queries) &&
               self.prepopulateRootFolders(db)
    }

    public func update(_ db: SQLiteDBConnection, from: Int) -> Bool {
        let to = self.version
        if from == to {
            logger.log("Skipping update from \(from) to \(to).",
                       level: .debug,
                       category: .storage)
            return true
        }

        if from == 42 {
            if !self.run(db, queries: [
                "DROP VIEW IF EXISTS view_bookmarksBuffer_on_mirror",
                "DROP VIEW IF EXISTS view_bookmarksBuffer_with_deletions_on_mirror",
                "DROP VIEW IF EXISTS view_bookmarksBufferStructure_on_mirror",
                "DROP VIEW IF EXISTS view_bookmarksLocal_on_mirror",
                "DROP VIEW IF EXISTS view_bookmarksLocalStructure_on_mirror",
                "DROP VIEW IF EXISTS view_all_bookmarks",
                "DROP VIEW IF EXISTS view_awesomebar_bookmarks",
                "DROP VIEW IF EXISTS view_awesomebar_bookmarks_with_favicons",
                "DROP VIEW IF EXISTS view_history_visits",
                "DROP VIEW IF EXISTS view_favicons_widest",
                "DROP VIEW IF EXISTS view_history_id_favicon",
                "DROP VIEW IF EXISTS view_icon_for_url",
            ]) {
                return false
            }
        }

        return true
    }

    fileprivate func migrateFromSchemaTableIfNeeded(_ db: SQLiteDBConnection) -> Bool {
        logger.log("Checking if schema table migration is needed.",
                   level: .info,
                   category: .storage)

        // If `PRAGMA user_version` is v31 or later, we don't need to do anything here.
        guard db.version < 31 else {
            return true
        }

        // Query for the existence of the `tableList` table to determine if we are
        // migrating from an older DB version or if this is just a brand new DB.
        let sqliteMainCursor = db.executeQueryUnsafe("SELECT count(*) AS number FROM sqlite_master WHERE type = 'table' AND name = 'tableList'", factory: IntFactory, withArgs: [] as Args)

        let tableListTableExists = sqliteMainCursor[0] == 1
        sqliteMainCursor.close()

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
        logger.log("Schema table migrations complete; Dropping 'tableList' table.",
                   level: .info,
                   category: .storage)

        let sql = "DROP TABLE IF EXISTS tableList"
        do {
            try db.executeChange(sql)
        } catch let err as NSError {
            logger.log("Error dropping tableList table",
                       level: .warning,
                       category: .storage,
                       description: err.localizedDescription)
            return false
        }

        // Lastly, write the *previous* schema version (prior to v31) to the database
        // using `PRAGMA user_version = ?`.
        do {
            try db.setVersion(previousVersion)
        } catch let err as NSError {
            logger.log("Error setting database version",
                       level: .warning,
                       category: .storage,
                       description: err.localizedDescription)
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
        let sqliteMainCursor = db.executeQueryUnsafe("SELECT count(*) AS number FROM sqlite_master WHERE type = 'table' AND name = 'clients'", factory: IntFactory, withArgs: [] as Args)

        let clientsTableExists = sqliteMainCursor[0] == 1
        sqliteMainCursor.close()

        guard clientsTableExists else {
            return .skipped
        }

        // Check if intermediate migrations are necessary for the 'clients' table.
        let previousVersionCursor = db.executeQueryUnsafe("SELECT version FROM tableList WHERE name = 'clients'", factory: IntFactory, withArgs: [] as Args)

        let previousClientsTableVersion = previousVersionCursor[0] ?? 0
        previousVersionCursor.close()

        guard previousClientsTableVersion > 0 && previousClientsTableVersion <= 3 else {
            return .skipped
        }

        logger.log("Migrating 'clients' table from version \(previousClientsTableVersion).",
                   level: .info,
                   category: .storage)

        if previousClientsTableVersion < 2 {
            let sql = "ALTER TABLE clients ADD COLUMN version TEXT"
            do {
                try db.executeChange(sql)
            } catch let err as NSError {
                logger.log("Error altering clients table: \(err.localizedDescription); SQL was \(sql)",
                           level: .warning,
                           category: .storage)
                return .failure
            }
        }

        if previousClientsTableVersion < 3 {
            let sql = "ALTER TABLE clients ADD COLUMN fxaDeviceId TEXT"
            do {
                try db.executeChange(sql)
            } catch let err as NSError {
                let extra = ["table": "clients", "errorDescription": "\(err.localizedDescription)", "sql": "\(sql)"]
                logger.log("Error altering clients table",
                           level: .warning,
                           category: .storage,
                           extra: extra)
                return .failure
            }
        }

        return .success
    }

    fileprivate func fillDomainNamesFromCursor(_ cursor: Cursor<String>, db: SQLiteDBConnection) -> Bool {
        let cursorCount = cursor.count
        if cursorCount == 0 {
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
            logger.log("Can't create temporary table. Unable to migrate domain names. Top Sites is likely to be broken.",
                       level: .warning,
                       category: .storage)
            return false
        }

        // Now insert these into the temporary table. Chunk by an even number, for obvious reasons.
        let chunks = chunk(pairs, by: BrowserDB.MaxVariableNumber - (BrowserDB.MaxVariableNumber % 2))
        for chunk in chunks {
            let ins =
                "INSERT INTO \(tmpTable) (url, domain) VALUES " + [String](repeating: "(?, ?)", count: chunk.count / 2).joined(separator: ", ")
            if !self.run(db, sql: ins, args: Array(chunk)) {
                logger.log("Couldn't insert domains into temporary table. Aborting migration.",
                           level: .warning,
                           category: .storage)
                return false
            }
        }

        // Now make those into domains.
        let domains = "INSERT OR IGNORE INTO domains (domain) SELECT DISTINCT domain FROM \(tmpTable)"

        // … and fill that temporary column.
        let domainIDs = "UPDATE \(tmpTable) SET domain_id = (SELECT id FROM domains WHERE domains.domain = \(tmpTable).domain)"

        // Update the history table from the temporary table.
        let updateHistory = "UPDATE history SET domain_id = (SELECT domain_id FROM \(tmpTable) WHERE \(tmpTable).url = history.url)"

        // Clean up.
        let dropTemp = "DROP TABLE \(tmpTable)"

        // Now run these.
        if !self.run(db, queries: [domains,
                                   domainIDs,
                                   updateHistory,
                                   dropTemp]) {
            logger.log("Unable to migrate domains.",
                       level: .warning,
                       category: .storage)
            return false
        }

        return true
    }

    public func drop(_ db: SQLiteDBConnection) -> Bool {
        logger.log("Dropping all browser tables.",
                   level: .debug,
                   category: .storage)
        let additional = [
            "DROP TABLE IF EXISTS faviconSites" // We renamed it to match naming convention.
        ]

        let indices = AllIndices.map { "DROP INDEX IF EXISTS \($0)" }
        let tables = AllTables.map { "DROP TABLE IF EXISTS \($0)" }
        let queries = Array([indices, tables, additional].joined())
        return self.run(db, queries: queries)
    }
}
