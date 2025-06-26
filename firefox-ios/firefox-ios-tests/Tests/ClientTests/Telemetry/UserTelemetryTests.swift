// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class UserTelemetryTests: XCTestCase {
    let mockFirefoxAccountId = "8a583618afa8468684cac629d899e0af" // FxA uses uuid v4 format
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()

        mockGleanWrapper = MockGleanWrapper()
    }

    func testSetFirefoxAccountID_recordsData() throws {
        let expectedMetricType = type(of: GleanMetrics.UserClientAssociation.uid)
        let expectedValue = mockFirefoxAccountId

        let subject = createSubject()
        subject.setFirefoxAccountID(uid: expectedValue)

        let savedValue = try XCTUnwrap(
            mockGleanWrapper.savedValues.first as? String
        )
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? StringMetricType
        )
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordStringCalled, 1)
        XCTAssertEqual(savedValue, expectedValue)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func createSubject() -> UserTelemetry {
        return UserTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
