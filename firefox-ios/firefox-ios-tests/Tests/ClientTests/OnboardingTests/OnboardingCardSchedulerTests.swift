// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class OnboardingCardSchedulerTests: XCTestCase {
    private var prefs: MockProfilePrefs!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
    }

    override func tearDown() {
        prefs = nil
        super.tearDown()
    }

    // MARK: - currentActiveDay

    func testCurrentActiveDay_whenNothingStored_defaultsToZero() {
        let subject = createSubject()

        XCTAssertEqual(subject.currentActiveDay, 0)
    }

    // MARK: - recordActiveDayIfNeeded

    func testRecordActiveDayIfNeeded_firstCall_incrementsToOne() {
        let subject = createSubject(date: { self.makeDate(year: 2026, month: 1, day: 1) })
        subject.recordActiveDayIfNeeded()
        XCTAssertEqual(subject.currentActiveDay, 1)
    }

    func testRecordActiveDayIfNeeded_sameCalendarDay_doesNotIncrement() {
        let subject = createSubject(date: { self.makeDate(year: 2026, month: 1, day: 1) })
        subject.recordActiveDayIfNeeded()
        subject.recordActiveDayIfNeeded()
        XCTAssertEqual(subject.currentActiveDay, 1)
    }

    func testRecordActiveDayIfNeeded_newCalendarDay_increments() {
        var now = makeDate(year: 2026, month: 1, day: 1)
        let subject = createSubject(date: { now })

        subject.recordActiveDayIfNeeded()
        now = makeDate(year: 2026, month: 1, day: 2)
        subject.recordActiveDayIfNeeded()

        XCTAssertEqual(subject.currentActiveDay, 2)
    }

    func testRecordActiveDayIfNeeded_persistsCountAndDate() {
        let subject = createSubject(date: { self.makeDate(year: 2026, month: 1, day: 3) })
        subject.recordActiveDayIfNeeded()

        XCTAssertEqual(prefs.intForKey(PrefsKeys.onboardingActiveDayCount), 1)
        XCTAssertEqual(prefs.intForKey(PrefsKeys.onboardingLastActiveDate), 2026_01_03)
    }

    // MARK: - consumeDueCards

    func testConsumeDueCards_whenNothingScheduledForDay_returnsEmpty() {
        let subject = createSubject(schedule: [1: [makeCard(title: "Day 1")]])

        // currentActiveDay is still 0, which has no scheduled cards.
        XCTAssertTrue(subject.consumeDueCards().isEmpty)
    }

    func testConsumeDueCards_returnsScheduledCardsForCurrentDay() {
        let schedule = [
            1: [makeCard(title: "Day 1 - A"), makeCard(title: "Day 1 - B")]
        ]
        let subject = createSubject(schedule: schedule,
                                    date: { self.makeDate(year: 2026, month: 1, day: 1) })
        subject.recordActiveDayIfNeeded()

        let cards = subject.consumeDueCards()

        XCTAssertEqual(cards.map { $0.title }, ["Day 1 - A", "Day 1 - B"])
    }

    func testConsumeDueCards_calledTwice_returnsEmptySecondTime() {
        let subject = createSubject(schedule: [1: [makeCard(title: "Day 1")]],
                                    date: { self.makeDate(year: 2026, month: 1, day: 1) })
        subject.recordActiveDayIfNeeded()

        XCTAssertFalse(subject.consumeDueCards().isEmpty)
        XCTAssertTrue(subject.consumeDueCards().isEmpty)
    }

    func testConsumeDueCards_marksLastCardActiveDay() {
        let subject = createSubject(schedule: [1: [makeCard(title: "Day 1")]],
                                    date: { self.makeDate(year: 2026, month: 1, day: 1) })
        subject.recordActiveDayIfNeeded()

        _ = subject.consumeDueCards()

        XCTAssertEqual(prefs.intForKey(PrefsKeys.onboardingLastCardActiveDay), 1)
    }

    // MARK: - Helpers

    private func createSubject(
        schedule: [Int: [OnboardingCard]] = [:],
        date: @escaping () -> Date = { Date() }
    ) -> OnboardingCardScheduler {
        return OnboardingCardScheduler(prefs: prefs, schedule: schedule, dateProvider: date)
    }

    private func makeCard(title: String) -> OnboardingCard {
        return OnboardingCard(title: title, body: "body")
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components)!
    }
}
