// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

class ReadingListMock: ReadingList {
    var getAvailableRecordsCallCount = 0
    var getAvailableRecordsCompletion: (([ReadingListItem]) -> Void)?

    func getAvailableRecords(completion: @escaping ([ReadingListItem]) -> Void) {
        getAvailableRecordsCallCount += 1
        getAvailableRecordsCompletion = completion
    }

    func callGetAvailableRecordsCompletion(with results: [ReadingListItem]) {
        getAvailableRecordsCompletion?(results)
    }

    func getAvailableRecords() -> Deferred<Maybe<[ReadingListItem]>> {
        return deferMaybe([])
    }

    func deleteRecord(_ record: ReadingListItem, completion: ((Bool) -> Void)?) {}

    func createRecordWithURL(_ url: String, title: String, addedBy: String) -> Deferred<Maybe<ReadingListItem>> {
        return deferMaybe(ReadingListStorageError("Function not mocked"))
    }

    func getRecordWithURL(_ url: String) -> Deferred<Maybe<ReadingListItem>> {
        return deferMaybe(ReadingListStorageError("Function not mocked"))
    }

    func updateRecord(_ record: ReadingListItem, unread: Bool) -> Deferred<Maybe<ReadingListItem>> {
        return deferMaybe(ReadingListStorageError("Function not mocked"))
    }
}
