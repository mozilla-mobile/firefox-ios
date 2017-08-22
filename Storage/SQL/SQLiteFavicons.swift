/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Deferred
import Shared

open class SQLiteFavicons {
    let db: BrowserDB
    
    required public init(db: BrowserDB) {
        self.db = db
    }
    
    public func getFaviconIDQuery(url: String) -> (sql: String, args: Args?) {
        var args: Args = []
        args.append(url)
        return (sql: "SELECT id FROM \(TableFavicons) WHERE url = ? LIMIT 1", args: args)
    }
    
    public func getInsertFaviconQuery(favicon: Favicon) -> (sql: String, args: Args?) {
        var args: Args = []
        args.append(favicon.url)
        args.append(favicon.width)
        args.append(favicon.height)
        args.append(favicon.date)
        args.append(favicon.type.rawValue)
        return (sql: "INSERT INTO \(TableFavicons) (url, width, height, date, type) VALUES (?,?,?,?,?)", args: args)
    }
    
    public func getUpdateFaviconQuery(favicon: Favicon) -> (sql: String, args: Args?) {
        var args = Args()
        args.append(favicon.width)
        args.append(favicon.height)
        args.append(favicon.date)
        args.append(favicon.type.rawValue)
        args.append(favicon.url)
        return (sql: "UPDATE \(TableFavicons) SET width = ?, height = ?, date = ?, type = ? WHERE url = ?", args: args)
    }
    
    public func getCleanupFaviconsQuery() -> (sql: String, args: Args?) {
        return (sql: "DELETE FROM \(TableFavicons) " +
            "WHERE \(TableFavicons).id NOT IN (" +
            "SELECT faviconID FROM \(TableFaviconSites) " +
            "UNION ALL " +
            "SELECT faviconID FROM \(TableBookmarksLocal) WHERE faviconID IS NOT NULL " +
            "UNION ALL " +
            "SELECT faviconID FROM \(TableBookmarksMirror) WHERE faviconID IS NOT NULL" +
            ")", args: nil)
    }
    
    public func insertOrUpdateFavicon(_ favicon: Favicon) -> Deferred<Maybe<Int>> {
        return self.db.runWithConnection { (conn, _) -> Int in
            return self.insertOrUpdateFaviconInTransaction(favicon, conn: conn) ?? 0
        }
    }
    
    func insertOrUpdateFaviconInTransaction(_ favicon: Favicon, conn: SQLiteDBConnection) -> Int? {
        let query = self.getFaviconIDQuery(url: favicon.url)
        let cursor = conn.executeQuery(query.sql, factory: IntFactory, withArgs: query.args)
        
        if let id = cursor[0] {
            let updateQuery = self.getUpdateFaviconQuery(favicon: favicon)
            if let _ = conn.executeChange(updateQuery.sql, withArgs: updateQuery.args) {
                return nil
            }
            
            return id
        }
        
        let insertQuery = self.getInsertFaviconQuery(favicon: favicon)
        if let _ = conn.executeChange(insertQuery.sql, withArgs: insertQuery.args) {
            return nil
        }
        
        return conn.lastInsertedRowID
    }
    
    public func cleanupFavicons() -> Success {
        return self.db.run([getCleanupFaviconsQuery()])
    }
}
