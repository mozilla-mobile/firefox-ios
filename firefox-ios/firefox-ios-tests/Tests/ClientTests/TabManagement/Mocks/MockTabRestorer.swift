// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import TabDataStore
@testable import Client

@MainActor
final class MockTabRestorer: TabRestorer {
    var restoreTabsResult: TabRestorationResult?
    var restoreTabsCalledCount = 0
    var restoreScreenshotCalls: [Tab] = []

    func restoreTabs(for windowUUID: WindowUUID) async -> TabRestorationResult {
        restoreTabsCalledCount += 1
        return restoreTabsResult ?? TabRestorationResult(
            restoredTabs: [],
            selectedTabUUID: nil,
            windowUUID: windowUUID
        )
    }

    func restoreScreenshot(tab: Tab, onComplete: (() -> Void)?) {
        restoreScreenshotCalls.append(tab)
        onComplete?()
    }
}
