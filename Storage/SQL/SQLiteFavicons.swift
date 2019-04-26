/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

open class SQLiteFavicons {
    let db: BrowserDB

    required public init(db: BrowserDB) {
        self.db = db
    }

    public func getFaviconIDQuery(url: String) -> (sql: String, args: Args?) {
        var args: Args = []
        args.append(url)
        return (sql: "SELECT id FROM favicons WHERE url = ? LIMIT 1", args: args)
    }

    public func getInsertFaviconQuery(favicon: Favicon) -> (sql: String, args: Args?) {
        var args: Args = []
        args.append(favicon.url)
        args.append(favicon.width)
        args.append(favicon.height)
        args.append(favicon.date)
        return (sql: "INSERT INTO favicons (url, width, height, type, date) VALUES (?,?,?,0,?)", args: args)
    }

    public func getUpdateFaviconQuery(favicon: Favicon) -> (sql: String, args: Args?) {
        var args = Args()
        args.append(favicon.width)
        args.append(favicon.height)
        args.append(favicon.date)
        args.append(favicon.url)
        return (sql: "UPDATE favicons SET width = ?, height = ?, date = ? WHERE url = ?", args: args)
    }

    public func getCleanupFaviconsQuery() -> (sql: String, args: Args?) {
        let sql = """
            DELETE FROM favicons
            WHERE favicons.id NOT IN (
                SELECT faviconID FROM favicon_sites
            )
            """

        return (sql: sql, args: nil)
    }

    public func getCleanupFaviconSiteURLsQuery() -> (sql: String, args: Args?) {
        let sql = """
            DELETE FROM favicon_site_urls
            WHERE id IN (
                SELECT favicon_site_urls.id FROM favicon_site_urls
                LEFT OUTER JOIN history ON favicon_site_urls.site_url = history.url
                WHERE history.id IS NULL
            )
            """

        return (sql: sql, args: nil)
    }

    public func insertOrUpdateFavicon(_ favicon: Favicon) -> Deferred<Maybe<Int>> {
        return db.withConnection { conn -> Int in
            self.insertOrUpdateFaviconInTransaction(favicon, conn: conn) ?? 0
        }
    }

    func insertOrUpdateFaviconInTransaction(_ favicon: Favicon, conn: SQLiteDBConnection) -> Int? {
        let query = self.getFaviconIDQuery(url: favicon.url)
        let cursor = conn.executeQuery(query.sql, factory: IntFactory, withArgs: query.args)

        if let id = cursor[0] {
            let updateQuery = self.getUpdateFaviconQuery(favicon: favicon)
            do {
                try conn.executeChange(updateQuery.sql, withArgs: updateQuery.args)
            } catch {
                return nil
            }

            return id
        }

        let insertQuery = self.getInsertFaviconQuery(favicon: favicon)
        do {
            try conn.executeChange(insertQuery.sql, withArgs: insertQuery.args)
        } catch {
            return nil
        }

        return Int(conn.lastInsertedRowID)
    }
}
