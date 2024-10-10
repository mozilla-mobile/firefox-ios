// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest

class TelemetryContextualIdentifierTests: XCTestCase {
    override func setUp() {
        super.setUp()
        clearTest()
    }

    override func tearDown() {
        clearTest()
        super.tearDown()
    }

    // MARK: Context id

    func testContextId_isNilByDefault() {
        XCTAssertNil(TelemetryContextualIdentifier.contextId)
    }

    func testContextId_isCreated() {
        TelemetryContextualIdentifier.setupContextId()
        XCTAssertNotNil(TelemetryContextualIdentifier.contextId)
    }

    func testContextId_isReusedAfterCreation() {
        TelemetryContextualIdentifier.setupContextId()
        let contextId = TelemetryContextualIdentifier.contextId
        TelemetryContextualIdentifier.setupContextId()
        XCTAssertEqual(contextId, TelemetryContextualIdentifier.contextId)
    }

    func testTelemetryWrapper_setsContextId() {
        TelemetryWrapper.shared.setup(profile: MockProfile())
        XCTAssertNotNil(TelemetryContextualIdentifier.contextId)
    }

    // MARK: Helper methods
    func clearTest() {
        Glean.shared.resetGlean(clearStores: true)
        TelemetryContextualIdentifier.clearUserDefaults()
    }
}
