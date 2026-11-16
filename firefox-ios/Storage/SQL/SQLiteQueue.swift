// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

public final class SQLiteQueue: TabQueue {
    let db: BrowserDB

    public init(db: BrowserDB) {
        self.db = db
    }

    public func addToQueue(_ tab: ShareItem) -> Success {
        return db.run("INSERT OR IGNORE INTO queue (url) VALUES (?)", withArgs: [tab.url])
    }

    fileprivate func factory(_ row: SDRow) -> ShareItem {
        let url = row["url"] as? String ?? ""
        return ShareItem(url: url, title: "")
    }

    public func getQueuedTabs() async throws -> [ShareItem] {
        let sql = "SELECT url FROM queue"
        return try await withCheckedThrowingContinuation { continuation in
            db.runQuery(sql, args: nil, factory: self.factory).upon { result in
                switch result {
                case .success(let cursor):
                    continuation.resume(returning: cursor.asArray())
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func clearQueuedTabs() -> Success {
        return db.run("DELETE FROM queue")
    }
}
