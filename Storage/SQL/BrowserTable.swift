/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCGLogger

// To keep SwiftData happy.
typealias Args = [AnyObject?]

let TableBookmarks = "bookmarks"
let TableHistory = "history"
let TableVisits = "visits"
let TableFaviconSites = "faviconSites"
let ViewWidestFaviconsForSites = "view_favicons_widest"
let ViewHistoryIDsWithWidestFavicons = "view_history_id_favicon"
let ViewIconForURL = "view_icon_for_url"

private let AllTables: Args = [
    TableFaviconSites,
    TableVisits,
    TableHistory,
    TableBookmarks,
]

private let AllViews: Args = [
    ViewHistoryIDsWithWidestFavicons,
    ViewWidestFaviconsForSites,
    ViewIconForURL
]

private let AllTablesAndViews: Args = AllViews + AllTables

private let log = XCGLogger.defaultInstance()

/**
 * The monolithic class that manages the inter-related history etc. tables.
 * We rely on SQLiteHistory having initialized the favicon table first.
 */
public class BrowserTable: Table {
    var name: String { return "BROWSER" }
    var version: Int { return 10 }

    public init() {
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
    func run(db: SQLiteDBConnection, queries: [String]) -> Bool {
        for sql in queries {
            if !run(db, sql: sql, args: nil) {
                return false
            }
        }
        return true
    }

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

    func create(db: SQLiteDBConnection, version: Int) -> Bool {
        // We ignore the version.
        let history =
        "CREATE TABLE IF NOT EXISTS \(TableHistory) (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "guid TEXT NOT NULL UNIQUE, " +
        "url TEXT NOT NULL UNIQUE, " +
        "title TEXT NOT NULL " +
        ") "

        let visits =
        "CREATE TABLE IF NOT EXISTS \(TableVisits) (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "siteID INTEGER NOT NULL REFERENCES \(TableHistory)(id) ON DELETE CASCADE, " +
        "date REAL NOT NULL, " +
        "type INTEGER NOT NULL " +
        ") "

        let faviconSites =
        "CREATE TABLE IF NOT EXISTS \(TableFaviconSites) (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "siteID INTEGER NOT NULL REFERENCES \(TableHistory)(id) ON DELETE CASCADE, " +
        "faviconID INTEGER NOT NULL REFERENCES favicons(id) ON DELETE CASCADE, " +
        "UNIQUE (siteID, faviconID) " +
        ") "

        let widestFavicons =
        "CREATE VIEW IF NOT EXISTS \(ViewWidestFaviconsForSites) AS " +
        "SELECT " +
        "faviconSites.siteID AS siteID, " +
        "favicons.id AS iconID, " +
        "favicons.url AS iconURL, " +
        "favicons.date AS iconDate, " +
        "favicons.type AS iconType, " +
        "MAX(favicons.width) AS iconWidth " +
        "FROM faviconSites, favicons WHERE " +
        "faviconSites.faviconID = favicons.id " +
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
        "CREATE TABLE IF NOT EXISTS \(TableBookmarks) (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "guid TEXT NOT NULL UNIQUE, " +
        "type TINYINT NOT NULL, " +
        "url TEXT, " +
        "parent INTEGER REFERENCES bookmarks(id) NOT NULL, " +
        "faviconID INTEGER REFERENCES favicons(id) ON DELETE SET NULL, " +
        "title TEXT" +
        ") "

        let queries = [
            history, visits, bookmarks, faviconSites,
            widestFavicons, historyIDsWithIcon, iconForURL,
        ]
        assert(queries.count == AllTablesAndViews.count, "Did you forget to add your table or view to the list?")
        return self.run(db, queries: queries) &&
               self.prepopulateRootFolders(db)
    }

    func updateTable(db: SQLiteDBConnection, from: Int, to: Int) -> Bool {
        if from == to {
            log.debug("Skipping update from \(from) to \(to).")
            return true
        }
        return drop(db) && create(db, version: to)
    }

    func exists(db: SQLiteDBConnection) -> Bool {
        let count = AllTables.count
        let orClause = join(" OR ", Array(count: count, repeatedValue: "name = ?"))
        let tablesSQL = "SELECT name FROM sqlite_master WHERE type = 'table' AND (\(orClause))"

        let res = db.executeQuery(tablesSQL, factory: StringFactory, withArgs: AllTables)
        log.debug("\(res.count) tables exist. Expected \(count)")
        return res.count == AllTables.count
    }

    func drop(db: SQLiteDBConnection) -> Bool {
        let queries = AllViews.map { "DROP VIEW \($0)" } + AllTables.map { "DROP TABLE \($0)" }
        return self.run(db, queries: queries)
    }
}