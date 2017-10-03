/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Shared
@testable import SyncTelemetry

class EventTests: XCTestCase {
    func testPickling() {
        let mockTimestamp = Date.now()
        XCTAssertEqual(String(data: basicEvent(timestamp: mockTimestamp).pickle()!, encoding: .utf8),
                       basicEventString(timestamp: mockTimestamp))
        XCTAssertEqual(String(data: basicWithValueEvent(timestamp: mockTimestamp).pickle()!, encoding: .utf8),
                       basicWithValueString(timestamp: mockTimestamp))
        XCTAssertEqual(String(data: extraEvent(timestamp: mockTimestamp).pickle()!, encoding: .utf8),
                       extraEventString(timestamp: mockTimestamp))
    }

    func testUnpickling() {
        let mockTimestamp = Date.now()
        let dataA = basicEventString(timestamp: mockTimestamp).data(using: .utf8)!
        XCTAssertEqual(Event.unpickle(dataA), basicEvent(timestamp: mockTimestamp))

        let dataB = basicWithValueString(timestamp: mockTimestamp).data(using: .utf8)!
        XCTAssertEqual(Event.unpickle(dataB), basicWithValueEvent(timestamp: mockTimestamp))

        let dataC = extraEventString(timestamp: mockTimestamp).data(using: .utf8)!
        XCTAssertEqual(Event.unpickle(dataC), extraEvent(timestamp: mockTimestamp))
    }

    func testIdentifierStringValidation() {
        let identifierA: IdentifierString = "basic"
        XCTAssertTrue(identifierA.validate())

        let identifierB: IdentifierString = "complex1234_more1234"
        XCTAssertTrue(identifierB.validate())

        let identifierC: IdentifierString = "invalid#!"
        XCTAssertFalse(identifierC.validate())

        let identifierD: IdentifierString = "almost_valid."
        XCTAssertFalse(identifierD.validate())
    }

    func testEventValidation() {
        let mockTimestamp = Date.now()
        let eventA = basicEvent(timestamp: mockTimestamp)
        XCTAssertTrue(eventA.validate())

        let eventB = extraEvent(timestamp: mockTimestamp)
        XCTAssertTrue(eventB.validate())

        let eventC = Event(category: "invalid__", method: "valid", object: "valid")
        XCTAssertFalse(eventC.validate())

        let eventD = Event(category: "valid", method: "invalid__", object: "valid")
        XCTAssertFalse(eventD.validate())
    }
}

// Builder methods for easier mocking of the pickled/unpickled events
extension EventTests {
    fileprivate func basicEventString(timestamp: Timestamp) -> String {
        return "[\(timestamp),\"test\",\"pickling\",\"this\",null,null]"
    }

    fileprivate func basicWithValueString(timestamp: Timestamp) -> String {
        return "[\(timestamp),\"test\",\"pickling\",\"this\",\"value\",null]"
    }

    fileprivate func extraEventString(timestamp: Timestamp) -> String {
        return "[\(timestamp),\"test\",\"pickling\",\"this\",\"value\",{\"flowID\":\"testFlowID\",\"numIDs\":\"12\"}]"
    }

    fileprivate func basicEvent(timestamp: Timestamp) -> Event {
        return Event(timestamp: timestamp, category: "test", method: "pickling", object: "this")
    }

    fileprivate func basicWithValueEvent(timestamp: Timestamp) -> Event {
        return Event(timestamp: timestamp, category: "test", method: "pickling", object: "this", value: "value")
    }

    fileprivate func extraEvent(timestamp: Timestamp) -> Event {
        let extra = ["flowID": "testFlowID", "numIDs": "12"]
        return Event(timestamp: timestamp, category: "test", method: "pickling", object: "this", value: "value", extra: extra)
    }
}

// Don't have a need for this in the app but is great for testing!
extension Event: Equatable {
    public static func ==(left: Event, right: Event) -> Bool {
        let propsAreEqual = (left.category == right.category) &&
                            (left.method == right.method) &&
                            (left.object == right.object) &&
                            (left.value ?? "" == right.value ?? "") &&
                            (left.extra ?? [:] == right.extra ?? [:])
        return propsAreEqual
    }
}

