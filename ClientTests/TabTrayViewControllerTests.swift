// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

import XCTest

class TabTrayViewControllerTests: XCTestCase {

    var profile: TabManagerMockProfile!
    var manager: TabManager!
    var tabTray: TabTrayViewController!
    var gridTab: GridTabViewController!

    override func setUp() {
        super.setUp()

        profile = TabManagerMockProfile()
        manager = TabManager(profile: profile, imageStore: nil)
        tabTray = TabTrayViewController(tabTrayDelegate: nil, profile: profile, showChronTabs: false, tabToFocus: nil, tabManager: manager)
        gridTab = GridTabViewController(tabManager: manager, profile: profile)
        manager.addDelegate(gridTab)
    }

    override func tearDown() {
        super.tearDown()

        profile = nil
        manager = nil
        tabTray = nil
        gridTab = nil
    }

    func testCountUpdatesAfterTabRemoval() {
        let tabToRemove = manager.addTab()
        manager.addTab()

        XCTAssertEqual(tabTray.viewModel.normalTabsCount, "2")
        XCTAssertEqual(tabTray.countLabel.text, "2")

        // Wait for notification of .TabClosed when tab is removed
        weak var expectation = self.expectation(description: "notificationReceived")
        NotificationCenter.default.addObserver(forName: .TabClosed, object: nil, queue: nil) { notification in
            expectation?.fulfill()
        }
        manager.removeTab(tabToRemove)
        waitForExpectations(timeout: 1.0, handler: nil)

        XCTAssertEqual(tabTray.viewModel.normalTabsCount, "1")
        XCTAssertEqual(tabTray.countLabel.text, "1")
    }
}
