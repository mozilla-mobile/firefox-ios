/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage

import XCTest

func advanceTimestamp(timestamp: Timestamp, by: Int) -> Timestamp {
    return timestamp + UInt64(by)
}

func advanceMicrosecondTimestamp(timestamp: MicrosecondTimestamp, by: Int) -> MicrosecondTimestamp {
    return timestamp + UInt64(by)
}

extension Site {
    func asPlace() -> Place {
        return Place(guid: self.guid!, url: self.url, title: self.title)
    }
}

class BaseHistoricalBrowserTable {
    func updateTable(db: SQLiteDBConnection, from: Int) -> Bool {
        assert(false, "Should never be called.")
    }

    func exists(db: SQLiteDBConnection) -> Bool {
        return false
    }

    func drop(db: SQLiteDBConnection) -> Bool {
        return false
    }

    var supportsPartialIndices: Bool {
        let v = sqlite3_libversion_number()
        return v >= 3008000          // 3.8.0.
    }

    let oldFaviconsSQL =
        "CREATE TABLE IF NOT EXISTS favicons (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "url TEXT NOT NULL UNIQUE, " +
        "width INTEGER, " +
        "height INTEGER, " +
        "type INTEGER NOT NULL, " +
        "date REAL NOT NULL" +
        ") "

    func run(db: SQLiteDBConnection, sql: String?, args: Args? = nil) -> Bool {
        if let sql = sql {
            let err = db.executeChange(sql, withArgs: args)
            return err == nil
        }
        return true
    }

    func run(db: SQLiteDBConnection, queries: [String?]) -> Bool {
        for sql in queries {
            if let sql = sql {
                if !run(db, sql: sql) {
                    return false
                }
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
}

// Versions of BrowserTable that we care about:
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

class BrowserTableV6: BaseHistoricalBrowserTable {
    var name: String { return "BROWSER" }
    var version: Int { return 6 }

    func prepopulateRootFolders(db: SQLiteDBConnection) -> Bool {
        let type = BookmarkNodeType.Folder.rawValue
        let root = BookmarkRoots.RootID

        let titleMobile = NSLocalizedString("Mobile Bookmarks", tableName: "Storage", comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.")
        let titleMenu = NSLocalizedString("Bookmarks Menu", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.")
        let titleToolbar = NSLocalizedString("Bookmarks Toolbar", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.")
        let titleUnsorted = NSLocalizedString("Unsorted Bookmarks", tableName: "Storage", comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.")

        let args: Args = [
            root, BookmarkRoots.RootGUID, type, "Root", root,
            BookmarkRoots.MobileID, BookmarkRoots.MobileFolderGUID, type, titleMobile, root,
            BookmarkRoots.MenuID, BookmarkRoots.MenuFolderGUID, type, titleMenu, root,
            BookmarkRoots.ToolbarID, BookmarkRoots.ToolbarFolderGUID, type, titleToolbar, root,
            BookmarkRoots.UnfiledID, BookmarkRoots.UnfiledFolderGUID, type, titleUnsorted, root,
        ]

        let sql =
        "INSERT INTO bookmarks (id, guid, type, url, title, parent) VALUES " +
            "(?, ?, ?, NULL, ?, ?), " +    // Root
            "(?, ?, ?, NULL, ?, ?), " +    // Mobile
            "(?, ?, ?, NULL, ?, ?), " +    // Menu
            "(?, ?, ?, NULL, ?, ?), " +    // Toolbar
        "(?, ?, ?, NULL, ?, ?)  "      // Unsorted

        return self.run(db, sql: sql, args: args)
    }

    func CreateHistoryTable() -> String {
        return "CREATE TABLE IF NOT EXISTS \(TableHistory) (" +
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
    }

    func CreateDomainsTable() -> String {
        return "CREATE TABLE IF NOT EXISTS \(TableDomains) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "domain TEXT NOT NULL UNIQUE, " +
            "showOnTopSites TINYINT NOT NULL DEFAULT 1" +
        ")"
    }

    func CreateQueueTable() -> String {
        return "CREATE TABLE IF NOT EXISTS \(TableQueuedTabs) (" +
            "url TEXT NOT NULL UNIQUE, " +
            "title TEXT" +
        ") "
    }
}

extension BrowserTableV6: Table {
    func create(db: SQLiteDBConnection) -> Bool {
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

        let bookmarks =
        "CREATE TABLE IF NOT EXISTS bookmarks (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "guid TEXT NOT NULL UNIQUE, " +
            "type TINYINT NOT NULL, " +
            "url TEXT, " +
            "parent INTEGER REFERENCES bookmarks(id) NOT NULL, " +
            "faviconID INTEGER REFERENCES favicons(id) ON DELETE SET NULL, " +
            "title TEXT" +
        ") "

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

class BrowserTableV7: BaseHistoricalBrowserTable {
    var name: String { return "BROWSER" }
    var version: Int { return 7 }

    func prepopulateRootFolders(db: SQLiteDBConnection) -> Bool {
        let type = BookmarkNodeType.Folder.rawValue
        let root = BookmarkRoots.RootID

        let titleMobile = NSLocalizedString("Mobile Bookmarks", tableName: "Storage", comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.")
        let titleMenu = NSLocalizedString("Bookmarks Menu", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.")
        let titleToolbar = NSLocalizedString("Bookmarks Toolbar", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.")
        let titleUnsorted = NSLocalizedString("Unsorted Bookmarks", tableName: "Storage", comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.")

        let args: Args = [
            root, BookmarkRoots.RootGUID, type, "Root", root,
            BookmarkRoots.MobileID, BookmarkRoots.MobileFolderGUID, type, titleMobile, root,
            BookmarkRoots.MenuID, BookmarkRoots.MenuFolderGUID, type, titleMenu, root,
            BookmarkRoots.ToolbarID, BookmarkRoots.ToolbarFolderGUID, type, titleToolbar, root,
            BookmarkRoots.UnfiledID, BookmarkRoots.UnfiledFolderGUID, type, titleUnsorted, root,
        ]

        let sql =
        "INSERT INTO bookmarks (id, guid, type, url, title, parent) VALUES " +
            "(?, ?, ?, NULL, ?, ?), " +    // Root
            "(?, ?, ?, NULL, ?, ?), " +    // Mobile
            "(?, ?, ?, NULL, ?, ?), " +    // Menu
            "(?, ?, ?, NULL, ?, ?), " +    // Toolbar
        "(?, ?, ?, NULL, ?, ?)  "      // Unsorted

        return self.run(db, sql: sql, args: args)
    }

    func getHistoryTableCreationString() -> String {
        return "CREATE TABLE IF NOT EXISTS history (" +
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
    }

    func getDomainsTableCreationString() -> String {
        return "CREATE TABLE IF NOT EXISTS \(TableDomains) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "domain TEXT NOT NULL UNIQUE, " +
            "showOnTopSites TINYINT NOT NULL DEFAULT 1" +
        ")"
    }

    func getQueueTableCreationString() -> String {
        return "CREATE TABLE IF NOT EXISTS \(TableQueuedTabs) (" +
            "url TEXT NOT NULL UNIQUE, " +
            "title TEXT" +
        ") "
    }
}

extension BrowserTableV7: SectionCreator, TableInfo {
    func create(db: SQLiteDBConnection) -> Bool {
        // Right now we don't need to track per-visit deletions: Sync can't
        // represent them! See Bug 1157553 Comment 6.
        // We flip the should_upload flag on the history item when we add a visit.
        // If we ever want to support logic like not bothering to sync if we added
        // and then rapidly removed a visit, then we need an 'is_new' flag on each visit.
        let visits =
        "CREATE TABLE IF NOT EXISTS \(TableVisits) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE, " +
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
            "ON history (should_upload) WHERE should_upload = 1"
        } else {
            indexShouldUpload =
                "CREATE INDEX IF NOT EXISTS \(IndexHistoryShouldUpload) " +
            "ON history (should_upload)"
        }

        let indexSiteIDDate =
        "CREATE INDEX IF NOT EXISTS \(IndexVisitsSiteIDIsLocalDate) " +
        "ON \(TableVisits) (siteID, is_local, date)"

        let faviconSites =
        "CREATE TABLE IF NOT EXISTS \(TableFaviconSites) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE, " +
            "faviconID INTEGER NOT NULL REFERENCES favicons(id) ON DELETE CASCADE, " +
            "UNIQUE (siteID, faviconID) " +
        ") "

        let widestFavicons =
        "CREATE VIEW IF NOT EXISTS \(ViewWidestFaviconsForSites) AS " +
            "SELECT " +
            "\(TableFaviconSites).siteID AS siteID, " +
            "favicons.id AS iconID, " +
            "favicons.url AS iconURL, " +
            "favicons.date AS iconDate, " +
            "favicons.type AS iconType, " +
            "MAX(favicons.width) AS iconWidth " +
            "FROM \(TableFaviconSites), favicons WHERE " +
            "\(TableFaviconSites).faviconID = favicons.id " +
        "GROUP BY siteID "

        let historyIDsWithIcon =
        "CREATE VIEW IF NOT EXISTS \(ViewHistoryIDsWithWidestFavicons) AS " +
            "SELECT history.id AS id, " +
            "iconID, iconURL, iconDate, iconType, iconWidth " +
            "FROM history " +
            "LEFT OUTER JOIN " +
        "\(ViewWidestFaviconsForSites) ON history.id = \(ViewWidestFaviconsForSites).siteID "

        let iconForURL =
        "CREATE VIEW IF NOT EXISTS \(ViewIconForURL) AS " +
            "SELECT history.url AS url, icons.iconID AS iconID FROM " +
            "\(TableHistory), \(ViewWidestFaviconsForSites) AS icons WHERE " +
        "\(TableHistory).id = icons.siteID "

        let bookmarks =
        "CREATE TABLE IF NOT EXISTS bookmarks (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "guid TEXT NOT NULL UNIQUE, " +
            "type TINYINT NOT NULL, " +
            "url TEXT, " +
            "parent INTEGER REFERENCES bookmarks(id) NOT NULL, " +
            "faviconID INTEGER REFERENCES favicons(id) ON DELETE SET NULL, " +
            "title TEXT" +
        ") "

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

class BrowserTableV8: BaseHistoricalBrowserTable {
    var name: String { return "BROWSER" }
    var version: Int { return 8 }

    func prepopulateRootFolders(db: SQLiteDBConnection) -> Bool {
        let type = BookmarkNodeType.Folder.rawValue
        let root = BookmarkRoots.RootID

        let titleMobile = NSLocalizedString("Mobile Bookmarks", tableName: "Storage", comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.")
        let titleMenu = NSLocalizedString("Bookmarks Menu", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.")
        let titleToolbar = NSLocalizedString("Bookmarks Toolbar", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.")
        let titleUnsorted = NSLocalizedString("Unsorted Bookmarks", tableName: "Storage", comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.")

        let args: Args = [
            root, BookmarkRoots.RootGUID, type, "Root", root,
            BookmarkRoots.MobileID, BookmarkRoots.MobileFolderGUID, type, titleMobile, root,
            BookmarkRoots.MenuID, BookmarkRoots.MenuFolderGUID, type, titleMenu, root,
            BookmarkRoots.ToolbarID, BookmarkRoots.ToolbarFolderGUID, type, titleToolbar, root,
            BookmarkRoots.UnfiledID, BookmarkRoots.UnfiledFolderGUID, type, titleUnsorted, root,
        ]

        let sql =
        "INSERT INTO bookmarks (id, guid, type, url, title, parent) VALUES " +
            "(?, ?, ?, NULL, ?, ?), " +    // Root
            "(?, ?, ?, NULL, ?, ?), " +    // Mobile
            "(?, ?, ?, NULL, ?, ?), " +    // Menu
            "(?, ?, ?, NULL, ?, ?), " +    // Toolbar
        "(?, ?, ?, NULL, ?, ?)  "      // Unsorted

        return self.run(db, sql: sql, args: args)
    }

    func getHistoryTableCreationString() -> String {
        return "CREATE TABLE IF NOT EXISTS \(TableHistory) (" +
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
    }

    func getDomainsTableCreationString() -> String {
        return "CREATE TABLE IF NOT EXISTS \(TableDomains) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "domain TEXT NOT NULL UNIQUE, " +
            "showOnTopSites TINYINT NOT NULL DEFAULT 1" +
        ")"
    }

    func getQueueTableCreationString() -> String {
        return "CREATE TABLE IF NOT EXISTS \(TableQueuedTabs) (" +
            "url TEXT NOT NULL UNIQUE, " +
            "title TEXT" +
        ") "
    }
}

extension BrowserTableV8: SectionCreator, TableInfo {
    func create(db: SQLiteDBConnection) -> Bool {
        let favicons =
        "CREATE TABLE IF NOT EXISTS favicons (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "url TEXT NOT NULL UNIQUE, " +
            "width INTEGER, " +
            "height INTEGER, " +
            "type INTEGER NOT NULL, " +
            "date REAL NOT NULL" +
        ") "

        // Right now we don't need to track per-visit deletions: Sync can't
        // represent them! See Bug 1157553 Comment 6.
        // We flip the should_upload flag on the history item when we add a visit.
        // If we ever want to support logic like not bothering to sync if we added
        // and then rapidly removed a visit, then we need an 'is_new' flag on each visit.
        let visits =
        "CREATE TABLE IF NOT EXISTS visits (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE, " +
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
            "siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE, " +
            "faviconID INTEGER NOT NULL REFERENCES favicons(id) ON DELETE CASCADE, " +
            "UNIQUE (siteID, faviconID) " +
        ") "

        let widestFavicons =
        "CREATE VIEW IF NOT EXISTS \(ViewWidestFaviconsForSites) AS " +
            "SELECT " +
            "\(TableFaviconSites).siteID AS siteID, " +
            "favicons.id AS iconID, " +
            "favicons.url AS iconURL, " +
            "favicons.date AS iconDate, " +
            "favicons.type AS iconType, " +
            "MAX(favicons.width) AS iconWidth " +
            "FROM \(TableFaviconSites), favicons WHERE " +
            "\(TableFaviconSites).faviconID = favicons.id " +
        "GROUP BY siteID "

        let historyIDsWithIcon =
        "CREATE VIEW IF NOT EXISTS \(ViewHistoryIDsWithWidestFavicons) AS " +
            "SELECT history.id AS id, " +
            "iconID, iconURL, iconDate, iconType, iconWidth " +
            "FROM history " +
            "LEFT OUTER JOIN " +
        "\(ViewWidestFaviconsForSites) ON history.id = \(ViewWidestFaviconsForSites).siteID "

        let iconForURL =
        "CREATE VIEW IF NOT EXISTS \(ViewIconForURL) AS " +
            "SELECT history.url AS url, icons.iconID AS iconID FROM " +
            "history, \(ViewWidestFaviconsForSites) AS icons WHERE " +
        "history.id = icons.siteID "

        let bookmarks =
        "CREATE TABLE IF NOT EXISTS bookmarks (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "guid TEXT NOT NULL UNIQUE, " +
            "type TINYINT NOT NULL, " +
            "url TEXT, " +
            "parent INTEGER REFERENCES bookmarks(id) NOT NULL, " +
            "faviconID INTEGER REFERENCES favicons(id) ON DELETE SET NULL, " +
            "title TEXT" +
        ") "

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

class BrowserTableV10: BaseHistoricalBrowserTable {
    var name: String { return "BROWSER" }
    var version: Int { return 10 }

    func prepopulateRootFolders(db: SQLiteDBConnection) -> Bool {
        let type = BookmarkNodeType.Folder.rawValue
        let root = BookmarkRoots.RootID

        let titleMobile = NSLocalizedString("Mobile Bookmarks", tableName: "Storage", comment: "The title of the folder that contains mobile bookmarks. This should match bookmarks.folder.mobile.label on Android.")
        let titleMenu = NSLocalizedString("Bookmarks Menu", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the menu. This should match bookmarks.folder.menu.label on Android.")
        let titleToolbar = NSLocalizedString("Bookmarks Toolbar", tableName: "Storage", comment: "The name of the folder that contains desktop bookmarks in the toolbar. This should match bookmarks.folder.toolbar.label on Android.")
        let titleUnsorted = NSLocalizedString("Unsorted Bookmarks", tableName: "Storage", comment: "The name of the folder that contains unsorted desktop bookmarks. This should match bookmarks.folder.unfiled.label on Android.")

        let args: Args = [
            root, BookmarkRoots.RootGUID, type, "Root", root,
            BookmarkRoots.MobileID, BookmarkRoots.MobileFolderGUID, type, titleMobile, root,
            BookmarkRoots.MenuID, BookmarkRoots.MenuFolderGUID, type, titleMenu, root,
            BookmarkRoots.ToolbarID, BookmarkRoots.ToolbarFolderGUID, type, titleToolbar, root,
            BookmarkRoots.UnfiledID, BookmarkRoots.UnfiledFolderGUID, type, titleUnsorted, root,
        ]

        let sql =
        "INSERT INTO bookmarks (id, guid, type, url, title, parent) VALUES " +
            "(?, ?, ?, NULL, ?, ?), " +    // Root
            "(?, ?, ?, NULL, ?, ?), " +    // Mobile
            "(?, ?, ?, NULL, ?, ?), " +    // Menu
            "(?, ?, ?, NULL, ?, ?), " +    // Toolbar
        "(?, ?, ?, NULL, ?, ?)  "      // Unsorted

        return self.run(db, sql: sql, args: args)
    }

    func getHistoryTableCreationString(forVersion version: Int = BrowserTable.DefaultVersion) -> String {
        return "CREATE TABLE IF NOT EXISTS history (" +
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
    }

    func getDomainsTableCreationString() -> String {
        return "CREATE TABLE IF NOT EXISTS \(TableDomains) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "domain TEXT NOT NULL UNIQUE, " +
            "showOnTopSites TINYINT NOT NULL DEFAULT 1" +
        ")"
    }

    func getQueueTableCreationString() -> String {
        return "CREATE TABLE IF NOT EXISTS \(TableQueuedTabs) (" +
            "url TEXT NOT NULL UNIQUE, " +
            "title TEXT" +
        ") "
    }

    func getBookmarksMirrorTableCreationString() -> String {
        // The stupid absence of naming conventions here is thanks to pre-Sync Weave. Sorry.
        // For now we have the simplest possible schema: everything in one.
        let sql =
        "CREATE TABLE IF NOT EXISTS \(TableBookmarksMirror) " +

            // Shared fields.
            "( id INTEGER PRIMARY KEY AUTOINCREMENT" +
            ", guid TEXT NOT NULL UNIQUE" +
            ", type TINYINT NOT NULL" +                    // Type enum. TODO: BookmarkNodeType needs to be extended.

            // Record/envelope metadata that'll allow us to do merges.
            ", server_modified INTEGER NOT NULL" +         // Milliseconds.
            ", is_deleted TINYINT NOT NULL DEFAULT 0" +    // Boolean

            ", hasDupe TINYINT NOT NULL DEFAULT 0" +       // Boolean, 0 (false) if deleted.
            ", parentid TEXT" +                            // GUID
            ", parentName TEXT" +

            // Type-specific fields. These should be NOT NULL in many cases, but we're going
            // for a sparse schema, so this'll do for now. Enforce these in the application code.
            ", feedUri TEXT, siteUri TEXT" +               // LIVEMARKS
            ", pos INT" +                                  // SEPARATORS
            ", title TEXT, description TEXT" +             // FOLDERS, BOOKMARKS, QUERIES
            ", bmkUri TEXT, tags TEXT, keyword TEXT" +     // BOOKMARKS, QUERIES
            ", folderName TEXT, queryId TEXT" +            // QUERIES
            ", CONSTRAINT parentidOrDeleted CHECK (parentid IS NOT NULL OR is_deleted = 1)" +
            ", CONSTRAINT parentNameOrDeleted CHECK (parentName IS NOT NULL OR is_deleted = 1)" +
        ")"

        return sql
    }

    /**
     * We need to explicitly store what's provided by the server, because we can't rely on
     * referenced child nodes to exist yet!
     */
    func getBookmarksMirrorStructureTableCreationString() -> String {
        return "CREATE TABLE IF NOT EXISTS \(TableBookmarksMirrorStructure) " +
            "( parent TEXT NOT NULL REFERENCES \(TableBookmarksMirror)(guid) ON DELETE CASCADE" +
            ", child TEXT NOT NULL" +      // Should be the GUID of a child.
            ", idx INTEGER NOT NULL" +     // Should advance from 0.
        ")"
    }
}

extension BrowserTableV10: SectionCreator, TableInfo {
    func create(db: SQLiteDBConnection) -> Bool {
        let favicons =
        "CREATE TABLE IF NOT EXISTS favicons (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "url TEXT NOT NULL UNIQUE, " +
            "width INTEGER, " +
            "height INTEGER, " +
            "type INTEGER NOT NULL, " +
            "date REAL NOT NULL" +
        ") "

        // Right now we don't need to track per-visit deletions: Sync can't
        // represent them! See Bug 1157553 Comment 6.
        // We flip the should_upload flag on the history item when we add a visit.
        // If we ever want to support logic like not bothering to sync if we added
        // and then rapidly removed a visit, then we need an 'is_new' flag on each visit.
        let visits =
        "CREATE TABLE IF NOT EXISTS visits (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE, " +
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
            "ON history (should_upload) WHERE should_upload = 1"
        } else {
            indexShouldUpload =
                "CREATE INDEX IF NOT EXISTS \(IndexHistoryShouldUpload) " +
            "ON history (should_upload)"
        }

        let indexSiteIDDate =
        "CREATE INDEX IF NOT EXISTS \(IndexVisitsSiteIDIsLocalDate) " +
        "ON visits (siteID, is_local, date)"

        let faviconSites =
        "CREATE TABLE IF NOT EXISTS \(TableFaviconSites) (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "siteID INTEGER NOT NULL REFERENCES history(id) ON DELETE CASCADE, " +
            "faviconID INTEGER NOT NULL REFERENCES favicons(id) ON DELETE CASCADE, " +
            "UNIQUE (siteID, faviconID) " +
        ") "

        let widestFavicons =
        "CREATE VIEW IF NOT EXISTS \(ViewWidestFaviconsForSites) AS " +
            "SELECT " +
            "\(TableFaviconSites).siteID AS siteID, " +
            "favicons.id AS iconID, " +
            "favicons.url AS iconURL, " +
            "favicons.date AS iconDate, " +
            "favicons.type AS iconType, " +
            "MAX(favicons.width) AS iconWidth " +
            "FROM \(TableFaviconSites), favicons WHERE " +
            "\(TableFaviconSites).faviconID = favicons.id " +
        "GROUP BY siteID "

        let historyIDsWithIcon =
        "CREATE VIEW IF NOT EXISTS \(ViewHistoryIDsWithWidestFavicons) AS " +
            "SELECT history.id AS id, " +
            "iconID, iconURL, iconDate, iconType, iconWidth " +
            "FROM history " +
            "LEFT OUTER JOIN " +
        "\(ViewWidestFaviconsForSites) ON history.id = \(ViewWidestFaviconsForSites).siteID "

        let iconForURL =
        "CREATE VIEW IF NOT EXISTS \(ViewIconForURL) AS " +
            "SELECT history.url AS url, icons.iconID AS iconID FROM " +
            "history, \(ViewWidestFaviconsForSites) AS icons WHERE " +
        "history.id = icons.siteID "

        let bookmarks =
        "CREATE TABLE IF NOT EXISTS bookmarks (" +
            "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
            "guid TEXT NOT NULL UNIQUE, " +
            "type TINYINT NOT NULL, " +
            "url TEXT, " +
            "parent INTEGER REFERENCES bookmarks(id) NOT NULL, " +
            "faviconID INTEGER REFERENCES favicons(id) ON DELETE SET NULL, " +
            "title TEXT" +
        ") "

        let bookmarksMirror = getBookmarksMirrorTableCreationString()
        let bookmarksMirrorStructure = getBookmarksMirrorStructureTableCreationString()

        let indexStructureParentIdx = "CREATE INDEX IF NOT EXISTS \(IndexBookmarksMirrorStructureParentIdx) " +
        "ON \(TableBookmarksMirrorStructure) (parent, idx)"

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

    private func deleteDatabases() {
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
        let db = BrowserDB(filename: "browser.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!

        let siteL = Site(url: "http://url1/", title: "title local only")
        let siteR = Site(url: "http://url2/", title: "title remote only")
        let siteB = Site(url: "http://url3/", title: "title local and remote")

        siteL.guid = "locallocal12"
        siteR.guid = "remoteremote"
        siteB.guid = "bothbothboth"

        let siteVisitL1 = SiteVisit(site: siteL, date: 1437088398461000, type: VisitType.Link)
        let siteVisitL2 = SiteVisit(site: siteL, date: 1437088398462000, type: VisitType.Link)

        let siteVisitR1 = SiteVisit(site: siteR, date: 1437088398461000, type: VisitType.Link)
        let siteVisitR2 = SiteVisit(site: siteR, date: 1437088398462000, type: VisitType.Link)
        let siteVisitR3 = SiteVisit(site: siteR, date: 1437088398463000, type: VisitType.Link)

        let siteVisitBL1 = SiteVisit(site: siteB, date: 1437088398464000, type: VisitType.Link)
        let siteVisitBR1 = SiteVisit(site: siteB, date: 1437088398465000, type: VisitType.Link)

        let deferred =
        history.clearHistory()
            >>> { history.addLocalVisit(siteVisitL1) }
            >>> { history.addLocalVisit(siteVisitL2) }
            >>> { history.addLocalVisit(siteVisitBL1) }
            >>> { history.insertOrUpdatePlace(siteL.asPlace(), modified: 1437088398462) }
            >>> { history.insertOrUpdatePlace(siteR.asPlace(), modified: 1437088398463) }
            >>> { history.insertOrUpdatePlace(siteB.asPlace(), modified: 1437088398465) }

            // Do this step twice, so we exercise the dupe-visit handling.
            >>> { history.storeRemoteVisits([siteVisitR1, siteVisitR2, siteVisitR3], forGUID: siteR.guid!) }
            >>> { history.storeRemoteVisits([siteVisitR1, siteVisitR2, siteVisitR3], forGUID: siteR.guid!) }

            >>> { history.storeRemoteVisits([siteVisitBR1], forGUID: siteB.guid!) }

            >>> { history.getSitesByFrecencyWithLimit(3)
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
                    if let (_, visits) = find(places, f: {$0.0.guid == siteR.guid!}) {
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
        let sources: [(Int, SectionCreator)] = [
            (6, BrowserTableV6()),
            (7, BrowserTableV7()),
            (8, BrowserTableV8()),
            (10, BrowserTableV10()),
        ]

        let destination = BrowserTable()

        for (version, table) in sources {
            let db = BrowserDB(filename: "browser-v\(version).db", files: files)
            XCTAssertTrue(
                db.runWithConnection { (conn, err) in
                    XCTAssertTrue(table.create(conn), "Creating browser table version \(version)")

                    // And we can upgrade to the current version.
                    XCTAssertTrue(destination.updateTable(conn, from: table.version), "Upgrading browser table from version \(version)")
                }.value.isSuccess
            )
            db.forceClose()
        }
    }

    func testUpgradesWithData() {
        let db = BrowserDB(filename: "browser-v6-data.db", files: files)

        XCTAssertTrue(db.createOrUpdate(BrowserTableV6()), "Creating browser table version 6")

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
        XCTAssertTrue(db.createOrUpdate(BrowserTable()), "Upgrading browser table from version 6")

        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)
        let results = history?.getSitesByLastVisit(10).value.successValue
        XCTAssertNotNil(results)
        XCTAssertEqual(results![0]?.url, "http://www.example.com")

        db.forceClose()
    }

    func testDomainUpgrade() {
        let db = BrowserDB(filename: "browser.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!

        let site = Site(url: "http://www.example.com/test1.1", title: "title one")
        var err: NSError? = nil

        // Insert something with an invalid domain ID. We have to manually do this since domains are usually hidden.
        db.withWritableConnection(&err, callback: { (connection, err) -> Int in
            let insert = "INSERT INTO \(TableHistory) (guid, url, title, local_modified, is_deleted, should_upload, domain_id) " +
                         "?, ?, ?, ?, ?, ?, ?"
            let args: Args = [Bytes.generateGUID(), site.url, site.title, NSDate.nowNumber(), 0, 0, -1]
            err = connection.executeChange(insert, withArgs: args)
            return 0
        })

        // Now insert it again. This should update the domain
        history.addLocalVisit(SiteVisit(site: site, date: NSDate.nowMicroseconds(), type: VisitType.Link))

        // DomainID isn't normally exposed, so we manually query to get it
        let results = db.withReadableConnection(&err, callback: { (connection, err) -> Cursor<Int> in
            let sql = "SELECT domain_id FROM \(TableHistory) WHERE url = ?"
            let args: Args = [site.url]
            return connection.executeQuery(sql, factory: IntFactory, withArgs: args)
        })
        XCTAssertNotEqual(results[0]!, -1, "Domain id was updated")
    }

    func testDomains() {
        let db = BrowserDB(filename: "browser.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!

        let initialGuid = Bytes.generateGUID()
        let site11 = Site(url: "http://www.example.com/test1.1", title: "title one")
        let site12 = Site(url: "http://www.example.com/test1.2", title: "title two")
        let site13 = Place(guid: initialGuid, url: "http://www.example.com/test1.3", title: "title three")
        let site3 = Site(url: "http://www.example2.com/test1", title: "title three")
        let expectation = self.expectationWithDescription("First.")

        history.clearHistory().bind({ success in
            return all([history.addLocalVisit(SiteVisit(site: site11, date: NSDate.nowMicroseconds(), type: VisitType.Link)),
                        history.addLocalVisit(SiteVisit(site: site12, date: NSDate.nowMicroseconds(), type: VisitType.Link)),
                        history.addLocalVisit(SiteVisit(site: site3, date: NSDate.nowMicroseconds(), type: VisitType.Link))])
        }).bind({ (results: [Maybe<()>]) in
            return history.insertOrUpdatePlace(site13, modified: NSDate.nowMicroseconds())
        }).bind({ guid in
            XCTAssertEqual(guid.successValue!, initialGuid, "Guid is correct")
            return history.getSitesByFrecencyWithLimit(10)
        }).bind({ (sites: Maybe<Cursor<Site>>) -> Success in
            XCTAssert(sites.successValue!.count == 2, "2 sites returned")
            return history.removeSiteFromTopSites(site11)
        }).bind({ success in
            XCTAssertTrue(success.isSuccess, "Remove was successful")
            return history.getSitesByFrecencyWithLimit(10)
        }).upon({ (sites: Maybe<Cursor<Site>>) in
            XCTAssert(sites.successValue!.count == 1, "1 site returned")
            expectation.fulfill()
        })

        waitForExpectationsWithTimeout(10.0) { error in
            return
        }
    }

    func testHistoryIsSynced() {
        let db = BrowserDB(filename: "historysynced.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!

        let initialGUID = Bytes.generateGUID()
        let site = Place(guid: initialGUID, url: "http://www.example.com/test1.3", title: "title")

        XCTAssertFalse(history.hasSyncedHistory().value.successValue ?? true)

        XCTAssertTrue(history.insertOrUpdatePlace(site, modified: NSDate.now()).value.isSuccess)

        XCTAssertTrue(history.hasSyncedHistory().value.successValue ?? false)
    }

    // This is a very basic test. Adds an entry, retrieves it, updates it,
    // and then clears the database.
    func testHistoryTable() {
        let db = BrowserDB(filename: "browser.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!
        let bookmarks = SQLiteBookmarks(db: db)

        let site1 = Site(url: "http://url1/", title: "title one")
        let site1Changed = Site(url: "http://url1/", title: "title one alt")

        let siteVisit1 = SiteVisit(site: site1, date: NSDate.nowMicroseconds(), type: VisitType.Link)
        let siteVisit2 = SiteVisit(site: site1Changed, date: NSDate.nowMicroseconds() + 1000, type: VisitType.Bookmark)

        let site2 = Site(url: "http://url2/", title: "title two")
        let siteVisit3 = SiteVisit(site: site2, date: NSDate.nowMicroseconds() + 2000, type: VisitType.Link)

        let expectation = self.expectationWithDescription("First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func checkSitesByFrecency(f: Cursor<Site> -> Success) -> () -> Success {
            return {
                history.getSitesByFrecencyWithLimit(10)
                    >>== f
            }
        }

        func checkSitesByDate(f: Cursor<Site> -> Success) -> () -> Success {
            return {
                history.getSitesByLastVisit(10)
                >>== f
            }
        }

        func checkSitesWithFilter(filter: String, f: Cursor<Site> -> Success) -> () -> Success {
            return {
                history.getSitesByFrecencyWithLimit(10, whereURLContains: filter)
                >>== f
            }
        }

        func checkDeletedCount(expected: Int) -> () -> Success {
            return {
                history.getDeletedHistoryToUpload()
                >>== { guids in
                    XCTAssertEqual(expected, guids.count)
                    return succeed()
                }
            }
        }

        history.clearHistory()
            >>>
            { history.addLocalVisit(siteVisit1) }
            >>> checkSitesByFrecency
            { (sites: Cursor) -> Success in
                XCTAssertEqual(1, sites.count)
                XCTAssertEqual(site1.title, sites[0]!.title)
                XCTAssertEqual(site1.url, sites[0]!.url)
                sites.close()
                return succeed()
            }
            >>>
            { history.addLocalVisit(siteVisit2) }
            >>> checkSitesByFrecency
            { (sites: Cursor) -> Success in
                XCTAssertEqual(1, sites.count)
                XCTAssertEqual(site1Changed.title, sites[0]!.title)
                XCTAssertEqual(site1Changed.url, sites[0]!.url)
                sites.close()
                return succeed()
            }
            >>>
            { history.addLocalVisit(siteVisit3) }
            >>> checkSitesByFrecency
            { (sites: Cursor) -> Success in
                XCTAssertEqual(2, sites.count)
                // They're in order of frecency.
                XCTAssertEqual(site1Changed.title, sites[0]!.title)
                XCTAssertEqual(site2.title, sites[1]!.title)
                return succeed()
            }
            >>> checkSitesByDate
            { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(2, sites.count)
                // They're in order of date last visited.
                let first = sites[0]!
                let second = sites[1]!
                XCTAssertEqual(site2.title, first.title)
                XCTAssertEqual(site1Changed.title, second.title)
                XCTAssertTrue(siteVisit3.date == first.latestVisit!.date)
                return succeed()
            }
            >>> checkSitesWithFilter("two")
            { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(1, sites.count)
                let first = sites[0]!
                XCTAssertEqual(site2.title, first.title)
                return succeed()
            }
            >>>
            checkDeletedCount(0)
            >>>
            { history.removeHistoryForURL("http://url2/") }
            >>>
            checkDeletedCount(1)
            >>> checkSitesByFrecency
                { (sites: Cursor) -> Success in
                    XCTAssertEqual(1, sites.count)
                    // They're in order of frecency.
                    XCTAssertEqual(site1Changed.title, sites[0]!.title)
                    return succeed()
            }
            >>>
            { history.clearHistory() }
            >>>
            checkDeletedCount(0)
            >>> checkSitesByDate
            { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(0, sites.count)
                return succeed()
            }
            >>> checkSitesByFrecency
            { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(0, sites.count)
                return succeed()
            }
            >>> done


        waitForExpectationsWithTimeout(10.0) { error in
            return
        }
    }

    func testFaviconTable() {
        let db = BrowserDB(filename: "browser.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!
        let bookmarks = SQLiteBookmarks(db: db)

        let expectation = self.expectationWithDescription("First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func updateFavicon() -> Success {
            let fav = Favicon(url: "http://url2/", date: NSDate(), type: .Icon)
            fav.id = 1
            let site = Site(url: "http://bookmarkedurl/", title: "My Bookmark")
            return history.addFavicon(fav, forSite: site) >>> succeed
        }

        func checkFaviconForBookmarkIsNil() -> Success {
            return bookmarks.bookmarksByURL("http://bookmarkedurl/".asURL!) >>== { results in
                XCTAssertEqual(1, results.count)
                XCTAssertNil(results[0]?.favicon)
                return succeed()
            }
        }

        func checkFaviconWasSetForBookmark() -> Success {
            return history.getFaviconsForBookmarkedURL("http://bookmarkedurl/") >>== { results in
                XCTAssertEqual(1, results.count)
                if let actualFaviconURL = results[0]??.url {
                    XCTAssertEqual("http://url2/", actualFaviconURL)
                }
                return succeed()
            }
        }

        func removeBookmark() -> Success {
            return bookmarks.removeByURL("http://bookmarkedurl/")
        }

        func checkFaviconWasRemovedForBookmark() -> Success {
            return history.getFaviconsForBookmarkedURL("http://bookmarkedurl/") >>== { results in
                XCTAssertEqual(0, results.count)
                return succeed()
            }
        }

        history.clearAllFavicons()
            >>> bookmarks.clearBookmarks
            >>> { bookmarks.addToMobileBookmarks("http://bookmarkedurl/".asURL!, title: "Title", favicon: nil) }
            >>> checkFaviconForBookmarkIsNil
            >>> updateFavicon
            >>> checkFaviconWasSetForBookmark
            >>> removeBookmark
            >>> checkFaviconWasRemovedForBookmark
            >>> done

        waitForExpectationsWithTimeout(10.0) { error in
            return
        }
    }

    func testTopSitesCache() {
        let db = BrowserDB(filename: "browser.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!

        history.setTopSitesCacheSize(20)
        history.clearTopSitesCache().value
        history.clearHistory().value

        // Make sure that we get back the top sites
        populateHistoryForFrecencyCalcuations(history, siteCount: 100)

        // Add extra visits to the 5th site to bubble it to the top of the top sites cache
        let site = Site(url: "http://s\(5)ite\(5)/foo", title: "A \(5)")
        site.guid = "abc\(5)def"
        for i in 0...20 {
            addVisitForSite(site, intoHistory: history, from: .Local, atTime: advanceTimestamp(1438088398461, by: 1000 * i))
        }

        let expectation = self.expectationWithDescription("First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func loadCache() -> Success {
            return history.updateTopSitesCacheIfInvalidated() >>> succeed
        }

        func checkTopSitesReturnsResults() -> Success {
            return history.getTopSitesWithLimit(20) >>== { topSites in
                XCTAssertEqual(topSites.count, 20)
                XCTAssertEqual(topSites[0]!.guid, "abc\(5)def")
                return succeed()
            }
        }

        func invalidateIfNeededDoesntChangeResults() -> Success {
            return history.updateTopSitesCacheIfInvalidated() >>> {
                return history.getTopSitesWithLimit(20) >>== { topSites in
                    XCTAssertEqual(topSites.count, 20)
                    XCTAssertEqual(topSites[0]!.guid, "abc\(5)def")
                    return succeed()
                }
            }
        }

        func addVisitsToZerothSite() -> Success {
            let site = Site(url: "http://s\(0)ite\(0)/foo", title: "A \(0)")
            site.guid = "abc\(0)def"
            for i in 0...20 {
                addVisitForSite(site, intoHistory: history, from: .Local, atTime: advanceTimestamp(1439088398461, by: 1000 * i))
            }
            return succeed()
        }

        func markInvalidation() -> Success {
            history.setTopSitesNeedsInvalidation()
            return succeed()
        }

        func checkSitesInvalidate() -> Success {
            history.updateTopSitesCacheIfInvalidated().value

            return history.getTopSitesWithLimit(20) >>== { topSites in
                XCTAssertEqual(topSites.count, 20)
                XCTAssertEqual(topSites[0]!.guid, "abc\(0)def")
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

        waitForExpectationsWithTimeout(10.0) { error in
            return
        }
    }
}

class TestSQLiteHistoryTransactionUpdate: XCTestCase {
    func testUpdateInTransaction() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!

        history.clearHistory().value
        let site = Site(url: "http://site/foo", title: "AA")
        site.guid = "abcdefghiabc"

        history.insertOrUpdatePlace(site.asPlace(), modified: 1234567890).value

        let ts: MicrosecondTimestamp = 1437088398461000
        let local = SiteVisit(site: site, date: ts, type: VisitType.Link)
        XCTAssertTrue(history.addLocalVisit(local).value.isSuccess)
    }
}



class TestSQLiteHistoryFrecencyPerf: XCTestCase {
    func testFrecencyPerf() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!

        let count = 500

        history.clearHistory().value
        populateHistoryForFrecencyCalcuations(history, siteCount: count)

        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: true) {
            for _ in 0...5 {
                history.getSitesByFrecencyWithLimit(10, includeIcon: false).value
            }
            self.stopMeasuring()
        }
    }
}

class TestSQLiteHistoryTopSitesCachePref: XCTestCase {
    func testCachePerf() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!

        let count = 500

        history.clearHistory().value
        populateHistoryForFrecencyCalcuations(history, siteCount: count)

        history.setTopSitesNeedsInvalidation()
        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: true) {
            history.updateTopSitesCacheIfInvalidated().value
            self.stopMeasuring()
        }
    }
}

// MARK - Private Test Helper Methods

private enum VisitOrigin {
    case Local
    case Remote
}

private func populateHistoryForFrecencyCalcuations(history: SQLiteHistory, siteCount count: Int) {
    for i in 0...count {
        let site = Site(url: "http://s\(i)ite\(i)/foo", title: "A \(i)")
        site.guid = "abc\(i)def"

        history.insertOrUpdatePlace(site.asPlace(), modified: 1234567890).value
        for j in 0...20 {
            let visitTime = advanceMicrosecondTimestamp(1437088398461000, by: ((1000000 * i) + (1000 * j)))
            addVisitForSite(site, intoHistory: history, from: .Local, atTime: visitTime)
            addVisitForSite(site, intoHistory: history, from: .Remote, atTime: visitTime)
        }
    }
}

private func addVisitForSite(site: Site, intoHistory history: SQLiteHistory, from: VisitOrigin, atTime: Timestamp) {
    let visit = SiteVisit(site: site, date: atTime, type: VisitType.Link)
    switch from {
    case .Local:
            history.addLocalVisit(visit).value
    case .Remote:
        history.storeRemoteVisits([visit], forGUID: site.guid!).value
    }
}