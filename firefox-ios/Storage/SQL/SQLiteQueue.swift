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
        return db.run("INSERT OR IGNORE INTO queue (url) VALUES (?)", withArgs: [tab.url])
    }

    fileprivate func factory(_ row: SDRow) -> ShareItem {
        let url = row["url"] as? String ?? ""
        return ShareItem(url: url, title: "")
    }

    open func getQueuedTabs(completion: @MainActor @Sendable @escaping ([ShareItem]) -> Void) {
        let sql = "SELECT url FROM queue"
        db.runQuery(sql, args: nil, factory: self.factory)
            .uponQueue(.main) { result in
                guard let cursor = result.successValue else { return }
                // FXIOS-13228 It should be safe to assumeIsolated here because of `.main` queue above
                MainActor.assumeIsolated {
                    completion(cursor.asArray())
                }
            }
    }

    open func clearQueuedTabs() -> Success {
        return db.run("DELETE FROM queue")
    }
}
