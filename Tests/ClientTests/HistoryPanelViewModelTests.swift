// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Storage
import Shared

@testable import Client

class HistoryPanelViewModelTests: XCTestCase {

    var sut: HistoryPanelViewModel!
    var profile: MockProfile!

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "HistoryPanelViewModelTest")

        ThemeManager.shared.updateProfile(with: profile)
        profile._reopen()
        sut = HistoryPanelViewModel(profile: profile)
    }

    override func tearDown() {
        super.tearDown()

        clear(profile.history)
        profile._shutdown()
        profile = nil
        sut = nil
    }

    func testHistorySectionTitle() {
        HistoryPanelViewModel.Sections.allCases.forEach({ section in
            switch section {
            case .today:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.Today)
            case .yesterday:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.Yesterday)
            case .lastWeek:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.LastWeek)
            case .lastMonth:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.LastMonth)
            case .older:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.Older)
            case .additionalHistoryActions, .searchResults:
                XCTAssertNil(section.title)
            }
        })
    }

    func testFetchHistory_WithResults() {
        setupSiteVisits()

        fetchHistory { success in
            XCTAssertTrue(success)
            XCTAssertNotNil(self.sut.searchTermGroups)
            XCTAssertFalse(self.sut.groupedSites.isEmpty)
            XCTAssertFalse(self.sut.visibleSections.isEmpty)
        }
    }

    func testFetchHistoryFail_WithFetchInProgress() {
        sut.isFetchInProgress = true

        fetchHistory { success in
            XCTAssertFalse(success)
        }
    }

    func testPerformSearch_ForNoResults() {
        fetchSearchHistory(searchTerm: "moz") { hasResults in
            XCTAssertFalse(hasResults)
            XCTAssertEqual(self.sut.searchResultSites.count, 0)
        }
    }

    func testPerformSearch_WithResults() {
        setupSiteVisits()

        fetchSearchHistory(searchTerm: "moz") { hasResults in
            XCTAssertTrue(hasResults)
            XCTAssertEqual(self.sut.searchResultSites.count, 2)
        }
    }

    func testEmptyStateText_ForSearch() {
        sut.isSearchInProgress = true
        XCTAssertEqual(sut.emptyStateText, .LibraryPanel.History.NoHistoryResult)
    }

    func testEmptyStateText_ForHistoryResults() {
        sut.isSearchInProgress = false
        XCTAssertEqual(sut.emptyStateText, .HistoryPanelEmptyStateTitle)
    }

    func testShouldShowEmptyState_ForEmptySearch() {
        setupSiteVisits()
        sut.isSearchInProgress = true

        fetchSearchHistory(searchTerm: "") { hasResults in
            XCTAssertFalse(self.sut.shouldShowEmptyState(searchText: ""))
        }
    }

    func testShouldShowEmptyState_ForNoResultSearch() {
        setupSiteVisits()
        sut.isSearchInProgress = true

        fetchSearchHistory(searchTerm: "ui") { hasResults in
            XCTAssertTrue(self.sut.shouldShowEmptyState(searchText: "ui"))
        }
    }

    func testShouldShowEmptyState_ForNoHistory() {
        sut.isSearchInProgress = false

        fetchHistory { _ in
            XCTAssertTrue(self.sut.shouldShowEmptyState())
        }
    }

    func testCollapseSection() {
        setupSiteVisits()
        XCTAssertTrue(sut.hiddenSections.isEmpty)

        fetchHistory { _ in
            self.sut.collapseSection(sectionIndex: 1)
            XCTAssertEqual(self.sut.hiddenSections.count, 1)
            // Starts at 0, removing the Additional section
            XCTAssertTrue(self.sut.isSectionCollapsed(sectionIndex: 0))
            XCTAssertTrue(self.sut.hiddenSections.contains(where: { $0 == .today }))
        }
    }

    func testExpandSection() {
        setupSiteVisits()
        XCTAssertTrue(sut.hiddenSections.isEmpty)

        fetchHistory { _ in
            self.sut.collapseSection(sectionIndex: 1)
            XCTAssertEqual(self.sut.hiddenSections.count, 1)
            // Starts at 0, removing the Additional section
            XCTAssertTrue(self.sut.isSectionCollapsed(sectionIndex: 0))
            XCTAssertTrue(self.sut.hiddenSections.contains(where: { $0 == .today }))

            self.sut.collapseSection(sectionIndex: 1)
            XCTAssertTrue(self.sut.hiddenSections.isEmpty)
            XCTAssertFalse(self.sut.isSectionCollapsed(sectionIndex: 1))
        }
    }

    func testRemoveAllData() {
        setupSiteVisits()
        XCTAssertTrue(sut.hiddenSections.isEmpty)

        fetchHistory { _ in
            self.sut.removeAllData()

            XCTAssertEqual(self.sut.currentFetchOffset, 0)
            XCTAssertTrue(self.sut.searchTermGroups.isEmpty)
            XCTAssertTrue(self.sut.groupedSites.isEmpty)
            XCTAssertTrue(self.sut.visibleSections.isEmpty)
        }
    }

    func testShouldNotAddGroupToSections() {
        let searchTermGroup = createSearchTermGroup(timestamp: Date.nowMicroseconds())
        XCTAssertNil(self.sut.shouldAddGroupToSections(group: searchTermGroup))
    }

    func testGroupBelongToSection_ForToday() {
        let searchTermGroup = createSearchTermGroup(timestamp: Date.nowMicroseconds())

        guard let section = self.sut.groupBelongsToSection(asGroup: searchTermGroup) else {
            XCTFail("Expected to return today section")
            return
        }

        XCTAssertEqual(section, .today)
    }

    func testGroupBelongToSection_ForYesterday() {
        let yesterday = Date.yesterday
        let searchTermGroup = createSearchTermGroup(timestamp: yesterday.toMicrosecondTimestamp())

        guard let section = self.sut.groupBelongsToSection(asGroup: searchTermGroup) else {
            XCTFail("Expected to return today section")
            return
        }

        XCTAssertEqual(section, .yesterday)
    }

    func testGroupBelongToSection_ForLastWeek() {
        let yesterday = Date().lastWeek
        let searchTermGroup = createSearchTermGroup(timestamp: yesterday.toMicrosecondTimestamp())

        guard let section = self.sut.groupBelongsToSection(asGroup: searchTermGroup) else {
            XCTFail("Expected to return today section")
            return
        }

        XCTAssertEqual(section, .lastWeek)
    }

    func testGroupBelongToSection_ForTwoLastWeek() {
        let yesterday = Date().lastTwoWeek
        let searchTermGroup = createSearchTermGroup(timestamp: yesterday.toMicrosecondTimestamp())

        guard let section = self.sut.groupBelongsToSection(asGroup: searchTermGroup) else {
            XCTFail("Expected to return today section")
            return
        }

        XCTAssertEqual(section, .lastMonth)
    }

    func testShouldAddGroupToSections_ForToday() {
        let searchTermGroup = createSearchTermGroup(timestamp: Date.nowMicroseconds())
        sut.visibleSections.append(.today)

        guard let section = self.sut.shouldAddGroupToSections(group: searchTermGroup) else {
            XCTFail("Expected to return today section")
            return
        }

        XCTAssertEqual(section, .today)
    }

    // MARK: -
    private func setupSiteVisits() {
        addSiteVisit(profile.history, url: "http://mozilla.org/", title: "Mozilla internet")
        addSiteVisit(profile.history, url: "http://mozilla.dev.org/", title: "Internet dev")
        addSiteVisit(profile.history, url: "https://apple.com/", title: "Apple")
    }

    private func addSiteVisit(_ history: BrowserHistory, url: String, title: String, s: Bool = true) {
        let site = Site(url: url, title: title)
        let visit = SiteVisit(site: site, date: Date.nowMicroseconds())
        XCTAssertEqual(s, history.addLocalVisit(visit).value.isSuccess, "Site added: \(url).")
    }

    private func clear(_ history: BrowserHistory) {
        XCTAssertTrue(history.clearHistory().value.isSuccess, "History cleared.")
    }

    private func fetchHistory(completion: @escaping (Bool) -> Void) {
        let expectation = self.expectation(description: "Wait for history")

        sut.reloadData { success in
            XCTAssertNotNil(success)
            completion(success)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    private func fetchSearchHistory(searchTerm: String,
                                    completion: @escaping (Bool) -> Void) {
        let expectation = self.expectation(description: "Wait for history search")

        sut.performSearch(term: searchTerm) { hasResults in
            XCTAssertNotNil(hasResults)
            completion(hasResults)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    private func createSearchTermGroup(timestamp: MicrosecondTimestamp) -> ASGroup<Site> {
        var groupSites = [Site]()
        for i in 0...3 {
            let site = Site(url: "http://site\(i).com", title: "Site \(i)")
            let visit = SiteVisit(site: site, date: timestamp)
            site.latestVisit = Visit(date: timestamp)
            XCTAssertTrue(profile.history.addLocalVisit(visit).value.isSuccess, "Site added: \(site.url).")
            groupSites.append(site)
        }

        return ASGroup<Site>(searchTerm: "site", groupedItems: groupSites, timestamp: timestamp)
    }
}
