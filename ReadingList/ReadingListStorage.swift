/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared


class ReadingListStorageError: MaybeErrorType {
    var message: String
    init(_ message: String) {
        self.message = message
    }
    var description: String {
        return message
    }
}

/// Storage protocol. The only thing the client (application) communicates with is the storage. Adding, removing and updating items.
protocol ReadingListStorage {
    func getAllRecords() -> Maybe<[ReadingListClientRecord]>
    func getNewRecords() -> Maybe<[ReadingListClientRecord]>

    // These are the used by the application
    func getUnreadRecords() -> Maybe<[ReadingListClientRecord]>
    func getAvailableRecords() -> Maybe<[ReadingListClientRecord]>
    func deleteRecord(_ record: ReadingListClientRecord) -> Maybe<Void>
    func deleteAllRecords() -> Maybe<Void>
    func createRecordWithURL(_ url: String, title: String, addedBy: String) -> Maybe<ReadingListClientRecord>
    func getRecordWithURL(_ url: String) -> Maybe<ReadingListClientRecord?>
    func updateRecord(_ record: ReadingListClientRecord, unread: Bool) -> Maybe<ReadingListClientRecord?>
}
