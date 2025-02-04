// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class HomepageTelemetryTests: XCTestCase {
    func testPrivateModeShortcutToggleTappedInNormalMode() throws {
        let mockWrapper = MockGleanWrapper()
        let subject = HomepageTelemetry(gleanWrapper: mockWrapper)

        subject.sendHomepageTappedTelemetry(enteringPrivateMode: true)

        XCTAssertEqual(mockWrapper.recordEventCalled, 1)

        let savedEvent = try XCTUnwrap(mockWrapper.savedEvent as? GleanEvent)
        XCTAssertEqual(savedEvent.extra?["is_private_mode"], "true")
    }

    func testPrivateModeShortcutToggleTappedInPrivateMode() throws {
        let mockWrapper = MockGleanWrapper() // Use the existing MockGleanWrapper
        let subject = HomepageTelemetry(gleanWrapper: mockWrapper)

        subject.sendHomepageTappedTelemetry(enteringPrivateMode: false)

        XCTAssertEqual(mockWrapper.recordEventCalled, 1)

        let savedEvent = try XCTUnwrap(mockWrapper.savedEvent as? GleanEvent)
        XCTAssertEqual(savedEvent.extra?["is_private_mode"], "false")
    }

    func testGleanWrapperIntegration() throws {
        let mockWrapper = MockGleanWrapper()
        let subject = HomepageTelemetry(gleanWrapper: mockWrapper)

        // Test recording with enteringPrivateMode = true
        subject.sendHomepageTappedTelemetry(enteringPrivateMode: true)
        XCTAssertEqual(mockWrapper.recordEventCalled, 1)

        // Test recording with enteringPrivateMode = false
        subject.sendHomepageTappedTelemetry(enteringPrivateMode: false)
        XCTAssertEqual(mockWrapper.recordEventCalled, 2)

        // Verify that the event was recorded
        XCTAssertNotNil(mockWrapper.savedEvent)
    }
}

class GleanEvent {
    let extra: [String: String]?

    init(extra: [String: String]?) {
        self.extra = extra
    }
}
