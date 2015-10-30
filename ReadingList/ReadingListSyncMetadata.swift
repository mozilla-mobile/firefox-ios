/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum ReadingListSyncChanges {

}

enum ReadingListSyncStatus {
    case Synced
    case New
    case Deleted
    case Modified
}

enum ReadingListSyncChange {
    case None, Unread, Favorite, Resolved
}

struct ReadingListSyncMetadata {
    var changes: ReadingListSyncChanges
    var status: ReadingListSyncStatus
}