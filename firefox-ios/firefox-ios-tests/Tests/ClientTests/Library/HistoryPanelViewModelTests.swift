// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import MozillaAppServices
import Shared
import Storage
import XCTest

@testable import Client

@MainActor
class HistoryPanelViewModelTests: XCTestCase {
    var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile(databasePrefix: "HistoryPanelViewModelTest")
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        profile.reopen()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        clear(profile: profile)
        profile.shutdown()
        profile = nil
        try await super.tearDown()
    }

    func testHistorySectionTitle() {
        HistoryPanelViewModel.Sections.allCases.forEach({ section in
            switch section {
            case .lastHour:
                XCTAssertEqual(section.title, .LibraryPanel.History.ClearHistorySheet.LastHourOption)
            case .lastTwentyFourHours:
                XCTAssertEqual(section.title, .LibraryPanel.History.ClearHistorySheet.LastTwentyFourHoursOption)
            case .lastSevenDays:
                XCTAssertEqual(section.title, .LibraryPanel.History.ClearHistorySheet.LastSevenDaysOption)
            case .lastFourWeeks:
                XCTAssertEqual(section.title, .LibraryPanel.History.ClearHistorySheet.LastFourWeeksOption)
            case .older:
                XCTAssertEqual(section.title, .LibraryPanel.Sections.Older)
            case .additionalHistoryActions, .searchResults:
                XCTAssertNil(section.title)
            }
        })
    }

    func testFetchHistory_WithResults() {
        let subject = createSubject()
        setupSiteVisits()

        fetchHistory(from: subject) { success in
            XCTAssertTrue(success)
            XCTAssertFalse(subject.dateGroupedSites.isEmpty)
            XCTAssertFalse(subject.visibleSections.isEmpty)
        }
    }

    func testFetchHistoryFail_WithFetchInProgress() {
        let subject = createSubject()
        subject.isFetchInProgress = true

        fetchHistory(from: subject) { success in
            XCTAssertFalse(success)
        }
    }

    func testPerformSearch_ForNoResults() {
        let subject = createSubject()
        fetchSearchHistory(from: subject, searchTerm: "moz") { hasResults in
            XCTAssertFalse(hasResults)
            XCTAssertEqual(subject.searchResultSites.count, 0)
        }
    }

    func testPerformSearch_WithResults() {
        let subject = createSubject()
        setupSiteVisits()

        fetchSearchHistory(from: subject, searchTerm: "moz") { hasResults in
            XCTAssertTrue(hasResults)
            XCTAssertEqual(subject.searchResultSites.count, 2)
        }
    }

    func testEmptyStateText_ForSearch() {
        let subject = createSubject()
        subject.isSearchInProgress = true
        XCTAssertEqual(subject.emptyStateText, .LibraryPanel.History.NoHistoryResult)
    }

    func testEmptyStateText_ForHistoryResults() {
        let subject = createSubject()
        subject.isSearchInProgress = false
        XCTAssertEqual(subject.emptyStateText, .HistoryPanelEmptyStateTitle)
    }

    func testShouldShowEmptyState_ForEmptySearch() {
        let subject = createSubject()
        setupSiteVisits()
        subject.isSearchInProgress = true

        fetchSearchHistory(from: subject, searchTerm: "") { hasResults in
            XCTAssertFalse(subject.shouldShowEmptyState(searchText: ""))
        }
    }

    func testShouldShowEmptyState_ForNoResultSearch() {
        let subject = createSubject()
        setupSiteVisits()
        subject.isSearchInProgress = true

        fetchSearchHistory(from: subject, searchTerm: "ui") { hasResults in
            XCTAssertTrue(subject.shouldShowEmptyState(searchText: "ui"))
        }
    }

    func testShouldShowEmptyState_ForNoHistory() {
        let subject = createSubject()
        subject.isSearchInProgress = false

        fetchHistory(from: subject) { _ in
            XCTAssertTrue(subject.shouldShowEmptyState())
        }
    }

    func testCollapseSection() {
        let subject = createSubject()
        setupSiteVisits()
        XCTAssertTrue(subject.hiddenSections.isEmpty)

        fetchHistory(from: subject) { _ in
            subject.collapseSection(sectionIndex: 1)
            XCTAssertEqual(subject.hiddenSections.count, 1)
            // Starts at 0, removing the Additional section
            XCTAssertTrue(subject.isSectionCollapsed(sectionIndex: 0))
            XCTAssertTrue(subject.hiddenSections.contains(where: { $0 == .lastHour }))
        }
    }

    func testExpandSection() {
        let subject = createSubject()
        setupSiteVisits()
        XCTAssertTrue(subject.hiddenSections.isEmpty)

        fetchHistory(from: subject) { _ in
            subject.collapseSection(sectionIndex: 1)
            XCTAssertEqual(subject.hiddenSections.count, 1)
            // Starts at 0, removing the Additional section
            XCTAssertTrue(subject.isSectionCollapsed(sectionIndex: 0))
            XCTAssertTrue(subject.hiddenSections.contains(where: { $0 == .lastHour }))

            subject.collapseSection(sectionIndex: 1)
            XCTAssertTrue(subject.hiddenSections.isEmpty)
            XCTAssertFalse(subject.isSectionCollapsed(sectionIndex: 1))
        }
    }

    func testRemoveAllData() {
        let subject = createSubject()
        setupSiteVisits()
        XCTAssertTrue(subject.hiddenSections.isEmpty)

        fetchHistory(from: subject) { _ in
            subject.removeAllData()

            XCTAssertEqual(subject.currentFetchOffset, 0)
            XCTAssertTrue(subject.dateGroupedSites.isEmpty)
            XCTAssertTrue(subject.visibleSections.isEmpty)
        }
    }

    // MARK: - Deletion

    func testDeleteGroup_ForLastHour() {
        let subject = createSubject()
        setupSiteVisits()

        fetchHistory(from: subject) { _ in
            XCTAssertEqual(subject.visibleSections[0], .lastHour)
            subject.deleteGroupsFor(dateOption: .lastHour)
            XCTAssertEqual(subject.visibleSections.count, 0)
        }
    }

    // MARK: - Setup
    private func createSubject() -> HistoryPanelViewModel {
        let subject = HistoryPanelViewModel(profile: profile)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func setupSiteVisits() {
        addSiteVisit(profile, url: "http://mozilla.org/", title: "Mozilla internet")
        addSiteVisit(profile, url: "http://mozilla.dev.org/", title: "Internet dev")
        addSiteVisit(profile, url: "https://apple.com/", title: "Apple")
    }

    private func addSiteVisit(_ profile: MockProfile,
                              url: String,
                              title: String,
                              file: StaticString = #filePath,
                              line: UInt = #line) {
        let visitObservation = VisitObservation(url: url, title: title, visitType: .link)
        let result = profile.places.applyObservation(visitObservation: visitObservation)

        XCTAssertEqual(true, result.value.isSuccess, "Site added: \(url).", file: file, line: line)
    }

    private func clear(profile: MockProfile,
                       file: StaticString = #filePath,
                       line: UInt = #line) {
        let result = profile.places.deleteEverythingHistory()
        XCTAssertTrue(result.value.isSuccess, "History cleared.", file: file, line: line)
    }

    private func fetchHistory(from subject: HistoryPanelViewModel,
                              file: StaticString = #filePath,
                              line: UInt = #line,
                              completion: @escaping @Sendable (Bool) -> Void) {
        let expectation = self.expectation(description: "Wait for history")

        subject.reloadData { success in
            XCTAssertNotNil(success, file: file, line: line)
            completion(success)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    private func fetchSearchHistory(from subject: HistoryPanelViewModel,
                                    searchTerm: String,
                                    file: StaticString = #filePath,
                                    line: UInt = #line,
                                    completion: @escaping @Sendable (Bool) -> Void) {
        let expectation = self.expectation(description: "Wait for history search")

        subject.performSearch(term: searchTerm) { hasResults in
            XCTAssertNotNil(hasResults, file: file, line: line)
            completion(hasResults)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    private func createSearchTermGroup(timestamp: MicrosecondTimestamp,
                                       file: StaticString = #filePath,
                                       line: UInt = #line) -> ASGroup<Site> {
        var groupSites = [Site]()
        for index in 0...3 {
            var site = Site.createBasicSite(url: "http://site\(index).com", title: "Site \(index)")
            site.latestVisit = Visit(date: timestamp)
            let visit = VisitObservation(
                url: site.url,
                title: site.title,
                visitType: .link,
                at: Int64(timestamp) / 1000
            )
            XCTAssertTrue(
                profile.places.applyObservation(visitObservation: visit).value.isSuccess,
                "Site added: \(site.url).",
                file: file,
                line: line
            )
            groupSites.append(site)
        }

        return ASGroup<Site>(searchTerm: "site", groupedItems: groupSites, timestamp: timestamp)
    }
}
