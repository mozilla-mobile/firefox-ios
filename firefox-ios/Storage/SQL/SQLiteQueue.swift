// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

open class SQLiteQueue: TabQueue {
    let db: BrowserDB

    public init(db: BrowserDB) {
        self.db = db
    }

    open func addToQueue(_ tab: ShareItem) -> Success {
        let args: Args = [tab.url, tab.title]
        return db.run("INSERT OR IGNORE INTO queue (url, title) VALUES (?, ?)", withArgs: args)
    }

    fileprivate func factory(_ row: SDRow) -> ShareItem {
        guard let url = row["url"] as? String, let title = row["title"] as? String else {
            return ShareItem(url: "", title: "")
        }
        return ShareItem(url: url, title: title)
    }

    open func getQueuedTabs(completion: @escaping ([ShareItem]) -> Void) {
        let sql = "SELECT url, title FROM queue"
        let deferredResponse = db.runQuery(sql, args: nil, factory: self.factory) >>== { cursor in
            return deferMaybe(cursor.asArray())
        }

        deferredResponse.upon { result in
            completion(result.successValue ?? [])
        }
    }

    open func clearQueuedTabs() -> Success {
        return db.run("DELETE FROM queue")
    }
}
