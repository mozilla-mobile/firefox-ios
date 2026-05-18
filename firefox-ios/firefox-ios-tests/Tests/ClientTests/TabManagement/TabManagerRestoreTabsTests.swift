// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import TabDataStore
import Common
@testable import Client

final class TabManagerRestoreTabsTests: TabManagerTestsBase {
    @MainActor
    func testRestoreTabs() {
        // Needed to ensure AppEventQueue is not fired from a previous test case with the same WindowUUID
        let testUUID = UUID()
        let subject = createSubject(windowUUID: testUUID)
        let expectation = XCTestExpectation(description: "Tab restoration event should have been called")
        mockTabStore.fetchTabWindowData = WindowData(id: UUID(),
                                                     activeTabId: UUID(),
                                                     tabData: getMockTabData(count: 4))

        subject.restoreTabs()

        AppEventQueue.wait(for: .tabRestoration(testUUID)) { [mockTabStore] in
            ensureMainThread {
                XCTAssertEqual(subject.tabs.count, 4)
                XCTAssertEqual(mockTabStore?.fetchWindowDataCalledCount, 1)
                expectation.fulfill()
            }
        }
        wait(for: [expectation])
    }

    // TODO: FXIOS-15742 - Add tests as part of the deeplink improvements refactor
}
