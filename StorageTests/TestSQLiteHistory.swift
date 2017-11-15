/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage
import Deferred

import XCTest

let threeMonthsInMillis: UInt64 = 3 * 30 * 24 * 60 * 60 * 1000
let threeMonthsInMicros: UInt64 = UInt64(threeMonthsInMillis) * UInt64(1000)

// Start everything three months ago.
let baseInstantInMillis = Date.now() - threeMonthsInMillis
let baseInstantInMicros = Date.nowMicroseconds() - threeMonthsInMicros

func advanceTimestamp(_ timestamp: Timestamp, by: Int) -> Timestamp {
    return timestamp + UInt64(by)
}

func advanceMicrosecondTimestamp(_ timestamp: MicrosecondTimestamp, by: Int) -> MicrosecondTimestamp {
    return timestamp + UInt64(by)
}

extension Site {
    func asPlace() -> Place {
        return Place(guid: self.guid!, url: self.url, title: self.title)
    }
}

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

    let oldFaviconsSQL =
        "CREATE TABLE IF NOT EXISTS favicons (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "url TEXT NOT NULL UNIQUE, " +
        "width INTEGER, " +
        "height INTEGER, " +
        "type INTEGER NOT NULL, " +
        "date REAL NOT NULL" +
        ") "

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
        let type = BookmarkNodeType.folder.rawValue
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

    override func create(_ db: SQLiteDBConnection) -> Bool {
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

class BrowserSchemaV7: BaseHistoricalBrowserSchema {
    override var version: Int { return 7 }

    func prepopulateRootFolders(_ db: SQLiteDBConnection) -> Bool {
        let type = BookmarkNodeType.folder.rawValue
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

    override func create(_ db: SQLiteDBConnection) -> Bool {
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

class BrowserSchemaV8: BaseHistoricalBrowserSchema {
    override var version: Int { return 8 }

    func prepopulateRootFolders(_ db: SQLiteDBConnection) -> Bool {
        let type = BookmarkNodeType.folder.rawValue
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

    override func create(_ db: SQLiteDBConnection) -> Bool {
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

class BrowserSchemaV10: BaseHistoricalBrowserSchema {
    override var version: Int { return 10 }

    func prepopulateRootFolders(_ db: SQLiteDBConnection) -> Bool {
        let type = BookmarkNodeType.folder.rawValue
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

    func getHistoryTableCreationString(forVersion version: Int = BrowserSchema.DefaultVersion) -> String {
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

    override func create(_ db: SQLiteDBConnection) -> Bool {
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
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
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

            >>> { history.getSitesByFrecencyWithHistoryLimit(3)
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
        let results = history.getSitesByLastVisit(10).value.successValue
        XCTAssertNotNil(results)
        XCTAssertEqual(results![0]?.url, "http://www.example.com")

        db.forceClose()
    }

    func testDomainUpgrade() {
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let site = Site(url: "http://www.example.com/test1.1", title: "title one")

        // Insert something with an invalid domain ID. We have to manually do this since domains are usually hidden.
        let insertDeferred = db.withConnection { connection -> Void in
            try connection.executeChange("PRAGMA foreign_keys = OFF")
                         let insert = "INSERT INTO \(TableHistory) (guid, url, title, local_modified, is_deleted, should_upload, domain_id) VALUES (?, ?, ?, ?, ?, ?, ?)"
            let args: Args = [Bytes.generateGUID(), site.url, site.title, Date.now(), 0, 0, -1]
            try connection.executeChange(insert, withArgs: args)
        }
        
        XCTAssertTrue(insertDeferred.value.isSuccess)

        // Now insert it again. This should update the domain.
        history.addLocalVisit(SiteVisit(site: site, date: Date.nowMicroseconds(), type: VisitType.link)).succeeded()

        // domain_id isn't normally exposed, so we manually query to get it.
        let resultsDeferred = db.withConnection { connection -> Cursor<Int?> in
            let sql = "SELECT domain_id FROM \(TableHistory) WHERE url = ?"
            let args: Args = [site.url]
            return connection.executeQuery(sql, factory: { $0[0] as? Int }, withArgs: args)
        }
        
        let results = resultsDeferred.value.successValue!
        let domain = results[0]!         // Unwrap to get the first item from the cursor.
        XCTAssertNil(domain)
    }

    func testDomains() {
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let initialGuid = Bytes.generateGUID()
        let site11 = Site(url: "http://www.example.com/test1.1", title: "title one")
        let site12 = Site(url: "http://www.example.com/test1.2", title: "title two")
        let site13 = Place(guid: initialGuid, url: "http://www.example.com/test1.3", title: "title three")
        let site3 = Site(url: "http://www.example2.com/test1", title: "title three")
        let expectation = self.expectation(description: "First.")

        history.clearHistory().bind({ success in
            return all([history.addLocalVisit(SiteVisit(site: site11, date: Date.nowMicroseconds(), type: VisitType.link)),
                        history.addLocalVisit(SiteVisit(site: site12, date: Date.nowMicroseconds(), type: VisitType.link)),
                        history.addLocalVisit(SiteVisit(site: site3, date: Date.nowMicroseconds(), type: VisitType.link))])
        }).bind({ (results: [Maybe<()>]) in
            return history.insertOrUpdatePlace(site13, modified: Date.nowMicroseconds())
        }).bind({ guid in
            XCTAssertEqual(guid.successValue!, initialGuid, "Guid is correct")
            return history.getSitesByFrecencyWithHistoryLimit(10)
        }).bind({ (sites: Maybe<Cursor<Site>>) -> Success in
            XCTAssert(sites.successValue!.count == 2, "2 sites returned")
            return history.removeSiteFromTopSites(site11)
        }).bind({ success in
            XCTAssertTrue(success.isSuccess, "Remove was successful")
            return history.getSitesByFrecencyWithHistoryLimit(10)
        }).upon({ (sites: Maybe<Cursor<Site>>) in
            XCTAssert(sites.successValue!.count == 1, "1 site returned")
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
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)
        let bookmarks = SQLiteBookmarks(db: db)

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
                history.getSitesByFrecencyWithHistoryLimit(10)
                    >>== f
            }
        }

        func checkSitesByDate(_ f: @escaping (Cursor<Site>) -> Success) -> () -> Success {
            return {
                history.getSitesByLastVisit(10)
                >>== f
            }
        }

        func checkSitesWithFilter(_ filter: String, f: @escaping (Cursor<Site>) -> Success) -> () -> Success {
            return {
                history.getSitesByFrecencyWithHistoryLimit(10, whereURLContains: filter)
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

    func testFaviconTable() {
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)
        let bookmarks = SQLiteBookmarks(db: db)
        
        let expectation = self.expectation(description: "First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func updateFavicon() -> Success {
            let fav = Favicon(url: "http://url2/", date: Date(), type: .icon)
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
            return bookmarks.testFactory.removeByURL("http://bookmarkedurl/")
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

        waitForExpectations(timeout: 10.0) { error in
            return
        }
    }

    func testTopSitesFrecencyOrder() {
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        history.setTopSitesCacheSize(20)
        history.clearTopSitesCache().succeeded()
        history.clearHistory().succeeded()

        // Lets create some history. This will create 100 sites that will have 21 local and 21 remote visits
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
            return history.repopulate(invalidateTopSites: true, invalidateHighlights: true) >>> succeed
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
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
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
            return history.repopulate(invalidateTopSites: true, invalidateHighlights: true) >>> succeed
        }

        func checkTopSitesReturnsResults() -> Success {
            return history.getTopSitesWithLimit(20) >>== { topSites in
                XCTAssertEqual(topSites[0]?.guid, "docsgoogle") // google docs should be the first topsite
                // make sure all other google guids are not in the topsites array
                topSites.forEach {
                    let guid: String = $0!.guid! // type checking is hard
                    XCTAssertNil(["abcgoogle", "abcgoogle1", "abcgoogleza"].index(of: guid))
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
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
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
            return history.repopulate(invalidateTopSites: true, invalidateHighlights: true) >>> succeed
        }

        func checkTopSitesReturnsResults() -> Success {
            return history.getTopSitesWithLimit(20) >>== { topSites in
                XCTAssertEqual(topSites.count, 20)
                XCTAssertEqual(topSites[0]!.guid, "abc\(5)def")
                return succeed()
            }
        }

        func invalidateIfNeededDoesntChangeResults() -> Success {
            return history.repopulate(invalidateTopSites: true, invalidateHighlights: true) >>> {
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
            history.repopulate(invalidateTopSites: true, invalidateHighlights: true).succeeded()

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
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
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
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        history.clearHistory().succeeded()
        let site = Site(url: "http://site/foo", title: "AA")
        site.guid = "abcdefghiabc"

        history.insertOrUpdatePlace(site.asPlace(), modified: 1234567890).succeeded()

        let ts: MicrosecondTimestamp = baseInstantInMicros
        let local = SiteVisit(site: site, date: ts, type: VisitType.link)
        XCTAssertTrue(history.addLocalVisit(local).value.isSuccess)
    }
}

class TestSQLiteHistoryFilterSplitting: XCTestCase {
    let history: SQLiteHistory = {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        return SQLiteHistory(db: db, prefs: prefs)
    }()

    func testWithSingleWord() {
        let (fragment, args) = history.computeWhereFragmentWithFilter("foo", perWordFragment: "?", perWordArgs: { [$0] })
        XCTAssertEqual(fragment, "?")
        XCTAssert(stringArgsEqual(args, ["foo"]))
    }

    func testWithIdenticalWords() {
        let (fragment, args) = history.computeWhereFragmentWithFilter("foo fo foo", perWordFragment: "?", perWordArgs: { [$0] })
        XCTAssertEqual(fragment, "?")
        XCTAssert(stringArgsEqual(args, ["foo"]))
    }

    func testWithDistinctWords() {
        let (fragment, args) = history.computeWhereFragmentWithFilter("foo bar", perWordFragment: "?", perWordArgs: { [$0] })
        XCTAssertEqual(fragment, "? AND ?")
        XCTAssert(stringArgsEqual(args, ["foo", "bar"]))
    }

    func testWithDistinctWordsAndWhitespace() {
        let (fragment, args) = history.computeWhereFragmentWithFilter("  foo    bar  ", perWordFragment: "?", perWordArgs: { [$0] })
        XCTAssertEqual(fragment, "? AND ?")
        XCTAssert(stringArgsEqual(args, ["foo", "bar"]))
    }

    func testWithSubstrings() {
        let (fragment, args) = history.computeWhereFragmentWithFilter("foo bar foobar", perWordFragment: "?", perWordArgs: { [$0] })
        XCTAssertEqual(fragment, "?")
        XCTAssert(stringArgsEqual(args, ["foobar"]))
    }

    func testWithSubstringsAndIdenticalWords() {
        let (fragment, args) = history.computeWhereFragmentWithFilter("foo bar foobar foobar", perWordFragment: "?", perWordArgs: { [$0] })
        XCTAssertEqual(fragment, "?")
        XCTAssert(stringArgsEqual(args, ["foobar"]))
    }

    fileprivate func stringArgsEqual(_ one: Args, _ other: Args) -> Bool {
        return one.elementsEqual(other, by: { (oneElement: Any?, otherElement: Any?) -> Bool in
            return (oneElement as! String) == (otherElement as! String)
        })
    }
}

// MARK - Private Test Helper Methods

enum VisitOrigin {
    case local
    case remote
}

private func populateHistoryForFrecencyCalculations(_ history: SQLiteHistory, siteCount count: Int) {
    for i in 0...count {
        let site = Site(url: "http://s\(i)ite\(i).com/foo", title: "A \(i)")
        site.guid = "abc\(i)def"

        let baseMillis: UInt64 = baseInstantInMillis - 20000
        history.insertOrUpdatePlace(site.asPlace(), modified: baseMillis).succeeded()

        for j in 0...20 {
            let visitTime = advanceMicrosecondTimestamp(baseInstantInMicros, by: (1000000 * i) + (1000 * j))
            addVisitForSite(site, intoHistory: history, from: .local, atTime: visitTime)
            addVisitForSite(site, intoHistory: history, from: .remote, atTime: visitTime - 100)
        }
    }
}

func addVisitForSite(_ site: Site, intoHistory history: SQLiteHistory, from: VisitOrigin, atTime: MicrosecondTimestamp) {
    let visit = SiteVisit(site: site, date: atTime, type: VisitType.link)
    switch from {
    case .local:
            history.addLocalVisit(visit).succeeded()
    case .remote:
        history.storeRemoteVisits([visit], forGUID: site.guid!).succeeded()
    }
}
