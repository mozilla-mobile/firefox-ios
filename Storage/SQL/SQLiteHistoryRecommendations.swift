// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import XCGLogger

fileprivate let log = Logger.syncLogger

extension SQLiteHistory: HistoryRecommendations {
    static let MaxHistoryRowCount: UInt = 200000
    static let PruneHistoryRowCount: UInt = 10000

    public func cleanupHistoryIfNeeded() {
        DispatchQueue.global(qos: .background).async {
            self.checkIfCleanupIsNeeded(maxHistoryRows: SQLiteHistory.MaxHistoryRowCount) >>== { doCleanup in
                if doCleanup {
                    _ = self.db.run(self.cleanupOldHistory(numberOfRowsToPrune: SQLiteHistory.PruneHistoryRowCount))
                }
            }
        }
    }

    // Checks if there are more than the specified number of rows in the
    // `history` table. This is used as an indicator that `cleanupOldHistory()`
    // needs to run.
    func checkIfCleanupIsNeeded(maxHistoryRows: UInt) -> Deferred<Maybe<Bool>> {
        let sql = "SELECT COUNT(rowid) > \(maxHistoryRows) AS cleanup FROM \(TableHistory)"
        return self.db.runQueryConcurrently(sql, args: nil, factory: IntFactory) >>== { cursor in
            guard let cleanup = cursor[0], cleanup > 0 else {
                return deferMaybe(false)
            }

            return deferMaybe(true)
        }
    }

    // Deletes the specified number of items from the `history` table and
    // their corresponding items in the `visits` table. This only gets run
    // when the `checkIfCleanupIsNeeded()` method returns `true`. It is possible
    // that a single clean-up operation may not remove enough rows to drop below
    // the threshold used in `checkIfCleanupIsNeeded()` and therefore, this may
    // end up running several times until that threshold is crossed.
    func cleanupOldHistory(numberOfRowsToPrune: UInt) -> [(String, Args?)] {
        log.debug("Cleaning up \(numberOfRowsToPrune) rows of history.")

        let sql = """
            DELETE FROM \(TableHistory) WHERE id IN (
                SELECT siteID
                FROM \(TableVisits)
                GROUP BY siteID
                ORDER BY max(date) ASC
                LIMIT \(numberOfRowsToPrune)
            )
            """
        return [(sql, nil)]
    }

    public func repopulate(invalidateTopSites shouldInvalidateTopSites: Bool) -> Success {
        if shouldInvalidateTopSites {
            return db.run(refreshTopSitesQuery())
        } else {
            return succeed()
        }
    }

}
