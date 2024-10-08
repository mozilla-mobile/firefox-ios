// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

import Common
@testable import Client

class HistoryPanelTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var notificationCenter: MockNotificationCenter!
    override func setUp() {
        super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        DependencyHelperMock().bootstrapDependencies()
        notificationCenter = MockNotificationCenter()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        notificationCenter = nil
    }

    func testHistoryButtons() {
        let panel = createSubject()

        // There is 2 flexible space to keep buttons to the left
        XCTAssertEqual(panel.bottomToolbarItems.count, 4, "Expected Delete, Search buttons and 2 flexible spaces")
    }

    func testHistorySearch_ForStartSearch() {
        let panel = createSubject()

        panel.updatePanelState(newState: .history(state: .mainView))
        panel.startSearchState()

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 4, "Expected Edit button and flexibleSpace")
    }

    func testHistorySearch_ForExitSearch() {
        let panel = createSubject()

        panel.updatePanelState(newState: .history(state: .search))
        panel.handleRightTopButton()

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 4, "Expected Edit button and flexibleSpace")
    }

    func testHistoryInFolder() {
        let panel = createSubject()

        panel.updatePanelState(newState: .history(state: .inFolder))
        XCTAssertTrue(panel.bottomToolbarItems.isEmpty, "Expected Edit button and flexibleSpace")
    }

    func testHistoryMain_ForBackButtonPress() {
        let panel = createSubject()

        panel.updatePanelState(newState: .history(state: .inFolder))
        panel.handleLeftTopButton()

        let toolbarItems = panel.bottomToolbarItems
        // We need to account for the flexibleSpace item
        XCTAssertEqual(toolbarItems.count, 4, "Expected Edit button and flexibleSpace")
    }

    func testHistoryShouldDismissOnDone_ForSearch() {
        let panel = createSubject()

        panel.updatePanelState(newState: .history(state: .search))
        XCTAssertFalse(panel.shouldDismissOnDone())
    }

    func testHistoryShouldDismissOnDone_ForMain() {
        let panel = createSubject()

        panel.updatePanelState(newState: .history(state: .mainView))
        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    func testHistoryShouldDismissOnDone_ForInFolder() {
        let panel = createSubject()

        panel.updatePanelState(newState: .history(state: .inFolder))
        XCTAssertTrue(panel.shouldDismissOnDone())
    }

    func testHistoryPanel_ShouldReceiveClosedTabNotification() {
        let panel = createSubject()
        panel.loadView()
        notificationCenter.post(name: .OpenRecentlyClosedTabs)

        XCTAssertEqual(notificationCenter.postCallCount, 1)
    }

    private func createSubject() -> HistoryPanel {
        let profile = MockProfile()
        let subject = HistoryPanel(profile: profile, windowUUID: windowUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}
