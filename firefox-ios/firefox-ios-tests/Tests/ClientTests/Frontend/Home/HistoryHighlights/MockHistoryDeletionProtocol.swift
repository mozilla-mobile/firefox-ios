// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

class MockHistoryDeletionProtocol: HistoryDeletionProtocol {
    var deleteCallCount = 0
    var deleteCompletion: ((Bool) -> Void)?

    func delete(_ sites: [String], completion: @escaping (Bool) -> Void) {
        deleteCallCount += 1
        deleteCompletion = completion
    }

    func callDeleteCompletion(result: Bool) {
        deleteCompletion?(result)
    }

    func deleteHistoryFrom(_ dateOption: HistoryDeletionUtilityDateOptions,
                           completion: @escaping (HistoryDeletionUtilityDateOptions) -> Void) {}
}
