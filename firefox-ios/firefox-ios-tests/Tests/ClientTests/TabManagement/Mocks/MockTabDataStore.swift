// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore

class MockTabDataStore: TabDataStore {
    var fetchWindowDataCalledCount = 0
    var saveWindowDataCalledCount = 0
    var fetchTabWindowData: WindowData?
    var saveWindowData: WindowData?

    func fetchWindowData() async -> WindowData? {
        fetchWindowDataCalledCount += 1
        return fetchTabWindowData
    }

    func saveWindowData(window: WindowData, forced: Bool) async {
        saveWindowDataCalledCount += 1
        saveWindowData = window
    }

    func clearAllWindowsData() async {}
}
