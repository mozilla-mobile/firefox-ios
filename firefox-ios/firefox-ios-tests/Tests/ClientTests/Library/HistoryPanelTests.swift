// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

import Common
import Storage
@testable import Client

@MainActor
class HistoryPanelTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var notificationCenter: MockNotificationCenter!
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        notificationCenter = MockNotificationCenter()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        notificationCenter = nil
        try await super.tearDown()
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

    func testHistoryDeleteSwipeAction_avoidsDestructiveStyleAnimation() throws {
        let panel = createSubject()
        let tableView = try populateHistory(panel)
        let configuration = try XCTUnwrap(panel.tableView(
            tableView,
            trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 1, section: 1)
        ))
        let deleteAction = try XCTUnwrap(configuration.actions.first)

        XCTAssertEqual(configuration.actions.count, 1)
        XCTAssertEqual(deleteAction.style, .normal)
        XCTAssertEqual(deleteAction.backgroundColor, .systemRed)
        XCTAssertEqual(deleteAction.title, .HistoryPanelDelete)
        XCTAssertTrue(configuration.performsFirstActionWithFullSwipe)
    }

    func testHistoryDeleteSwipeAction_removesOnlySelectedSiteAndCompletes() throws {
        let panel = createSubject()
        let tableView = try populateHistory(panel)
        let configuration = try XCTUnwrap(panel.tableView(
            tableView,
            trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 1, section: 1)
        ))
        let deleteAction = try XCTUnwrap(configuration.actions.first)
        var completionResults = [Bool]()

        deleteAction.handler(deleteAction, tableView) { completionResults.append($0) }

        XCTAssertEqual(completionResults, [true])
        XCTAssertEqual(panel.viewModel.dateGroupedSites.allItems().map(\.url), [
            "https://example.com/first", "https://example.com/last"
        ])
        XCTAssertEqual(panel.diffableDataSource?.snapshot().numberOfItems(inSection: .lastHour), 2)
    }

    func testHistoryDeleteSwipeAction_inSearch_removesOnlySelectedResultAndCompletes() throws {
        let panel = createSubject()
        let tableView = try populateHistory(panel, searching: true)
        let configuration = try XCTUnwrap(panel.tableView(
            tableView,
            trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 1, section: 0)
        ))
        let deleteAction = try XCTUnwrap(configuration.actions.first)
        var completionResults = [Bool]()

        deleteAction.handler(deleteAction, tableView) { completionResults.append($0) }

        XCTAssertEqual(completionResults, [true])
        XCTAssertEqual(panel.viewModel.searchResultSites.map(\.url), [
            "https://example.com/first", "https://example.com/last"
        ])
        XCTAssertEqual(panel.viewModel.dateGroupedSites.allItems().count, 2)
        XCTAssertEqual(panel.diffableDataSource?.snapshot().numberOfItems(inSection: .searchResults), 2)
    }

    func testHistoryDeleteSwipeAction_isUnavailableForRecentlyClosedRow() throws {
        let panel = createSubject()
        let tableView = try populateHistory(panel)

        XCTAssertNil(panel.tableView(
            tableView,
            trailingSwipeActionsConfigurationForRowAt: IndexPath(row: 0, section: 0)
        ))
    }

    private func populateHistory(_ panel: HistoryPanel, searching: Bool = false) throws -> UITableView {
        panel.loadViewIfNeeded()
        let tableView = try XCTUnwrap(panel.view.subviews.compactMap { $0 as? UITableView }.first)
        let sites = [
            Site.createBasicSite(url: "https://example.com/first", title: "First"),
            Site.createBasicSite(url: "https://example.com/middle", title: "Middle"),
            Site.createBasicSite(url: "https://example.com/last", title: "Last")
        ]
        for site in sites {
            panel.viewModel.dateGroupedSites.add(site, timestamp: Date().timeIntervalSince1970)
        }
        panel.viewModel.visibleSections = [.lastHour]
        panel.viewModel.isSearchInProgress = searching
        if searching {
            panel.viewModel.searchResultSites = sites
            panel.applySearchSnapshot()
        } else {
            panel.applySnapshot()
        }
        return tableView
    }

    private func createSubject() -> HistoryPanel {
        let profile = MockProfile()
        let subject = HistoryPanel(profile: profile, windowUUID: windowUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}
