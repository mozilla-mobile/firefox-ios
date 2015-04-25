/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public typealias ReadingListRecordId = Int64
public typealias ReadingListTimestamp = Int64

func ReadingListNow() -> ReadingListTimestamp {
    return ReadingListTimestamp(NSDate.timeIntervalSinceReferenceDate() * 1000.0)
}

let ReadingListDefaultUnread: Bool = true
let ReadingListDefaultFavorite: Bool = false
let ReadingListDefaultArchived: Bool = false
