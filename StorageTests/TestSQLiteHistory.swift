// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
@testable import Storage
@testable import Client

import XCTest

class BaseHistoricalBrowserSchema: Schema {
    var name: String { return "BROWSER" }
    var version: Int { return -1 }

    func update(_ db: SQLiteDBConnection, from: Int) -> Bool {
        fatalError("Should never be called.")
    }

    func create(_ db: SQLiteDBConnection) -> Bool {
        return false
    }

    func drop(_ db: SQLiteDBConnection) -> Bool {
        return false
    }

    var supportsPartialIndices: Bool {
        let v = sqlite3_libversion_number()
        return v >= 3008000          // 3.8.0.
    }

    let oldFaviconsSQL = """
        CREATE TABLE IF NOT EXISTS favicons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            url TEXT NOT NULL UNIQUE,
            width INTEGER,
            height INTEGER,
            type INTEGER NOT NULL,
            date REAL NOT NULL
        )
        """

    func run(_ db: SQLiteDBConnection, sql: String?, args: Args? = nil) -> Bool {
        if let sql = sql {
            do {
                try db.executeChange(sql, withArgs: args)
            } catch {
                return false
            }
        }

        return true
    }

    func run(_ db: SQLiteDBConnection, queries: [String?]) -> Bool {
        for sql in queries {
            if let sql = sql {
                if !run(db, sql: sql) {
                    return false
                }
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
}

// Versions of BrowserSchema that we care about:
// v6, prior to 001c73ea1903c238be1340950770879b40c41732, July 2015.
// This is when we first started caring about database versions.
//
// v7, 81e22fa6f7446e27526a5a9e8f4623df159936c3. History tiles.
//
// v8, 02c08ddc6d805d853bbe053884725dc971ef37d7. Favicons.
//
// v10, 4428c7d181ff4779ab1efb39e857e41bdbf4de67. Mirroring. We skipped v9.
//
// These tests snapshot the table creation code at each of these points.

class BrowserSchemaV6: BaseHistoricalBrowserSchema {
    override var version: Int { return 6 }

    func prepopulateRootFolders(_ db: SQLiteDBConnection) -> Bool {
        let type = 2 // "folder"
        let root = 0

        let titleMobile = String.BookmarksFolderTitleMobile
        let titleMenu = String.BookmarksFolderTitleMenu
        let titleToolbar = String.BookmarksFolderTitleToolbar
        let titleUnsorted = String.BookmarksFolderTitleUnsorted

        let args: Args = [
            root, BookmarkRoots.RootGUID, type, "Root", root,
            1, BookmarkRoots.MobileFolderGUID, type, titleMobile, root,
            2, BookmarkRoots.MenuFolderGUID, type, titleMenu, root,
            3, BookmarkRoots.ToolbarFolderGUID, type, titleToolbar, root,
            4, BookmarkRoots.UnfiledFolderGUID, type, titleUnsorted, root,
        ]

        let sql = """
            INSERT INTO bookmarks
                (id, guid, type, url, title, parent)
            VALUES
                -- Root
                (?, ?, ?, NULL, ?, ?),
                -- Mobile
                (?, ?, ?, NULL, ?, ?),
                -- Menu
                (?, ?, ?, NULL, ?, ?),
                -- Toolbar
                (?, ?, ?, NULL, ?, ?),
                -- Unsorted
                (?, ?, ?, NULL, ?, ?)
            """

        return self.run(db, sql: sql, args: args)
    }

    func CreateHistoryTable() -> String {
        let sql = """
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

        return sql
    }

    func CreateDomainsTable() -> String {
        let sql = """
            CREATE TABLE IF NOT EXISTS domains (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                domain TEXT NOT NULL UNIQUE,
                showOnTopSites TINYINT NOT NULL DEFAULT 1
            )
            """

        return sql
    }

    func CreateQueueTable() -> String {
        let sql = """
            CREATE TABLE IF NOT EXISTS queue (
                url TEXT NOT NULL UNIQUE,
                title TEXT
            )
            """

        return sql
    }

    override func create(_ db: SQLiteDBConnection) -> Bool {
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
            indexShouldUpload =
                "CREATE INDEX IF NOT EXISTS idx_history_should_upload ON history (should_upload) WHERE should_upload = 1"
        } else {
            indexShouldUpload =
                "CREATE INDEX IF NOT EXISTS idx_history_should_upload ON history (should_upload)"
        }

        let indexSiteIDDate =
            "CREATE INDEX IF NOT EXISTS idx_visits_siteID_is_local_date ON visits (siteID, is_local, date)"

        let faviconSites = """
            CREATE TABLE IF NOT EXISTS favicon_sites (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE,
                faviconID INTEGER NOT NULL REFERENCES favicons(id) ON DELETE CASCADE,
                UNIQUE (siteID, faviconID)
            )
            """

        let widestFavicons = """
            CREATE VIEW IF NOT EXISTS view_favicons_widest AS
            SELECT
                favicon_sites.siteID AS siteID,
                favicons.id AS iconID,
                favicons.url AS iconURL,
                favicons.date AS iconDate,
                favicons.type AS iconType,
                max(favicons.width) AS iconWidth
            FROM favicon_sites, favicons
            WHERE favicon_sites.faviconID = favicons.id
            GROUP BY siteID
            """

        let historyIDsWithIcon = """
            CREATE VIEW IF NOT EXISTS view_history_id_favicon AS
            SELECT history.id AS id, iconID, iconURL, iconDate, iconType, iconWidth
            FROM history LEFT OUTER JOIN view_favicons_widest ON
                history.id = view_favicons_widest.siteID
            """

        let iconForURL = """
            CREATE VIEW IF NOT EXISTS view_icon_for_url AS
            SELECT history.url AS url, icons.iconID AS iconID
            FROM history, view_favicons_widest AS icons
            WHERE history.id = icons.siteID
            """

        let bookmarks = """
            CREATE TABLE IF NOT EXISTS bookmarks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                guid TEXT NOT NULL UNIQUE,
                type TINYINT NOT NULL,
                url TEXT,
                parent INTEGER REFERENCES bookmarks(id) NOT NULL,
                faviconID INTEGER REFERENCES favicons(id) ON DELETE SET NULL,
                title TEXT
            )
            """

        let queries = [
            // This used to be done by FaviconsTable.
            self.oldFaviconsSQL,
            CreateDomainsTable(),
            CreateHistoryTable(),
            visits, bookmarks, faviconSites,
            indexShouldUpload, indexSiteIDDate,
            widestFavicons, historyIDsWithIcon, iconForURL,
            CreateQueueTable(),
        ]

        return self.run(db, queries: queries) &&
               self.prepopulateRootFolders(db)
    }
}

class BrowserSchemaV7: BaseHistoricalBrowserSchema {
    override var version: Int { return 7 }

    func prepopulateRootFolders(_ db: SQLiteDBConnection) -> Bool {
        let type = 2 // "folder"
        let root = 0

        let titleMobile = String.BookmarksFolderTitleMobile
        let titleMenu = String.BookmarksFolderTitleMenu
        let titleToolbar = String.BookmarksFolderTitleToolbar
        let titleUnsorted = String.BookmarksFolderTitleUnsorted

        let args: Args = [
            root, BookmarkRoots.RootGUID, type, "Root", root,
            1, BookmarkRoots.MobileFolderGUID, type, titleMobile, root,
            2, BookmarkRoots.MenuFolderGUID, type, titleMenu, root,
            3, BookmarkRoots.ToolbarFolderGUID, type, titleToolbar, root,
            4, BookmarkRoots.UnfiledFolderGUID, type, titleUnsorted, root,
        ]

        let sql = """
            INSERT INTO bookmarks
                (id, guid, type, url, title, parent)
            VALUES
                -- Root
                (?, ?, ?, NULL, ?, ?),
                -- Mobile
                (?, ?, ?, NULL, ?, ?),
                -- Menu
                (?, ?, ?, NULL, ?, ?),
                -- Toolbar
                (?, ?, ?, NULL, ?, ?),
                -- Unsorted
                (?, ?, ?, NULL, ?, ?)
            """

        return self.run(db, sql: sql, args: args)
    }

    func getHistoryTableCreationString() -> String {
        let sql = """
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

        return sql
    }

    func getDomainsTableCreationString() -> String {
        let sql = """
            CREATE TABLE IF NOT EXISTS domains (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                domain TEXT NOT NULL UNIQUE,
                showOnTopSites TINYINT NOT NULL DEFAULT 1
            )
            """

        return sql
    }

    func getQueueTableCreationString() -> String {
        let sql = """
            CREATE TABLE IF NOT EXISTS queue (
                url TEXT NOT NULL UNIQUE,
                title TEXT
            )
            """

        return sql
    }

    override func create(_ db: SQLiteDBConnection) -> Bool {
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
            indexShouldUpload =
                "CREATE INDEX IF NOT EXISTS idx_history_should_upload ON history (should_upload) WHERE should_upload = 1"
        } else {
            indexShouldUpload =
                "CREATE INDEX IF NOT EXISTS idx_history_should_upload ON history (should_upload)"
        }

        let indexSiteIDDate =
            "CREATE INDEX IF NOT EXISTS idx_visits_siteID_is_local_date ON visits (siteID, is_local, date)"

        let faviconSites = """
            CREATE TABLE IF NOT EXISTS favicon_sites (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE,
                faviconID INTEGER NOT NULL REFERENCES favicons(id) ON DELETE CASCADE,
                UNIQUE (siteID, faviconID)
            )
            """

        let widestFavicons = """
            CREATE VIEW IF NOT EXISTS view_favicons_widest AS
            SELECT
                favicon_sites.siteID AS siteID,
                favicons.id AS iconID,
                favicons.url AS iconURL,
                favicons.date AS iconDate,
                favicons.type AS iconType,
                max(favicons.width) AS iconWidth
            FROM favicon_sites, favicons
            WHERE favicon_sites.faviconID = favicons.id
            GROUP BY siteID
            """

        let historyIDsWithIcon = """
            CREATE VIEW IF NOT EXISTS view_history_id_favicon AS
            SELECT history.id AS id, iconID, iconURL, iconDate, iconType, iconWidth
            FROM history LEFT OUTER JOIN view_favicons_widest ON
                history.id = view_favicons_widest.siteID
            """

        let iconForURL = """
            CREATE VIEW IF NOT EXISTS view_icon_for_url AS
            SELECT history.url AS url, icons.iconID AS iconID
            FROM history, view_favicons_widest AS icons
            WHERE history.id = icons.siteID
            """

        let bookmarks = """
            CREATE TABLE IF NOT EXISTS bookmarks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                guid TEXT NOT NULL UNIQUE,
                type TINYINT NOT NULL,
                url TEXT,
                parent INTEGER REFERENCES bookmarks(id) NOT NULL,
                faviconID INTEGER REFERENCES favicons(id) ON DELETE SET NULL,
                title TEXT
            )
            """

        let queries = [
            // This used to be done by FaviconsTable.
            self.oldFaviconsSQL,
            getDomainsTableCreationString(),
            getHistoryTableCreationString(),
            visits, bookmarks, faviconSites,
            indexShouldUpload, indexSiteIDDate,
            widestFavicons, historyIDsWithIcon, iconForURL,
            getQueueTableCreationString(),
        ]

        return self.run(db, queries: queries) &&
               self.prepopulateRootFolders(db)
    }
}

class BrowserSchemaV8: BaseHistoricalBrowserSchema {
    override var version: Int { return 8 }

    func prepopulateRootFolders(_ db: SQLiteDBConnection) -> Bool {
        let type = 2 // "folder"
        let root = 0

        let titleMobile = String.BookmarksFolderTitleMobile
        let titleMenu = String.BookmarksFolderTitleMenu
        let titleToolbar = String.BookmarksFolderTitleToolbar
        let titleUnsorted = String.BookmarksFolderTitleUnsorted

        let args: Args = [
            root, BookmarkRoots.RootGUID, type, "Root", root,
            1, BookmarkRoots.MobileFolderGUID, type, titleMobile, root,
            2, BookmarkRoots.MenuFolderGUID, type, titleMenu, root,
            3, BookmarkRoots.ToolbarFolderGUID, type, titleToolbar, root,
            4, BookmarkRoots.UnfiledFolderGUID, type, titleUnsorted, root,
        ]

        let sql = """
            INSERT INTO bookmarks
                (id, guid, type, url, title, parent)
            VALUES
                -- Root
                (?, ?, ?, NULL, ?, ?),
                -- Mobile
                (?, ?, ?, NULL, ?, ?),
                -- Menu
                (?, ?, ?, NULL, ?, ?),
                -- Toolbar
                (?, ?, ?, NULL, ?, ?),
                -- Unsorted
                (?, ?, ?, NULL, ?, ?)
            """

        return self.run(db, sql: sql, args: args)
    }

    func getHistoryTableCreationString() -> String {
        let sql = """
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

        return sql
    }

    func getDomainsTableCreationString() -> String {
        let sql = """
            CREATE TABLE IF NOT EXISTS domains (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                domain TEXT NOT NULL UNIQUE,
                showOnTopSites TINYINT NOT NULL DEFAULT 1
            )
            """

        return sql
    }

    func getQueueTableCreationString() -> String {
        let sql = """
            CREATE TABLE IF NOT EXISTS queue (
                url TEXT NOT NULL UNIQUE,
                title TEXT
            )
            """

        return sql
    }

    override func create(_ db: SQLiteDBConnection) -> Bool {
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
            indexShouldUpload =
                "CREATE INDEX IF NOT EXISTS idx_history_should_upload ON history (should_upload) WHERE should_upload = 1"
        } else {
            indexShouldUpload =
                "CREATE INDEX IF NOT EXISTS idx_history_should_upload ON history (should_upload)"
        }

        let indexSiteIDDate =
            "CREATE INDEX IF NOT EXISTS idx_visits_siteID_is_local_date ON visits (siteID, is_local, date)"

        let faviconSites = """
            CREATE TABLE IF NOT EXISTS favicon_sites (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE,
                faviconID INTEGER NOT NULL REFERENCES favicons(id) ON DELETE CASCADE,
                UNIQUE (siteID, faviconID)
            )
            """

        let widestFavicons = """
            CREATE VIEW IF NOT EXISTS view_favicons_widest AS
            SELECT
                favicon_sites.siteID AS siteID,
                favicons.id AS iconID,
                favicons.url AS iconURL,
                favicons.date AS iconDate,
                favicons.type AS iconType,
                max(favicons.width) AS iconWidth
            FROM favicon_sites, favicons
            WHERE favicon_sites.faviconID = favicons.id
            GROUP BY siteID
            """

        let historyIDsWithIcon = """
            CREATE VIEW IF NOT EXISTS view_history_id_favicon AS
            SELECT history.id AS id, iconID, iconURL, iconDate, iconType, iconWidth
            FROM history LEFT OUTER JOIN view_favicons_widest ON
                history.id = view_favicons_widest.siteID
            """

        let iconForURL = """
            CREATE VIEW IF NOT EXISTS view_icon_for_url AS
            SELECT history.url AS url, icons.iconID AS iconID
            FROM history, view_favicons_widest AS icons
            WHERE history.id = icons.siteID
            """

        let bookmarks = """
            CREATE TABLE IF NOT EXISTS bookmarks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                guid TEXT NOT NULL UNIQUE,
                type TINYINT NOT NULL,
                url TEXT,
                parent INTEGER REFERENCES bookmarks(id) NOT NULL,
                faviconID INTEGER REFERENCES favicons(id) ON DELETE SET NULL,
                title TEXT
            )
            """

        let queries: [String] = [
            getDomainsTableCreationString(),
            getHistoryTableCreationString(),
            favicons,
            visits,
            bookmarks,
            faviconSites,
            indexShouldUpload,
            indexSiteIDDate,
            widestFavicons,
            historyIDsWithIcon,
            iconForURL,
            getQueueTableCreationString(),
        ]

        return self.run(db, queries: queries) &&
               self.prepopulateRootFolders(db)
    }
}

class BrowserSchemaV10: BaseHistoricalBrowserSchema {
    override var version: Int { return 10 }

    func prepopulateRootFolders(_ db: SQLiteDBConnection) -> Bool {
        let type = 2 // "folder"
        let root = 0

        let titleMobile = String.BookmarksFolderTitleMobile
        let titleMenu = String.BookmarksFolderTitleMenu
        let titleToolbar = String.BookmarksFolderTitleToolbar
        let titleUnsorted = String.BookmarksFolderTitleUnsorted

        let args: Args = [
            root, BookmarkRoots.RootGUID, type, "Root", root,
            1, BookmarkRoots.MobileFolderGUID, type, titleMobile, root,
            2, BookmarkRoots.MenuFolderGUID, type, titleMenu, root,
            3, BookmarkRoots.ToolbarFolderGUID, type, titleToolbar, root,
            4, BookmarkRoots.UnfiledFolderGUID, type, titleUnsorted, root,
        ]

        let sql = """
            INSERT INTO bookmarks
                (id, guid, type, url, title, parent)
            VALUES
                -- Root
                (?, ?, ?, NULL, ?, ?),
                -- Mobile
                (?, ?, ?, NULL, ?, ?),
                -- Menu
                (?, ?, ?, NULL, ?, ?),
                -- Toolbar
                (?, ?, ?, NULL, ?, ?),
                -- Unsorted
                (?, ?, ?, NULL, ?, ?)
            """

        return self.run(db, sql: sql, args: args)
    }

    func getHistoryTableCreationString(forVersion version: Int = BrowserSchema.DefaultVersion) -> String {
        let sql = """
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

        return sql
    }

    func getDomainsTableCreationString() -> String {
        let sql = """
            CREATE TABLE IF NOT EXISTS domains (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                domain TEXT NOT NULL UNIQUE,
                showOnTopSites TINYINT NOT NULL DEFAULT 1
            )
            """

        return sql
    }

    func getQueueTableCreationString() -> String {
        let sql = """
            CREATE TABLE IF NOT EXISTS queue (
                url TEXT NOT NULL UNIQUE,
                title TEXT
            )
            """

        return sql
    }

    func getBookmarksMirrorTableCreationString() -> String {
        // The stupid absence of naming conventions here is thanks to pre-Sync Weave. Sorry.
        // For now we have the simplest possible schema: everything in one.
        let sql = """
            CREATE TABLE IF NOT EXISTS bookmarksMirror
                -- Shared fields.
                ( id INTEGER PRIMARY KEY AUTOINCREMENT
                , guid TEXT NOT NULL UNIQUE
                -- Type enum. TODO: BookmarkNodeType needs to be extended.
                , type TINYINT NOT NULL
                -- Record/envelope metadata that'll allow us to do merges.
                -- Milliseconds.
                , server_modified INTEGER NOT NULL
                -- Boolean
                , is_deleted TINYINT NOT NULL DEFAULT 0
                -- Boolean, 0 (false) if deleted.
                , hasDupe TINYINT NOT NULL DEFAULT 0
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
    func getBookmarksMirrorStructureTableCreationString() -> String {
        let sql = """
            CREATE TABLE IF NOT EXISTS bookmarksMirrorStructure (
                parent TEXT NOT NULL REFERENCES bookmarksMirror(guid) ON DELETE CASCADE,
                -- Should be the GUID of a child.
                child TEXT NOT NULL,
                -- Should advance from 0.
                idx INTEGER NOT NULL
            )
            """

        return sql
    }

    override func create(_ db: SQLiteDBConnection) -> Bool {
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
            indexShouldUpload =
                "CREATE INDEX IF NOT EXISTS idx_history_should_upload ON history (should_upload) WHERE should_upload = 1"
        } else {
            indexShouldUpload =
                "CREATE INDEX IF NOT EXISTS idx_history_should_upload ON history (should_upload)"
        }

        let indexSiteIDDate =
            "CREATE INDEX IF NOT EXISTS idx_visits_siteID_is_local_date ON visits (siteID, is_local, date)"

        let faviconSites = """
            CREATE TABLE IF NOT EXISTS favicon_sites (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE,
                faviconID INTEGER NOT NULL REFERENCES favicons(id) ON DELETE CASCADE,
                UNIQUE (siteID, faviconID)
            )
            """

        let widestFavicons = """
            CREATE VIEW IF NOT EXISTS view_favicons_widest AS
            SELECT
                favicon_sites.siteID AS siteID,
                favicons.id AS iconID,
                favicons.url AS iconURL,
                favicons.date AS iconDate,
                favicons.type AS iconType,
                max(favicons.width) AS iconWidth
            FROM favicon_sites, favicons
            WHERE favicon_sites.faviconID = favicons.id
            GROUP BY siteID
            """

        let historyIDsWithIcon = """
            CREATE VIEW IF NOT EXISTS view_history_id_favicon AS
            SELECT history.id AS id, iconID, iconURL, iconDate, iconType, iconWidth
            FROM history LEFT OUTER JOIN view_favicons_widest ON
                history.id = view_favicons_widest.siteID
            """

        let iconForURL = """
            CREATE VIEW IF NOT EXISTS view_icon_for_url AS
            SELECT history.url AS url, icons.iconID AS iconID
            FROM history, view_favicons_widest AS icons
            WHERE history.id = icons.siteID
            """

        let bookmarks = """
            CREATE TABLE IF NOT EXISTS bookmarks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                guid TEXT NOT NULL UNIQUE,
                type TINYINT NOT NULL,
                url TEXT,
                parent INTEGER REFERENCES bookmarks(id) NOT NULL,
                faviconID INTEGER REFERENCES favicons(id) ON DELETE SET NULL,
                title TEXT
            )
            """

        let bookmarksMirror = getBookmarksMirrorTableCreationString()
        let bookmarksMirrorStructure = getBookmarksMirrorStructureTableCreationString()

        let indexStructureParentIdx =
            "CREATE INDEX IF NOT EXISTS idx_bookmarksMirrorStructure_parent_idx ON bookmarksMirrorStructure (parent, idx)"

        let queries: [String] = [
            getDomainsTableCreationString(),
            getHistoryTableCreationString(),
            favicons,
            visits,
            bookmarks,
            bookmarksMirror,
            bookmarksMirrorStructure,
            indexStructureParentIdx,
            faviconSites,
            indexShouldUpload,
            indexSiteIDDate,
            widestFavicons,
            historyIDsWithIcon,
            iconForURL,
            getQueueTableCreationString(),
        ]

        return self.run(db, queries: queries) &&
               self.prepopulateRootFolders(db)
    }
}

class TestSQLiteHistory: XCTestCase {
    let files = MockFiles()

    fileprivate func deleteDatabases() {
        for v in ["6", "7", "8", "10", "6-data"] {
            do {
                try files.remove("browser-v\(v).db")
            } catch {}
        }
        do {
            try files.remove("browser.db")
            try files.remove("historysynced.db")
        } catch {}
    }

    override func tearDown() {
        super.tearDown()
        self.deleteDatabases()
    }

    override func setUp() {
        super.setUp()

        // Just in case tearDown didn't run or succeed last time!
        self.deleteDatabases()
    }

    // Test that our visit partitioning for frecency is correct.
    func testHistoryLocalAndRemoteVisits() {
        let db = BrowserDB(filename: "testHistoryLocalAndRemoteVisits.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let siteL = Site(url: "http://url1/", title: "title local only")
        let siteR = Site(url: "http://url2/", title: "title remote only")
        let siteB = Site(url: "http://url3/", title: "title local and remote")

        siteL.guid = "locallocal12"
        siteR.guid = "remoteremote"
        siteB.guid = "bothbothboth"

        let siteVisitL1 = SiteVisit(site: siteL, date: baseInstantInMicros + 1000, type: VisitType.link)
        let siteVisitL2 = SiteVisit(site: siteL, date: baseInstantInMicros + 2000, type: VisitType.link)

        let siteVisitR1 = SiteVisit(site: siteR, date: baseInstantInMicros + 1000, type: VisitType.link)
        let siteVisitR2 = SiteVisit(site: siteR, date: baseInstantInMicros + 2000, type: VisitType.link)
        let siteVisitR3 = SiteVisit(site: siteR, date: baseInstantInMicros + 3000, type: VisitType.link)

        let siteVisitBL1 = SiteVisit(site: siteB, date: baseInstantInMicros + 4000, type: VisitType.link)
        let siteVisitBR1 = SiteVisit(site: siteB, date: baseInstantInMicros + 5000, type: VisitType.link)

        let deferred =
        history.clearHistory()
            >>> { history.addLocalVisit(siteVisitL1) }
            >>> { history.addLocalVisit(siteVisitL2) }
            >>> { history.addLocalVisit(siteVisitBL1) }
            >>> { history.insertOrUpdatePlace(siteL.asPlace(), modified: baseInstantInMillis + 2) }
            >>> { history.insertOrUpdatePlace(siteR.asPlace(), modified: baseInstantInMillis + 3) }
            >>> { history.insertOrUpdatePlace(siteB.asPlace(), modified: baseInstantInMillis + 5) }

            // Do this step twice, so we exercise the dupe-visit handling.
            >>> { history.storeRemoteVisits([siteVisitR1, siteVisitR2, siteVisitR3], forGUID: siteR.guid!) }
            >>> { history.storeRemoteVisits([siteVisitR1, siteVisitR2, siteVisitR3], forGUID: siteR.guid!) }

            >>> { history.storeRemoteVisits([siteVisitBR1], forGUID: siteB.guid!) }

            >>> {
                history.getFrecentHistory().getSites(matchingSearchQuery: nil, limit: 3)
                >>== { (sites: Cursor) -> Success in
                    XCTAssertEqual(3, sites.count)

                    // Two local visits beat a single later remote visit and one later local visit.
                    // Two local visits beat three remote visits.
                    XCTAssertEqual(siteL.guid!, sites[0]!.guid!)
                    XCTAssertEqual(siteB.guid!, sites[1]!.guid!)
                    XCTAssertEqual(siteR.guid!, sites[2]!.guid!)
                    return succeed()
            }

            // This marks everything as modified so we can fetch it.
            >>> history.onRemovedAccount

            // Now check that we have no duplicate visits.
            >>> { history.getModifiedHistoryToUpload()
                >>== { (places) -> Success in
                    if let (_, visits) = places.find({$0.0.guid == siteR.guid!}) {
                        XCTAssertEqual(3, visits.count)
                    } else {
                        XCTFail("Couldn't find site R.")
                    }
                    return succeed()
                }
            }
        }

        XCTAssertTrue(deferred.value.isSuccess)
    }

    func testUpgrades() {
        let sources: [(Int, Schema)] = [
            (6, BrowserSchemaV6()),
            (7, BrowserSchemaV7()),
            (8, BrowserSchemaV8()),
            (10, BrowserSchemaV10()),
        ]

        let destination = BrowserSchema()

        for (version, schema) in sources {
            var db = BrowserDB(filename: "browser-v\(version).db", schema: schema, files: files)
            XCTAssertTrue(db.withConnection({ connection -> Int in
                connection.version
            }).value.successValue == schema.version, "Creating BrowserSchema at version \(version)")
            db.forceClose()

            db = BrowserDB(filename: "browser-v\(version).db", schema: destination, files: files)
            XCTAssertTrue(db.withConnection({ connection -> Int in
                connection.version
            }).value.successValue == destination.version, "Upgrading BrowserSchema from version \(version) to version \(schema.version)")
            db.forceClose()
        }
    }

    func testUpgradesWithData() {
        var db = BrowserDB(filename: "browser-v6-data.db", schema: BrowserSchemaV6(), files: files)

        // Insert some data.
        let queries = [
            "INSERT INTO domains (id, domain) VALUES (1, 'example.com')",
            "INSERT INTO history (id, guid, url, title, server_modified, local_modified, is_deleted, should_upload, domain_id) VALUES (5, 'guid', 'http://www.example.com', 'title', 5, 10, 0, 1, 1)",
            "INSERT INTO visits (siteID, date, type, is_local) VALUES (5, 15, 1, 1)",
            "INSERT INTO favicons (url, width, height, type, date) VALUES ('http://www.example.com/favicon.ico', 10, 10, 1, 20)",
            "INSERT INTO favicon_sites (siteID, faviconID) VALUES (5, 1)",
            "INSERT INTO bookmarks (guid, type, url, parent, faviconID, title) VALUES ('guid', 1, 'http://www.example.com', 0, 1, 'title')"
        ]

        XCTAssertTrue(db.run(queries).value.isSuccess)

        // And we can upgrade to the current version.
        db = BrowserDB(filename: "browser-v6-data.db", schema: BrowserSchema(), files: files)

        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)
        let results = history.getSitesByLastVisit(limit: 10, offset: 0).value.successValue
        XCTAssertNotNil(results)
        XCTAssertEqual(results![0]?.url, "http://www.example.com")

        db.forceClose()
    }

    func testDomainUpgrade() {
        let db = BrowserDB(filename: "testDomainUpgrade.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let site = Site(url: "http://www.example.com/test1.4", title: "title one")

        // Insert something with an invalid domain ID. We have to manually do this since domains are usually hidden.
        let insertDeferred = db.withConnection { connection -> Void in
            try connection.executeChange("PRAGMA foreign_keys = OFF")
            let insert = "INSERT OR REPLACE INTO history (guid, url, title, local_modified, is_deleted, should_upload, domain_id) VALUES (?, ?, ?, ?, ?, ?, ?)"
            let args: Args = [Bytes.generateGUID(), site.url, site.title, Date.now(), 0, 0, -1]
            try connection.executeChange(insert, withArgs: args)
        }

        XCTAssertTrue(insertDeferred.value.isSuccess)

        // Now insert it again. This should update the domain.
        history.addLocalVisit(SiteVisit(site: site, date: Date.nowMicroseconds(), type: VisitType.link)).succeeded()

        // domain_id isn't normally exposed, so we manually query to get it.
        let resultsDeferred = db.withConnection { connection -> Cursor<Int?> in
            let sql = "SELECT domain_id FROM history WHERE url = ?"
            let args: Args = [site.url]
            return connection.executeQuery(sql, factory: { $0[0] as? Int }, withArgs: args)
        }

        let results = resultsDeferred.value.successValue!
        let domain = results[0]!         // Unwrap to get the first item from the cursor.
        XCTAssertNil(domain)
    }

    func testDomains() {
        let db = BrowserDB(filename: "testDomains.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let initialGuid = Bytes.generateGUID()
        let site11 = Site(url: "http://www.example.com/test1.1", title: "title one")
        let site12 = Site(url: "http://www.example.com/test1.2", title: "title two")
        let site13 = Place(guid: initialGuid, url: "http://www.example.com/test1.3", title: "title three")
        let site3 = Site(url: "http://www.example2.com/test1", title: "title three")
        let expectation = self.expectation(description: "First.")

        let clearTopSites = "DELETE FROM cached_top_sites"
        let updateTopSites: [(String, Args?)] = [(clearTopSites, nil), (history.getFrecentHistory().updateTopSitesCacheQuery())]

        func countTopSites() -> Deferred<Maybe<Cursor<Int>>> {
            return db.runQuery("SELECT count(*) FROM cached_top_sites", args: nil, factory: { sdrow -> Int in
                return sdrow[0] as? Int ?? 0
            })
        }

        history.clearHistory().bind({ success in
            return all([history.addLocalVisit(SiteVisit(site: site11, date: Date.nowMicroseconds(), type: VisitType.link)),
                        history.addLocalVisit(SiteVisit(site: site12, date: Date.nowMicroseconds(), type: VisitType.link)),
                        history.addLocalVisit(SiteVisit(site: site3, date: Date.nowMicroseconds(), type: VisitType.link))])
        }).bind({ (results: [Maybe<()>]) in
            return history.insertOrUpdatePlace(site13, modified: Date.nowMicroseconds())
        }).bind({ guid -> Success in
            XCTAssertEqual(guid.successValue!, initialGuid, "Guid is correct")
            return db.run(updateTopSites)
        }).bind({ success in
            XCTAssertTrue(success.isSuccess, "update was successful")
            return countTopSites()
        }).bind({ (count: Maybe<Cursor<Int>>) -> Success in
            XCTAssert(count.successValue![0] == 2, "2 sites returned")
            return history.removeSiteFromTopSites(site11)
        }).bind({ success -> Success in
            XCTAssertTrue(success.isSuccess, "Remove was successful")
            return db.run(updateTopSites)
        }).bind({ success -> Deferred<Maybe<Cursor<Int>>> in
            XCTAssertTrue(success.isSuccess, "update was successful")
            return countTopSites()
        })
        .upon({ (count: Maybe<Cursor<Int>>) in
            XCTAssert(count.successValue![0] == 1, "1 site returned")
            expectation.fulfill()
        })

        waitForExpectations(timeout: 10.0) { error in
            return
        }
    }

    func testHistoryIsSynced() {
        let db = BrowserDB(filename: "historysynced.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let initialGUID = Bytes.generateGUID()
        let site = Place(guid: initialGUID, url: "http://www.example.com/test1.3", title: "title")

        XCTAssertFalse(history.hasSyncedHistory().value.successValue ?? true)

        XCTAssertTrue(history.insertOrUpdatePlace(site, modified: Date.now()).value.isSuccess)

        XCTAssertTrue(history.hasSyncedHistory().value.successValue ?? false)
    }

    // This is a very basic test. Adds an entry, retrieves it, updates it,
    // and then clears the database.
    func testHistoryTable() {
        let db = BrowserDB(filename: "testHistoryTable.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let site1 = Site(url: "http://url1/", title: "title one")
        let site1Changed = Site(url: "http://url1/", title: "title one alt")

        let siteVisit1 = SiteVisit(site: site1, date: Date.nowMicroseconds(), type: VisitType.link)
        let siteVisit2 = SiteVisit(site: site1Changed, date: Date.nowMicroseconds() + 1000, type: VisitType.bookmark)

        let site2 = Site(url: "http://url2/", title: "title two")
        let siteVisit3 = SiteVisit(site: site2, date: Date.nowMicroseconds() + 2000, type: VisitType.link)

        let expectation = self.expectation(description: "First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func checkSitesByFrecency(_ f: @escaping (Cursor<Site>) -> Success) -> () -> Success {
            return {
                history.getFrecentHistory().getSites(matchingSearchQuery: nil, limit: 10)
                    >>== f
            }
        }

        func checkSitesByDate(_ f: @escaping (Cursor<Site>) -> Success) -> () -> Success {
            return {
                history.getSitesByLastVisit(limit: 10, offset: 0)
                >>== f
            }
        }

        func checkSitesWithFilter(_ filter: String, f: @escaping (Cursor<Site>) -> Success) -> () -> Success {
            return {
                history.getFrecentHistory().getSites(matchingSearchQuery: filter, limit: 10)
                >>== f
            }
        }

        func checkDeletedCount(_ expected: Int) -> () -> Success {
            return {
                history.getDeletedHistoryToUpload()
                >>== { guids in
                    XCTAssertEqual(expected, guids.count)
                    return succeed()
                }
            }
        }

        history.clearHistory()
            >>> { history.addLocalVisit(siteVisit1) }
            >>> checkSitesByFrecency { (sites: Cursor) -> Success in
                XCTAssertEqual(1, sites.count)
                XCTAssertEqual(site1.title, sites[0]!.title)
                XCTAssertEqual(site1.url, sites[0]!.url)
                sites.close()
                return succeed()
            }
            >>> { history.addLocalVisit(siteVisit2) }
            >>> checkSitesByFrecency { (sites: Cursor) -> Success in
                XCTAssertEqual(1, sites.count)
                XCTAssertEqual(site1Changed.title, sites[0]!.title)
                XCTAssertEqual(site1Changed.url, sites[0]!.url)
                sites.close()
                return succeed()
            }
            >>> { history.addLocalVisit(siteVisit3) }
            >>> checkSitesByFrecency { (sites: Cursor) -> Success in
                XCTAssertEqual(2, sites.count)
                // They're in order of frecency.
                XCTAssertEqual(site1Changed.title, sites[0]!.title)
                XCTAssertEqual(site2.title, sites[1]!.title)
                return succeed()
            }
            >>> checkSitesByDate { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(2, sites.count)
                // They're in order of date last visited.
                let first = sites[0]!
                let second = sites[1]!
                XCTAssertEqual(site2.title, first.title)
                XCTAssertEqual(site1Changed.title, second.title)
                XCTAssertTrue(siteVisit3.date == first.latestVisit!.date)
                return succeed()
            }
            >>> checkSitesWithFilter("two") { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(1, sites.count)
                let first = sites[0]!
                XCTAssertEqual(site2.title, first.title)
                return succeed()
            }
            >>>
            checkDeletedCount(0)
            >>> { history.removeHistoryForURL("http://url2/") }
            >>>
            checkDeletedCount(1)
            >>> checkSitesByFrecency { (sites: Cursor) -> Success in
                    XCTAssertEqual(1, sites.count)
                    // They're in order of frecency.
                    XCTAssertEqual(site1Changed.title, sites[0]!.title)
                    return succeed()
            }
            >>> { history.clearHistory() }
            >>>
            checkDeletedCount(0)
            >>> checkSitesByDate { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(0, sites.count)
                return succeed()
            }
            >>> checkSitesByFrecency { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(0, sites.count)
                return succeed()
            }
            >>> done

        waitForExpectations(timeout: 10.0) { error in
            return
        }
    }

    func testRemoveRecentHistory() {
        let db = BrowserDB(filename: "testRemoveRecentHistory.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        func delete(date: Date, expectedDeletions: Int) {
            history.clearHistory().succeeded()
            let siteL = Site(url: "http://url1/", title: "title local only")
            let siteR = Site(url: "http://url2/", title: "title remote only")
            let siteB = Site(url: "http://url3/", title: "title local and remote")
            siteL.guid = "locallocal12"
            siteR.guid = "remoteremote"
            siteB.guid = "bothbothboth"
            // Site visit uses microsec timestamp
            let siteVisitL1 = SiteVisit(site: siteL, date: 1_000_000, type: VisitType.link)
            let siteVisitL2 = SiteVisit(site: siteR, date: 2_000_000, type: VisitType.link)
            let siteVisitBL1 = SiteVisit(site: siteB, date: 4_000_000, type: VisitType.link)

            let deferred = history.addLocalVisit(siteVisitL1)
                    >>> { history.addLocalVisit(siteVisitL2) }
                    >>> { history.addLocalVisit(siteVisitBL1) }
                    >>> { history.insertOrUpdatePlace(siteL.asPlace(), modified: baseInstantInMillis + 2) }
                    >>> { history.insertOrUpdatePlace(siteR.asPlace(), modified: baseInstantInMillis + 3) }
                    >>> { history.insertOrUpdatePlace(siteB.asPlace(), modified: baseInstantInMillis + 5) }

            XCTAssert(deferred.value.isSuccess)

            history.removeHistoryFromDate(date).succeeded()
            history.getDeletedHistoryToUpload() >>== { guids in
                XCTAssertEqual(expectedDeletions, guids.count)
            }
        }

        delete(date: Date(timeIntervalSinceNow: 0), expectedDeletions: 0)
        delete(date: Date(timeIntervalSince1970: 0), expectedDeletions: 3)
        delete(date: Date(timeIntervalSince1970: 3), expectedDeletions: 1)
    }

    func testRemoveHistoryForUrl() {
        let db = BrowserDB(filename: "testRemoveHistoryForUrl.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        history.setTopSitesCacheSize(20)
        history.clearTopSitesCache().succeeded()
        history.clearHistory().succeeded()

        // Lets create some history. This will create 3 sites that will have 4 local and 4 remote visits
        populateHistoryForFrecencyCalculations(history, siteCount: 3)

        history.removeHistoryForURL("http://s0ite0.com/foo").succeeded()
        history.removeHistoryForURL("http://s1ite1.com/foo").succeeded()

        let deletedResult = history.getDeletedHistoryToUpload().value
        XCTAssertTrue(deletedResult.isSuccess)
        let guids = deletedResult.successValue!
        XCTAssertEqual(2, guids.count)
    }

    func testTopSitesFrecencyOrder() {
        let db = BrowserDB(filename: "testTopSitesFrecencyOrder.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        history.setTopSitesCacheSize(20)
        history.clearTopSitesCache().succeeded()
        history.clearHistory().succeeded()

        // Lets create some history. This will create 100 sites that will have 4 local and 4 remote visits
        populateHistoryForFrecencyCalculations(history, siteCount: 100)

        // Create a new site thats for an existing domain but a different URL.
        let site = Site(url: "http://s\(5)ite\(5).com/foo-different-url", title: "A \(5) different url")
        site.guid = "abc\(5)defhi"
        history.insertOrUpdatePlace(site.asPlace(), modified: baseInstantInMillis - 20000).succeeded()
        // Don't give it any remote visits. But give it 100 local visits. This should be the new Topsite!
        for i in 0...100 {
            addVisitForSite(site, intoHistory: history, from: .local, atTime: advanceTimestamp(baseInstantInMicros, by: 1000000 * i))
        }

        let expectation = self.expectation(description: "First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func loadCache() -> Success {
            return history.repopulate(invalidateTopSites: true) >>> succeed
        }

        func checkTopSitesReturnsResults() -> Success {
            return history.getTopSitesWithLimit(20) >>== { topSites in
                XCTAssertEqual(topSites.count, 20)
                XCTAssertEqual(topSites[0]!.guid, "abc\(5)defhi")
                return succeed()
            }
        }

        loadCache()
            >>> checkTopSitesReturnsResults
            >>> done

        waitForExpectations(timeout: 10.0) { error in
            return
        }
    }

    func testTopSitesFiltersGoogle() {
        let db = BrowserDB(filename: "testTopSitesFiltersGoogle.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        history.setTopSitesCacheSize(20)
        history.clearTopSitesCache().succeeded()
        history.clearHistory().succeeded()
        // Lets create some history. This will create 100 sites that will have 21 local and 21 remote visits
        populateHistoryForFrecencyCalculations(history, siteCount: 100)

        func createTopSite(url: String, guid: String) {
            let site = Site(url: url, title: "Hi")
            site.guid = guid
            history.insertOrUpdatePlace(site.asPlace(), modified: baseInstantInMillis - 20000).succeeded()
            // Don't give it any remote visits. But give it 100 local visits. This should be the new Topsite!
            for i in 0...100 {
                addVisitForSite(site, intoHistory: history, from: .local, atTime: advanceTimestamp(baseInstantInMicros, by: 1000000 * i))
            }
        }

        createTopSite(url: "http://google.com", guid: "abcgoogle") // should not be a topsite
        createTopSite(url: "http://www.google.com", guid: "abcgoogle1") // should not be a topsite
        createTopSite(url: "http://google.co.za", guid: "abcgoogleza") // should not be a topsite
        createTopSite(url: "http://docs.google.com", guid: "docsgoogle") // should be a topsite

        let expectation = self.expectation(description: "First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func loadCache() -> Success {
            return history.repopulate(invalidateTopSites: true) >>> succeed
        }

        func checkTopSitesReturnsResults() -> Success {
            return history.getTopSitesWithLimit(20) >>== { topSites in
                XCTAssertEqual(topSites[0]?.guid, "docsgoogle") // google docs should be the first topsite
                // make sure all other google guids are not in the topsites array
                topSites.forEach {
                    let guid: String = $0!.guid! // type checking is hard
                    XCTAssertNil(["abcgoogle", "abcgoogle1", "abcgoogleza"].firstIndex(of: guid))
                }
                XCTAssertEqual(topSites.count, 20)
                return succeed()
            }
        }

        loadCache()
            >>> checkTopSitesReturnsResults
            >>> done

        waitForExpectations(timeout: 10.0) { error in
            return
        }
    }

    func testTopSitesCache() {
        let db = BrowserDB(filename: "testTopSitesCache.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        history.setTopSitesCacheSize(20)
        history.clearTopSitesCache().succeeded()
        history.clearHistory().succeeded()

        // Make sure that we get back the top sites
        populateHistoryForFrecencyCalculations(history, siteCount: 100)

        // Add extra visits to the 5th site to bubble it to the top of the top sites cache
        let site = Site(url: "http://s\(5)ite\(5).com/foo", title: "A \(5)")
        site.guid = "abc\(5)def"
        for i in 0...20 {
            addVisitForSite(site, intoHistory: history, from: .local, atTime: advanceTimestamp(baseInstantInMicros, by: 1000000 * i))
        }

        let expectation = self.expectation(description: "First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func loadCache() -> Success {
            return history.repopulate(invalidateTopSites: true) >>> succeed
        }

        func checkTopSitesReturnsResults() -> Success {
            return history.getTopSitesWithLimit(20) >>== { topSites in
                XCTAssertEqual(topSites.count, 20)
                XCTAssertEqual(topSites[0]!.guid, "abc\(5)def")
                return succeed()
            }
        }

        func invalidateIfNeededDoesntChangeResults() -> Success {
            return history.repopulate(invalidateTopSites: true) >>> {
                return history.getTopSitesWithLimit(20) >>== { topSites in
                    XCTAssertEqual(topSites.count, 20)
                    XCTAssertEqual(topSites[0]!.guid, "abc\(5)def")
                    return succeed()
                }
            }
        }

        func addVisitsToZerothSite() -> Success {
            let site = Site(url: "http://s\(0)ite\(0).com/foo", title: "A \(0)")
            site.guid = "abc\(0)def"
            for i in 0...20 {
                addVisitForSite(site, intoHistory: history, from: .local, atTime: advanceTimestamp(baseInstantInMicros, by: 1000000 * i))
            }
            return succeed()
        }

        func markInvalidation() -> Success {
            history.setTopSitesNeedsInvalidation()
            return succeed()
        }

        func checkSitesInvalidate() -> Success {
            history.repopulate(invalidateTopSites: true).succeeded()

            return history.getTopSitesWithLimit(20) >>== { topSites in
                XCTAssertEqual(topSites.count, 20)
                XCTAssertEqual(topSites[0]!.guid, "abc\(5)def")
                XCTAssertEqual(topSites[1]!.guid, "abc\(0)def")
                return succeed()
            }
        }

        loadCache()
            >>> checkTopSitesReturnsResults
            >>> invalidateIfNeededDoesntChangeResults
            >>> markInvalidation
            >>> addVisitsToZerothSite
            >>> checkSitesInvalidate
            >>> done

        waitForExpectations(timeout: 10.0) { error in
            return
        }
    }

    func testPinnedTopSites() {
        let db = BrowserDB(filename: "testPinnedTopSites.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        history.setTopSitesCacheSize(20)
        history.clearTopSitesCache().succeeded()
        history.clearHistory().succeeded()

        // add 2 sites to pinned topsite
        // get pinned site and make sure it exists in the right order
        // remove pinned sites
        // make sure pinned sites dont exist

        // create pinned sites.
        let site1 = Site(url: "http://s\(1)ite\(1).com/foo", title: "A \(1)")
        site1.id = 1
        site1.guid = "abc\(1)def"
        addVisitForSite(site1, intoHistory: history, from: .local, atTime: Date.now())
        let site2 = Site(url: "http://s\(2)ite\(2).com/foo", title: "A \(2)")
        site2.id = 2
        site2.guid = "abc\(2)def"
        addVisitForSite(site2, intoHistory: history, from: .local, atTime: Date.now())


        let expectation = self.expectation(description: "First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func addPinnedSites() -> Success {
            return history.addPinnedTopSite(site1) >>== {
                sleep(1) // Sleep to prevent intermittent issue with sorting on the timestamp
                return history.addPinnedTopSite(site2)
            }
        }

        func checkPinnedSites() -> Success {
            return history.getPinnedTopSites() >>== { pinnedSites in
                XCTAssertEqual(pinnedSites.count, 2)
                XCTAssertEqual(pinnedSites[0]!.url, site2.url)
                XCTAssertEqual(pinnedSites[1]!.url, site1.url, "The older pinned site should be last")
                return succeed()
            }
        }

        func removePinnedSites() -> Success {
            return history.removeFromPinnedTopSites(site2) >>== {
                return history.getPinnedTopSites() >>== { pinnedSites in
                    XCTAssertEqual(pinnedSites.count, 1, "There should only be one pinned site")
                    XCTAssertEqual(pinnedSites[0]!.url, site1.url, "Site2 should be the only pin left")
                    return succeed()
                }
            }
        }

        func dupePinnedSite() -> Success {
            return history.addPinnedTopSite(site1) >>== {
                return history.getPinnedTopSites() >>== { pinnedSites in
                    XCTAssertEqual(pinnedSites.count, 1, "There should not be a dupe")
                    XCTAssertEqual(pinnedSites[0]!.url, site1.url, "Site2 should be the only pin left")
                    return succeed()
                }
            }
        }

        func removeHistory() -> Success {
            return history.clearHistory() >>== {
                return history.getPinnedTopSites() >>== { pinnedSites in
                    XCTAssertEqual(pinnedSites.count, 1, "Pinned sites should exist after a history clear")
                    return succeed()
                }
            }
        }

        addPinnedSites()
            >>> checkPinnedSites
            >>> removePinnedSites
            >>> dupePinnedSite
            >>> removeHistory
            >>> done

        waitForExpectations(timeout: 10.0) { error in
            return
        }

    }
}

class TestSQLiteHistoryTransactionUpdate: XCTestCase {
    func testUpdateInTransaction() {
        let files = MockFiles()
        let db = BrowserDB(filename: "testUpdateInTransaction.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        history.clearHistory().succeeded()
        let site = Site(url: "http://site.example/foo", title: "AA")
        site.guid = "abcdefghiabc"

        history.insertOrUpdatePlace(site.asPlace(), modified: 1234567890).succeeded()

        let ts: MicrosecondTimestamp = baseInstantInMicros
        let local = SiteVisit(site: site, date: ts, type: VisitType.link)
        XCTAssertTrue(history.addLocalVisit(local).value.isSuccess)

        // Doing it again is a no-op and will not fail.
        history.insertOrUpdatePlace(site.asPlace(), modified: 1234567890).succeeded()
    }
}
