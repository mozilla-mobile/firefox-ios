// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore
import Common
import XCTest

final class MockTabDataStore: TabDataStore, @unchecked Sendable {
    var fetchWindowDataCalledCount = 0
    var saveWindowDataCalledCount = 0
    var saveWindowDataForcedValue = false
    var fetchTabWindowData: WindowData?
    var saveWindowData: WindowData?
    var clearAllWindowsDataCalled = 0
    var removeWindowDataCalled = 0
    var removedWindowDataUUIDs: [WindowUUID] = []
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
        saveWindowDataForcedValue = forced
        saveWindowData = window
    }

    func clearAllWindowsData() async {
        clearAllWindowsDataCalled += 1
    }

    var removeWindowDataExpectation: XCTestExpectation?

    /// Reached from unstructured `Task`s (see `WindowManager` and `MergeWindowsManager`), so the
    /// recording is hopped to the main actor that the tests read it from. Mutating these
    /// concurrently traps inside the standard library's Array buffer copy.
    func removeWindowData(forUUIDs: [WindowUUID]) async {
        await MainActor.run {
            removeWindowDataCalled += 1
            removedWindowDataUUIDs.append(contentsOf: forUUIDs)
            // Cleared before fulfilling so a late Task cannot over-fulfil an expectation, which traps.
            let expectation = removeWindowDataExpectation
            removeWindowDataExpectation = nil
            expectation?.fulfill()
        }
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
