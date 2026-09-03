// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class TrackerBlockerSheetStateProviderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_770_000_000)

    func test_sheetState_withNothingEverBlocked_isEmptyState() {
        let store = MockTrackerBlockStatsStore()

        let state = createSubject(store: store).sheetState()

        XCTAssertTrue(state.isEmpty)
        XCTAssertEqual(state.presentation, .empty)
        XCTAssertNil(state.weeklyCount)
        XCTAssertNil(state.total)
        XCTAssertEqual(state.lifetimeTotal, 0)
        XCTAssertEqual(state.categories.count, TrackerBlockerSheetState.Category.Kind.allCases.count)
        XCTAssertTrue(state.categories.allSatisfy { $0.count == nil })
    }

    func test_sheetState_withBlockedTrackers_usesTheCurrentWeekCounts() {
        let store = MockTrackerBlockStatsStore()
        store.lifetimeTotalToReturn = 4321
        store.currentWeekTotalToReturn = 210
        store.currentWeekByCategoryToReturn = [
            .advertising: 100,
            .fingerprinting: 60,
            .analytics: 40,
            .social: 10
        ]

        let state = createSubject(store: store).sheetState()

        XCTAssertFalse(state.isEmpty)
        XCTAssertEqual(state.presentation, .filled)
        XCTAssertEqual(state.weeklyCount, 210)
        XCTAssertEqual(state.lifetimeTotal, 4321)
        XCTAssertNil(state.emptyMessage)
        XCTAssertEqual(counts(in: state), [100, 60, 40, 10])
    }

    /// The state carries the lifetime total so callers don't have to read and decode it from prefs again.
    func test_sheetState_readsTheLifetimeTotalOnce() {
        let store = MockTrackerBlockStatsStore()
        store.lifetimeTotalToReturn = 4321

        _ = createSubject(store: store).sheetState()

        XCTAssertEqual(store.lifetimeTotalCallCount, 1)
    }

    /// The rows are in the sheet's fixed display order, each counting the blocklist category the enhanced
    /// tracking protection panel shows it for.
    func test_sheetState_mapsEachRowToItsBlocklistCategory() {
        let store = MockTrackerBlockStatsStore()
        store.lifetimeTotalToReturn = 10
        store.currentWeekByCategoryToReturn = [.advertising: 1, .fingerprinting: 2, .analytics: 3, .social: 4]

        let state = createSubject(store: store).sheetState()

        XCTAssertEqual(state.categories.map { $0.kind },
                       [.crossSiteTrackingCookies, .fingerprinters, .trackingContent, .socialMediaTrackers])
        XCTAssertEqual(counts(in: state), [1, 2, 3, 4])
    }

    func test_sheetState_withCategoryMissingFromTheWeek_countsItAsZero() {
        let store = MockTrackerBlockStatsStore()
        store.lifetimeTotalToReturn = 10
        store.currentWeekByCategoryToReturn = [.advertising: 10]

        let state = createSubject(store: store).sheetState()

        XCTAssertEqual(counts(in: state), [10, 0, 0, 0])
    }

    func test_sheetState_readsTheCurrentWeekForTheProvidedDate() {
        let store = MockTrackerBlockStatsStore()
        store.lifetimeTotalToReturn = 10

        _ = createSubject(store: store).sheetState()

        XCTAssertEqual(store.currentWeekTotalDates, [now])
        XCTAssertEqual(store.currentWeekByCategoryDates, [now])
    }

    /// The week can roll over while the lifetime total stays: the bars empty out but the footer remains.
    func test_sheetState_withNothingBlockedThisWeek_keepsTheLifetimeTotal() {
        let store = MockTrackerBlockStatsStore()
        store.lifetimeTotalToReturn = 5305
        store.currentWeekTotalToReturn = 0
        store.currentWeekByCategoryToReturn = [:]

        let state = createSubject(store: store).sheetState()

        XCTAssertFalse(state.isEmpty)
        XCTAssertEqual(state.presentation, .weeklyReset)
        XCTAssertEqual(state.weeklyCount, 0)
        XCTAssertEqual(state.total?.count, 5305)
        XCTAssertEqual(counts(in: state), [0, 0, 0, 0])
    }

    func test_sheetState_footerCountsFromTheTrackingStartDate() throws {
        let startDate = Date(timeIntervalSince1970: 1_760_000_000)
        let store = MockTrackerBlockStatsStore()
        store.lifetimeTotalToReturn = 43251
        store.trackingStartDateToReturn = startDate

        let total = try XCTUnwrap(createSubject(store: store).sheetState().total)

        XCTAssertEqual(total.count, 43251)
        XCTAssertEqual(total.sinceDate, startDate.formatted(date: .numeric, time: .omitted))
    }

    /// The footer copy needs a date to count from, so it is dropped rather than shown without one.
    func test_sheetState_withoutATrackingStartDate_hasNoFooterTotal() {
        let store = MockTrackerBlockStatsStore()
        store.lifetimeTotalToReturn = 43251
        store.currentWeekTotalToReturn = 12
        store.trackingStartDateToReturn = nil

        let state = createSubject(store: store).sheetState()

        XCTAssertNil(state.total)
        XCTAssertEqual(state.weeklyCount, 12)
        XCTAssertEqual(state.lifetimeTotal, 43251, "The total is still known, it just has no footer to appear in")
    }

    // MARK: - Helpers

    private func counts(in state: TrackerBlockerSheetState) -> [Int?] {
        return state.categories.map { $0.count }
    }

    private func createSubject(store: MockTrackerBlockStatsStore) -> TrackerBlockerSheetStateProvider {
        return TrackerBlockerSheetStateProvider(statsStore: store, dateProvider: MockDateProvider(fixedDate: now))
    }
}

private final class MockTrackerBlockStatsStore: TrackerBlockStatsStore {
    var lifetimeTotalToReturn = 0
    var currentWeekTotalToReturn = 0
    var currentWeekByCategoryToReturn = [BlocklistCategory: Int]()
    var trackingStartDateToReturn: Date? = Date(timeIntervalSince1970: 1_760_000_000)
    var highestReportedFiguresToReturn = 0

    var currentWeekTotalDates = [Date]()
    var currentWeekByCategoryDates = [Date]()
    var lifetimeTotalCallCount = 0

    func record(category: BlocklistCategory, count: Int, date: Date) {}

    func lifetimeTotal() -> Int {
        lifetimeTotalCallCount += 1
        return lifetimeTotalToReturn
    }

    func lifetimeByCategory() -> [BlocklistCategory: Int] { return [:] }

    func currentWeekTotal(for date: Date) -> Int {
        currentWeekTotalDates.append(date)
        return currentWeekTotalToReturn
    }

    func currentWeekByCategory(for date: Date) -> [BlocklistCategory: Int] {
        currentWeekByCategoryDates.append(date)
        return currentWeekByCategoryToReturn
    }

    func trackingStartDate() -> Date? { return trackingStartDateToReturn }
    func reset() {}
    func highestReportedFigures() -> Int { return highestReportedFiguresToReturn }
    func setHighestReportedFigures(_ figures: Int) { highestReportedFiguresToReturn = figures }
}
