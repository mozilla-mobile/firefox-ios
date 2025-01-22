// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class GleanUsageReportingLifecycleObserverTest: XCTestCase {
    private var fakeGleanUsageReportingApi: MockGleanUsageReportingApi!

    override func setUp() {
        super.setUp()
        fakeGleanUsageReportingApi = MockGleanUsageReportingApi()
    }

    func testNoPingsSubmittedBeforeLifecycleChanges() {
        _ = createObserver()
        XCTAssertEqual(fakeGleanUsageReportingApi.pingSubmitCount, 0)
    }

    func testNoUsageReasonSetBeforeLifecycleChanges() {
        _ = createObserver()
        XCTAssertNil(fakeGleanUsageReportingApi.lastUsageReason)
    }

    func testSetUsageReasonToActiveOnStart() {
        let observer = createObserver()
        observer.handleForegroundEvent()
        XCTAssertEqual(fakeGleanUsageReportingApi.lastUsageReason, "active")
    }

    func testSubmitPingOnStart() {
        let observer = createObserver()
        observer.handleForegroundEvent()
        XCTAssertEqual(fakeGleanUsageReportingApi.pingSubmitCount, 1)
    }

    func testSetUsageReasonToInactiveOnStop() {
        let observer = createObserver()
        observer.handleBackgroundEvent()
        XCTAssertEqual(fakeGleanUsageReportingApi.lastUsageReason, "inactive")
    }

    func testSubmitPingOnStop() {
        let observer = createObserver()
        observer.handleForegroundEvent()
        observer.handleBackgroundEvent()
        XCTAssertEqual(fakeGleanUsageReportingApi.pingSubmitCount, 2)
    }

    private func createObserver() -> GleanLifecycleObserver {
        return GleanLifecycleObserver(
            gleanUsageReportingApi: fakeGleanUsageReportingApi
        )
    }
}
