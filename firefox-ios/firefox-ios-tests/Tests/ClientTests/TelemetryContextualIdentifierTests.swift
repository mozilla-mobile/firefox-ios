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
        super.tearDown()
        clearTest()
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
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to puth them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
        TelemetryContextualIdentifier.clearUserDefaults()
    }
}
