// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class WorldCupCountdownModelTests: XCTestCase {
    private let mockPrefs = MockProfilePrefs()

    override func setUp() {
        super.setUp()
        FxNimbus.shared.features.worldCupWidgetFeature.with { _, _ in
            return WorldCupWidgetFeature(countdownTargetDate: "2026-06-11T19:00:00Z")
        }
    }

    // All "now" dates are expressed in UTC to reason clearly against the 19:00 UTC kickoff.
    private func utcDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var c = DateComponents()
        c.timeZone = TimeZone(identifier: "UTC")
        c.year = year; c.month = month; c.day = day
        c.hour = hour; c.minute = minute; c.second = 0
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    func testCountdownBeforeKickoff() {
        // 2026-06-01T19:00:00Z — exactly 10 days before kickoff
        let now = utcDate(year: 2026, month: 6, day: 1, hour: 19)
        let model = WorldCupCountdownModel(prefs: mockPrefs, now: { now })
        let cd = model.currentCountdown
        XCTAssertEqual(cd.days, 10)
        XCTAssertEqual(cd.hours, 0)
        XCTAssertEqual(cd.minutes, 0)
    }

    func testCountdownSameDayBeforeKickoff() {
        // 2026-06-11T09:30:00Z — same day, 9h30m before the 19:00 kickoff
        let now = utcDate(year: 2026, month: 6, day: 11, hour: 9, minute: 30)
        let model = WorldCupCountdownModel(prefs: mockPrefs, now: { now })
        let cd = model.currentCountdown
        XCTAssertEqual(cd.days, 0)
        XCTAssertEqual(cd.hours, 9)
        XCTAssertEqual(cd.minutes, 30)
    }

    func testCountdownAfterKickoffClampsToZero() {
        // 2026-06-11T20:00:00Z — one hour after kickoff
        let now = utcDate(year: 2026, month: 6, day: 11, hour: 20)
        let model = WorldCupCountdownModel(prefs: mockPrefs, now: { now })
        let cd = model.currentCountdown
        XCTAssertEqual(cd.days, 0)
        XCTAssertEqual(cd.hours, 0)
        XCTAssertEqual(cd.minutes, 0)
    }

    func testCountdownWithCustomNimbusTargetDate() {
        // Override Nimbus to use a different target date
        FxNimbus.shared.features.worldCupWidgetFeature.with { _, _ in
            return WorldCupWidgetFeature(countdownTargetDate: "2026-07-01T12:00:00Z")
        }
        let now = utcDate(year: 2026, month: 6, day: 30, hour: 12)
        let model = WorldCupCountdownModel(prefs: mockPrefs, now: { now })
        let cd = model.currentCountdown
        XCTAssertEqual(cd.days, 1)
        XCTAssertEqual(cd.hours, 0)
        XCTAssertEqual(cd.minutes, 0)
    }

    func testCallbackFiredOnStart() {
        let now = utcDate(year: 2026, month: 5, day: 1)
        let model = WorldCupCountdownModel(prefs: mockPrefs, now: { now })
        var received: WorldCupCountdown?
        model.onCountdownUpdated = { received = $0 }
        model.start()
        XCTAssertNotNil(received)
        XCTAssertGreaterThan(received!.days, 0)
        model.stop()
    }

    func testStopPreventsSubsequentFires() {
        let now = utcDate(year: 2026, month: 5, day: 1)
        let model = WorldCupCountdownModel(prefs: mockPrefs, now: { now })
        var fireCount = 0
        model.onCountdownUpdated = { _ in fireCount += 1 }
        model.start()   // fires immediately → fireCount == 1
        model.stop()
        XCTAssertEqual(fireCount, 1)
    }
}
