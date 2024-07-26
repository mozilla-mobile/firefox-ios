// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore
import Common

class MockTabDataStore: TabDataStore {
    var fetchWindowDataCalledCount = 0
    var saveWindowDataCalledCount = 0
    var fetchTabWindowData: WindowData?
    var saveWindowData: WindowData?
    var clearAllWindowsDataCalled = 0
    var removeWindowDataCalled = 0
    private var persistedTabWindowUUIDs: [UUID] = []

    func fetchWindowDataUUIDs() -> [UUID] {
        return persistedTabWindowUUIDs
    }

    func fetchWindowData(uuid: UUID) async -> WindowData? {
        fetchWindowDataCalledCount += 1
        return fetchTabWindowData
    }

    func saveWindowData(window: WindowData, forced: Bool) async {
        saveWindowDataCalledCount += 1
        saveWindowData = window
    }

    func clearAllWindowsData() async {
        clearAllWindowsDataCalled += 1
    }

    func removeWindowData(forUUIDs: [WindowUUID]) async {
        removeWindowDataCalled += 1
    }
}

// Utilities for mocking available tab window UUIDs in unit tests.
extension MockTabDataStore {
    func resetMockTabWindowUUIDs() {
        persistedTabWindowUUIDs.removeAll()
    }

    func injectMockTabWindowUUID(_ uuid: UUID) {
        persistedTabWindowUUIDs.append(uuid)
    }
}
