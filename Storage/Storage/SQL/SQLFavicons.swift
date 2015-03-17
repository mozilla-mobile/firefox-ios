/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 * The sqlite-backed implementation of the favicons protocol.
 */
public class SQLiteFavicons : Favicons {
    let files: FileAccessor
    let db: BrowserDB
    let table: JoinedFaviconsHistoryTable<(Site, Favicon)>

    lazy public var defaultIcon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    required public init(files: FileAccessor) {
        self.files = files
        self.db = BrowserDB(files: files)!
        self.table = JoinedFaviconsHistoryTable<(Site, Favicon)>(files: files)
        db.createOrUpdate(table)
    }

    public func clear(options: QueryOptions?, complete: ((success: Bool) -> Void)?) {
        var err: NSError? = nil
        let res = db.delete(&err) { connection, err in
            return self.table.delete(connection, item: nil, err: &err)
        }

        files.remove("favicons", basePath: nil)

        dispatch_async(dispatch_get_main_queue()) {
            complete?(success: err == nil)
            return
        }
    }

    public func get(options: QueryOptions?, complete: (data: Cursor) -> Void) {
        var err: NSError? = nil
        let res = db.query(&err) { connection, err in
            return self.table.query(connection, options: options)
        }

        dispatch_async(dispatch_get_main_queue()) {
            complete(data: res)
        }
    }

    public func add(icon: Favicon, site: Site, complete: ((success: Bool) -> Void)?) {
        var err: NSError? = nil
        let res = db.insert(&err) { connection, err in
            return self.table.insert(connection, item: (icon: icon, site: site), err: &err)
        }

        dispatch_async(dispatch_get_main_queue()) {
            complete?(success: err == nil)
            return
        }
    }

    private let debug_enabled = false
    private func debug(msg: String) {
        if debug_enabled {
            println("FaviconsSqlite: " + msg)
        }
    }
}
