/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
* The sqlite-backed implementation of the history protocol.
*/
public class SQLiteFavicons : Favicons {
    let files: FileAccessor
    let db: BrowserDB
    let table: FaviconSiteTable

    required public init(files: FileAccessor) {
        self.files = files
        self.db = BrowserDB(files: files)!
        table = FaviconSiteTable(files: files)
        self.db.create(table)
    }

    public func clear(complete: (success: Bool) -> Void) {
        var err: NSError? = nil
        db.delete(&err) { (connection, err) -> Int in
            return self.table.delete(connection, item: nil, err: &err)
        }

        dispatch_async(dispatch_get_main_queue()) {
            if err != nil {
                self.debug("Clear failed: \(err!.localizedDescription)")
            }
        }
    }

    public func get(options: QueryOptions?, complete: (data: Cursor) -> Void) {
        var err: NSError? = nil
        let res = db.query(&err) { (connection, err) -> Cursor in
            return self.table.query(connection, options: options)
        }
        dispatch_async(dispatch_get_main_queue()) {
            complete(data: res)
        }
    }

    public func add(favicon: Favicon, site: Site, complete: (success: Bool) -> Void) {
        let saved = SavedFavicon(favicon: favicon)
        saved.download(files)

        var err: NSError? = nil
        let inserted = db.insert(&err) { (connection, err) -> Int in
            return self.table.insert(connection, item: (site: site, icon: SavedFavicon(favicon: favicon)), err: &err)
        }

        dispatch_async(dispatch_get_main_queue()) {
            if err != nil {
                self.debug("Add failed: \(err!.localizedDescription)")
            }
            complete(success: err == nil)
        }
    }

    private let debug_enabled = false
    private func debug(msg: String) {
        if debug_enabled {
            println("FaviconsSqlite: " + msg)
        }
    }
}
