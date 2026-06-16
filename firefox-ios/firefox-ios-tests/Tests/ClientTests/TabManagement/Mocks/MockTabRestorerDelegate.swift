// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore
import Common
@testable import Client

@MainActor
final class MockTabRestorerDelegate: TabRestorerDelegate {
    var createdTabs: [Tab] = []
    var screenshotRestoredTabs: [Tab] = []
    private let profile: MockProfile

    init(profile: MockProfile) {
        self.profile = profile
    }

    func createTab(with tabData: TabData) -> Tab {
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.tabUUID = tabData.id.uuidString
        createdTabs.append(tab)
        return tab
    }

    func restoreScreenshot(for tab: Tab) {
        screenshotRestoredTabs.append(tab)
    }
}
