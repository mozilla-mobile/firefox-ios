// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore
import Common

final class MockTabDataStore: TabDataStore, @unchecked Sendable {
    var fetchWindowDataCalledCount = 0
    var suspendFetch = false
    var onFetch: (@Sendable () -> Void)?
    private var fetchContinuation: CheckedContinuation<WindowData?, Never>?
    var saveWindowDataCalledCount = 0
    var saveWindowDataForcedValue = false
    var fetchTabWindowData: WindowData?
    var saveWindowData: WindowData?
    var onSave: (@Sendable (WindowData) -> Void)?
    var clearAllWindowsDataCalled = 0
    var removeWindowDataCalled = 0
    private var persistedTabWindowUUIDs: [UUID] = []

    func fetchWindowDataUUIDs() -> [UUID] {
        return persistedTabWindowUUIDs
    }

    func fetchWindowData(uuid: UUID) async -> WindowData? {
        fetchWindowDataCalledCount += 1
        if suspendFetch {
            return await withCheckedContinuation {
                fetchContinuation = $0
                onFetch?()
            }
        }
        return fetchTabWindowData
    }

    func resumeFetch() {
        fetchContinuation?.resume(returning: fetchTabWindowData)
        fetchContinuation = nil
        suspendFetch = false
    }

    func saveWindowData(window: WindowData, forced: Bool) async {
        saveWindowDataCalledCount += 1
        saveWindowDataForcedValue = forced
        saveWindowData = window
        onSave?(window)
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
