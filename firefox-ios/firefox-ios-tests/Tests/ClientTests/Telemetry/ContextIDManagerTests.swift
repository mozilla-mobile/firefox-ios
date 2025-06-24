// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import MozillaAppServices
import XCTest

class ContextIDManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        ContextIDManager.setup(isGleanMetricsAllowed: true, isTesting: true, contextIdComponent: nil)
        super.tearDown()
    }

    func testGetContextID_callsContextIDComponentRequest() {
        let mock = MockContextIDComponent()
        ContextIDManager.setup(isGleanMetricsAllowed: true, isTesting: true, contextIdComponent: mock)
        let contextID = ContextIDManager.shared.getContextID()
        XCTAssertEqual(contextID, "testContextID")
        XCTAssertTrue(mock.requestWasCalled)
    }

    func testClearContextIDState_unsetsCallback() {
        let mock = MockContextIDComponent()
        ContextIDManager.setup(isGleanMetricsAllowed: true, isTesting: true, contextIdComponent: mock)
        ContextIDManager.shared.clearContextIDState()
        XCTAssertTrue(mock.unsetCallbackWasCalled)
    }
}

class MockContextIDComponent: ContextIdComponentProtocol {
    var requestWasCalled = false
    var unsetCallbackWasCalled = false

    func forceRotation() throws { }

    func request(rotationDaysInS: UInt8) throws -> String {
        requestWasCalled = true
        return "testContextID"
    }

    func unsetCallback() throws {
        unsetCallbackWasCalled = true
    }
}
