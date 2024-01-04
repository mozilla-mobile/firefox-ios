// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class HistoryPanelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
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

    private func createSubject() -> HistoryPanel {
        let profile = MockProfile()
        let tabManager = MockTabManager()
        let subject = HistoryPanel(profile: profile)
        trackForMemoryLeaks(subject)
        return subject
    }
}
