// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import Glean

@testable import Client

class ContextIDRotationHandlerTests: XCTestCase {
    let mockGlean = MockGleanWrapper()
    let uuidString = UUID().uuidString

    func testPersist_setsGleanWrapperUUID() {
        let contextIDRotationHandler = ContextIDRotationHandler(isGleanMetricsAllowed: true, gleanWrapper: mockGlean)

        contextIDRotationHandler.persist(contextId: uuidString, creationDate: 12345)
        XCTAssertTrue(mockGlean.setUUIDWasCalled)
    }

    func testRotated_configuresPingOnGleanWrapper() throws {
        let contextIDRotationHandler = ContextIDRotationHandler(isGleanMetricsAllowed: true, gleanWrapper: mockGlean)
        contextIDRotationHandler.rotated(oldContextId: uuidString)
        XCTAssertTrue(mockGlean.setPingBooleanWasCalled)
        XCTAssertEqual(mockGlean.valueSetToPing, true)
    }
}
