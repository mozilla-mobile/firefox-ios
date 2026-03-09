/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import MozillaRustComponents
@testable import MozillaAppServices
import XCTest

final class EventStoreTests: XCTestCase {
    var nimbus: NimbusInterface!

    var events: NimbusEventStore {
        nimbus
    }

    let eventId = "app_launched"
    let oneDay: TimeInterval = 24.0 * 60 * 60

    override func setUpWithError() throws {
        nimbus = try createNimbus()
    }

    func createDatabasePath() -> String {
        // For whatever reason, we cannot send a file:// because it'll fail
        // to make the DB both locally and on CI, so we just send the path
        let directory = NSTemporaryDirectory()
        let filename = "testdb-\(UUID().uuidString).db"
        let dbPath = directory + filename
        return dbPath
    }

    func createNimbus() throws -> NimbusInterface {
        let appSettings = NimbusAppSettings(appName: "EventStoreTest", channel: "nightly")
        let nimbusEnabled = try Nimbus.create(server: nil, appSettings: appSettings, dbPath: createDatabasePath())
        XCTAssert(nimbusEnabled is Nimbus)
        if let nimbus = nimbusEnabled as? Nimbus {
            try nimbus.initializeOnThisThread()
        }
        return nimbusEnabled
    }

    func testRecordPastEvent() throws {
        let helper = try nimbus.createMessageHelper()

        try events.recordPastEvent(1, eventId, oneDay)

        XCTAssertTrue(
            try helper.evalJexl(expression: "'\(eventId)'|eventLastSeen('Days') == 1")
        )
        XCTAssertTrue(
            try helper.evalJexl(expression: "'\(eventId)'|eventLastSeen('Hours') == 24")
        )
    }

    func testAdvancingTimeIntoTheFuture() throws {
        let helper = try nimbus.createMessageHelper()
        events.recordEvent(eventId)

        XCTAssertTrue(
            try helper.evalJexl(expression: "'\(eventId)'|eventLastSeen('Days') == 0")
        )

        try events.advanceEventTime(by: oneDay)

        XCTAssertTrue(
            try helper.evalJexl(expression: "'\(eventId)'|eventLastSeen('Days') == 1")
        )
        XCTAssertTrue(
            try helper.evalJexl(expression: "'\(eventId)'|eventLastSeen('Hours') == 24")
        )

        try events.advanceEventTime(by: oneDay)
        XCTAssertTrue(
            try helper.evalJexl(expression: "'\(eventId)'|eventLastSeen('Days') == 2")
        )
        XCTAssertTrue(
            try helper.evalJexl(expression: "'\(eventId)'|eventLastSeen('Hours') == 48")
        )
    }

    func testEventLastSeenRegression() async throws {
        let jexl = try nimbus.createMessageHelper()
        nimbus.events.recordEvent(eventId)
        _ = try jexl.evalJexl(expression: "'\(eventId)'|eventLastSeen('Minutes', 1) == 1")
    }
}
