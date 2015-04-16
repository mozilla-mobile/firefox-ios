/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared


class ReadingListStorageError: ErrorType {
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
    func getAllRecords() -> Result<[ReadingListClientRecord]>
    func getNewRecords() -> Result<[ReadingListClientRecord]>

    // These are the used by the application
    func getUnreadRecords() -> Result<[ReadingListClientRecord]>
    func getAvailableRecords() -> Result<[ReadingListClientRecord]>
    func deleteRecord(record: ReadingListClientRecord) -> Result<Void>
    func deleteAllRecords() -> Result<Void>
    func createRecordWithURL(url: String, title: String, addedBy: String) -> Result<ReadingListClientRecord>
    func getRecordWithURL(url: String) -> Result<ReadingListClientRecord?>
    func updateRecord(record: ReadingListClientRecord, unread: Bool) -> Result<ReadingListClientRecord?>
}
