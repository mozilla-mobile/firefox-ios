/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum ReadingListSyncChanges {

}

enum ReadingListSyncStatus {
    case synced
    case new
    case deleted
    case modified
}

enum ReadingListSyncChange {
    case none, unread, favorite, resolved
}

struct ReadingListSyncMetadata {
    var changes: ReadingListSyncChanges
    var status: ReadingListSyncStatus
}
