/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

//import SQLite
import Shared

class ReadingListSQLStorage: ReadingListStorage {

    init(path: String) {
    }

    func getAllRecords() -> Maybe<[ReadingListClientRecord]> {
        return Maybe(success: Array())
    }

    func getNewRecords() -> Maybe<[ReadingListClientRecord]> {
        return Maybe(success: Array())
    }

    func getUnreadRecords() -> Maybe<[ReadingListClientRecord]> {
        return Maybe(success: Array())
    }

    func getAvailableRecords() -> Maybe<[ReadingListClientRecord]> {
        return Maybe(success: Array())
    }

    func deleteRecord(_ record: ReadingListClientRecord) -> Maybe<Void> {
        return Maybe(success: Void())
    }

    func deleteAllRecords() -> Maybe<Void> {
        return Maybe(success: Void())
    }

    func createRecordWithURL(_ url: String, title: String, addedBy: String) -> Maybe<ReadingListClientRecord> {
        return Maybe(failure: ReadingListStorageError("Can't get first item from results"))
    }

    func getRecordWithURL(_ url: String) -> Maybe<ReadingListClientRecord?> {
                    return Maybe(failure: ReadingListStorageError("Can't create RLCR from row"))
    }

    func updateRecord(_ record: ReadingListClientRecord, unread: Bool) -> Maybe<ReadingListClientRecord?> {
                    return Maybe(failure: ReadingListStorageError("Can't create RLCR from row"))
    }
}
