// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest

class TelemetryContextualIdentifierTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
        clearTest()
    }

    override func tearDown() async throws {
        clearTest()
        try await super.tearDown()
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

    func testContextId_noGleanMetricsSetsContextId() {
        TelemetryContextualIdentifier.setupContextId(isGleanMetricsAllowed: false)
        XCTAssertNotNil(TelemetryContextualIdentifier.contextId)
    }

    @MainActor
    func testTelemetryWrapper_setsContextId() {
        TelemetryWrapper.shared.setup(profile: MockProfile())
        XCTAssertNotNil(TelemetryContextualIdentifier.contextId)
    }

    // MARK: Helper methods
    func clearTest() {
        TelemetryContextualIdentifier.clearUserDefaults()
    }
}
