// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore

class MockTabSessionStore: TabSessionStore {
    var saveTabSessionCallCount = 0
    var tabID: UUID?
    var sessionData: Data?

    func saveTabSession(tabID: UUID, sessionData: Data) {
        saveTabSessionCallCount += 1
        self.tabID = tabID
        self.sessionData = sessionData
    }

    func fetchTabSession(tabID: UUID) -> Data? {
        return Data()
    }

    func clearAllData() {}

    func deleteUnusedTabSessionData(keeping: [UUID]) {}
}
