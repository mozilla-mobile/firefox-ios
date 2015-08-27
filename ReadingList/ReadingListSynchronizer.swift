/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum ReadingListSynchronizerResult {
    case Success
    case Failure
    case Error(NSError)
}

enum ReadingListSyncType {
    case UploadOnly
    case Full
}

class ReadingListSynchronizer {
    var storage: ReadingListStorage
    var client: ReadingListClient

    init(storage: ReadingListStorage, client: ReadingListClient) {
        self.storage = storage
        self.client = client
    }

    func synchronize(type type: ReadingListSyncType, completion: (ReadingListSynchronizerResult) -> Void) {
        // TODO Check if we are already syncing - Keep state somewhere
        // TODO If this is a first time sync then we want to remember the account and server in storage, so that:
        // TODO Check if the client is configured to use a different account or server
        switch type {
        case .UploadOnly:
            let synchronizer = ReadingListUploadOnlySynchronizer(storage: storage, client: client)
            synchronizer.synchronizeWithCompletion(completion)
        case .Full:
            let synchronizer = ReadingListFullSynchronizer(storage: storage, client: client)
            synchronizer.synchronizeWithCompletion(completion)
        }
    }
}

// This is implemented in two different classes to make the design simpler. There will be some duplicate
// code but I prefer that instead of having two implementations in one class.

private class ReadingListUploadOnlySynchronizer {
    var storage: ReadingListStorage
    var client: ReadingListClient

    init(storage: ReadingListStorage, client: ReadingListClient) {
        self.storage = storage
        self.client = client
    }

    func synchronizeWithCompletion(completion: (ReadingListSynchronizerResult) -> Void) {
    }
}

private class ReadingListFullSynchronizer {
    var storage: ReadingListStorage
    var client: ReadingListClient

    init(storage: ReadingListStorage, client: ReadingListClient) {
        self.storage = storage
        self.client = client
    }

    func synchronizeWithCompletion(completion: (ReadingListSynchronizerResult) -> Void) {
    }
}
