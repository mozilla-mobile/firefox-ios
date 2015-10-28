/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.syncLogger

public class SQLiteQueue: TabQueue {
    let db: BrowserDB

    public init(db: BrowserDB) {
        // BrowserTable exists only to perform create/update etc. operations -- it's not
        // a queryable thing that needs to stick around.
        db.createOrUpdate(BrowserTable())
        self.db = db
    }

    public func addToQueue(tab: ShareItem) -> Success {
        let args: Args = [tab.url, tab.title]
        return db.run("INSERT OR IGNORE INTO \(TableQueuedTabs) (url, title) VALUES (?, ?)", withArgs: args)
    }

    private func factory(row: SDRow) -> ShareItem {
        return ShareItem(url: row["url"] as! String, title: row["title"] as? String, favicon: nil)
    }

    public func getQueuedTabs() -> Deferred<Maybe<Cursor<ShareItem>>> {
        return db.runQuery("SELECT url, title FROM \(TableQueuedTabs)", args: nil, factory: self.factory)
    }

    public func clearQueuedTabs() -> Success {
        return db.run("DELETE FROM \(TableQueuedTabs)")
    }
}