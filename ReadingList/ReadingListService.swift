/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

/// This is the public API that the application and extension talk to. It exposes the bare minimum
/// functions that need to be public and hides details like storage and syncing.
public class ReadingListService {
    var databasePath: String
    var storage: ReadingListStorage

    public init?(profileStoragePath: String) {
        databasePath = (profileStoragePath as NSString).appendingPathComponent("ReadingList.db")
        storage = ReadingListSQLStorage(path: "\(profileStoragePath)/ReadingList.db")
    }

    public func getAvailableRecords() -> Maybe<[ReadingListClientRecord]> {
        return storage.getAvailableRecords()
    }

    public func deleteRecord(_ record: ReadingListClientRecord) -> Maybe<Void> {
        return storage.deleteRecord(record)
    }

    public func deleteAllRecords() -> Maybe<Void>{
        return storage.deleteAllRecords()
    }

    public func createRecord(withURL url: String, title: String, addedBy: String) -> Maybe<ReadingListClientRecord> {
        return storage.createRecord(withURL: url, title: title, addedBy: addedBy)
    }

    public func getRecord(withURL url: String) -> Maybe<ReadingListClientRecord?> {
        return storage.getRecord(withURL: url)
    }

    public func updateRecord(_ record: ReadingListClientRecord, unread: Bool) -> Maybe<ReadingListClientRecord?> {
        return storage.updateRecord(record, unread: unread)
    }
}
