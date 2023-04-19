// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore

class MockTabDataStore: TabDataStore {
    var fetchTabDataCalledCount = 0
    var fetchAllWindowsDataCount = 0
    var fetchWindowDataWithIDCalledCount = 0
    var saveTabDataCalledCount = 0
    var fetchTabWindowData: WindowData?
    var saveWindowData: WindowData?
    var allWindowsData: [WindowData]?

    func fetchWindowData() async -> WindowData {
        fetchTabDataCalledCount += 1
        return fetchTabWindowData ?? WindowData(id: UUID(), isPrimary: true, activeTabId: UUID(), tabData: [])
    }
    func fetchWindowData() async -> WindowData? {
        fetchTabDataCalledCount += 1
        return fetchTabWindowData
    }

    func saveWindowData(window: WindowData) async {
        saveTabDataCalledCount += 1
        saveWindowData = window
    }

    func clearAllTabData() async {}
    func clearAllWindowsData() async {}
    func fetchWindowData(withID id: UUID) async -> WindowData? {
        fetchWindowDataWithIDCalledCount += 1
        return fetchTabWindowData
    }
    func fetchAllWindowsData() async -> [WindowData] {
        fetchAllWindowsDataCount += 1
        return allWindowsData ?? [WindowData]()
    }
    func clearWindowData(for id: UUID) async {}
}
