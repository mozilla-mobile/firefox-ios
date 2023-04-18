// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore

class MockTabDataStore: TabDataStore {
    var fetchTabDataCalledCount = 0
    var saveTabDataCalledCount = 0
    var fetchTabWindowData: WindowData?
    var saveWindowData: WindowData?

    func fetchTabData() async -> WindowData? {
        fetchTabDataCalledCount += 1
        return fetchTabWindowData
    }

    func saveTabData(window: WindowData) async {
        saveTabDataCalledCount += 1
        saveWindowData = window
    }

    func clearAllTabData() async {}
}
