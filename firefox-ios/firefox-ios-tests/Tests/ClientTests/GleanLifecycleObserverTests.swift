// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class MockGleanUsageReportingApi: GleanUsageReportingApi {
    var setUsageReasonCalled = false
    var submitPingCalled = false
    var startTrackingDurationCalled = false
    var stopTrackingDurationCalled = false
    var pingSubmitCount = 0
    var lastUsageReason: String?

    func setUsageReason(_ usageReason: UsageReason) {
        setUsageReasonCalled = true
        lastUsageReason = usageReason.rawValue
    }

    func submitPing() {
        submitPingCalled = true
        pingSubmitCount += 1
    }

    func startTrackingDuration() {
        startTrackingDurationCalled = true
    }

    func stopTrackingDuration() {
        stopTrackingDurationCalled = true
    }
}

class MockGleanLifecycleObserver: GleanLifecycleObserver {
    var startObservingCalled = false
    var stopObservingCalled = false
    var handleForegroundEventCalled = false
    var handleBackgroundEventCalled = false

    override func startObserving() {
        startObservingCalled = true
    }

    override func stopObserving() {
        stopObservingCalled = true
    }

    override func handleForegroundEvent() {
        handleForegroundEventCalled = true
    }

    override func handleBackgroundEvent() {
        handleBackgroundEventCalled = true
    }
}

class GleanLifecycleObserverTests: XCTestCase {
    var mockGleanUsageReportingApi: MockGleanUsageReportingApi!
    var gleanLifecycleObserver: GleanLifecycleObserver!
    let notificationCenter = NotificationCenter()

    override func setUp() {
        super.setUp()
        mockGleanUsageReportingApi = MockGleanUsageReportingApi()
        gleanLifecycleObserver = GleanLifecycleObserver(
            gleanUsageReportingApi: mockGleanUsageReportingApi,
            notificationCenter: notificationCenter
        )
    }

    override func tearDown() {
        mockGleanUsageReportingApi = nil
        gleanLifecycleObserver = nil
        super.tearDown()
    }

    func testStartObserving() {
        gleanLifecycleObserver.startObserving()

        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        XCTAssertTrue(
            mockGleanUsageReportingApi.startTrackingDurationCalled,
            "Foreground notification should trigger startTrackingDuration."
        )
        XCTAssertTrue(
            mockGleanUsageReportingApi.setUsageReasonCalled,
            "Foreground notification should trigger setUsageReason."
        )
    }

    func testStopObserving() {
        gleanLifecycleObserver.startObserving()

        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        XCTAssertTrue(
            mockGleanUsageReportingApi.startTrackingDurationCalled,
            "Observer should respond to notifications when observing."
        )

        mockGleanUsageReportingApi.startTrackingDurationCalled = false

        gleanLifecycleObserver.stopObserving()

        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        XCTAssertFalse(
            mockGleanUsageReportingApi.startTrackingDurationCalled,
            "Observer should not respond to notifications after stopObserving is called."
        )
    }

    func testHandleForegroundEvent() {
        gleanLifecycleObserver.handleForegroundEvent()
        XCTAssertTrue(
            mockGleanUsageReportingApi.startTrackingDurationCalled,
            "startTrackingDuration should be called."
        )
        XCTAssertTrue(
            mockGleanUsageReportingApi.setUsageReasonCalled,
            "setUsageReason should be called."
        )
        XCTAssertTrue(
            mockGleanUsageReportingApi.submitPingCalled,
            "submitPing should be called."
        )
    }

    func testHandleBackgroundEvent() {
        gleanLifecycleObserver.handleBackgroundEvent()
        XCTAssertTrue(
            mockGleanUsageReportingApi.stopTrackingDurationCalled,
            "stopTrackingDuration should be called."
        )
        XCTAssertTrue(
            mockGleanUsageReportingApi.setUsageReasonCalled,
            "setUsageReason should be called."
        )
        XCTAssertTrue(
            mockGleanUsageReportingApi.submitPingCalled,
            "submitPing should be called."
        )
    }

    func testNotificationTriggersForegroundEvent() {
        gleanLifecycleObserver.startObserving()
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        XCTAssertTrue(
            mockGleanUsageReportingApi.startTrackingDurationCalled,
            "Foreground notification should trigger startTrackingDuration."
        )
    }

    func testNotificationTriggersBackgroundEvent() {
        gleanLifecycleObserver.startObserving()
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        XCTAssertTrue(
            mockGleanUsageReportingApi.stopTrackingDurationCalled,
            "Background notification should trigger stopTrackingDuration."
        )
    }
}
