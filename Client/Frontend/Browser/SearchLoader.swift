/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

// TODO: Swift currently requires that classes extending generic classes must also be generic.
// This is a workaround until that requirement is fixed.
typealias SearchLoader = _SearchLoader<AnyObject, AnyObject>

class _SearchLoader<UnusedA, UnusedB>: Loader<Cursor, SearchViewController> {
    private let history: History

    init(history: History) {
        self.history = history
        super.init()
    }

    var query: String = "" {
        didSet {
            if query.isEmpty {
                self.load(Cursor(status: .Success, msg: "Empty query"))
                return
            }

            let options = QueryOptions(filter: query, filterType: FilterType.Url, sort: QuerySort.Frecency)
            self.history.get(options, complete: { (cursor: Cursor) in
                if cursor.status != .Success {
                    println("Err: \(cursor.statusMessage)")
                } else {
                    self.load(cursor)
                }
            })
        }
    }
}
