// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

import XCTest
import Common
import Shared

final class LegacyTabTrayViewControllerTests: XCTestCase {
    var profile: MockProfile!
    var manager: TabManager!
    var tabTray: LegacyTabTrayViewController!
    var gridTab: LegacyGridTabViewController!
    var overlayManager: MockOverlayModeManager!
    var urlBar: MockURLBarView!

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        manager = TabManagerImplementation(profile: profile,
                                           uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))
        urlBar = MockURLBarView()
        overlayManager = MockOverlayModeManager()
        overlayManager.setURLBar(urlBarView: urlBar)
        tabTray = LegacyTabTrayViewController(tabTrayDelegate: nil,
                                              profile: profile,
                                              tabToFocus: nil,
                                              tabManager: manager,
                                              overlayManager: overlayManager)
        gridTab = LegacyGridTabViewController(tabManager: manager, profile: profile)
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()

        AppContainer.shared.reset()
        profile = nil
        manager = nil
        urlBar = nil
        overlayManager = nil
        tabTray = nil
        gridTab = nil
    }

    func testCountUpdatesAfterTabRemoval() throws {
        let tabToRemove = manager.addTab()
        manager.addTab()

        XCTAssertEqual(tabTray.viewModel.normalTabsCount, "2")
        XCTAssertEqual(tabTray.countLabel.text, "2")

        gridTab.tabDisplayManager.performCloseAction(for: tabToRemove)
        // Wait for notification of .TabClosed when tab is removed
        let expectation = expectation(description: "notificationReceived")
        NotificationCenter.default.addObserver(
            forName: .UpdateLabelOnTabClosed,
            object: nil,
            queue: nil
        ) { notification in
            expectation.fulfill()

            XCTAssertEqual(self.tabTray.viewModel.normalTabsCount, "1")
            XCTAssertEqual(self.tabTray.countLabel.text, "1")
        }

        waitForExpectations(timeout: 3.0)
    }

    func testTabTrayRevertToRegular_ForNoPrivateTabSelected() {
        // If the user selects Private mode but doesn't focus or creates a new tab
        // we considered that regular is actually active
        tabTray.viewModel.segmentToFocus = TabTrayPanelType.privateTabs
        tabTray.viewDidLoad()
        tabTray.didTapDone()

        let privateState = UserDefaults.standard.bool(forKey: PrefsKeys.LastSessionWasPrivate)
        XCTAssertFalse(privateState)
    }
}
