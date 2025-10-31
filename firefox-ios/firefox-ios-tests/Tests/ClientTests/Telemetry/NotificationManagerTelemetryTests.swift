// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class NotificationManagerTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!
    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }
    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func test_onboardingNotificationPermission_GleanIsCalled() throws {
        let event = GleanMetrics.Onboarding.notificationPermissionPrompt
        typealias EventExtrasType = GleanMetrics.Onboarding.NotificationPermissionPromptExtra
        let isGranted = true
        let subject = createSubject()
        subject.sendNotificationPermissionPrompt(isPermissionGranted: isGranted)
        let savedEvent = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? EventExtrasType
        )
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
        XCTAssertEqual(savedExtras.granted, true)
    }
    func test_appNotificationPermission_GleanIsCalled() throws {
        let event = GleanMetrics.App.notificationPermission
        typealias EventExtrasType = GleanMetrics.App.NotificationPermissionExtra
        let subject = createSubject()
        let settings = MockUNNotificationSettings(authorizationStatus: .authorized, alertSetting: .enabled)
        subject.sendNotificationPermission(settings: settings)
        let savedEvent = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? EventExtrasType
        )
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.alertSetting, "enabled")
        XCTAssertEqual(savedExtras.status, "authorized")
        XCTAssert(savedEvent === event, "Received \(savedEvent) instead of \(event)")
    }

    func createSubject() -> NotificationManagerTelemetry {
        return NotificationManagerTelemetry(gleanWrapper: mockGleanWrapper)
    }
}

class MockUNNotificationSettings: NotificationSettings {
    var authorizationStatus: UNAuthorizationStatus
    var alertSetting: UNNotificationSetting
    init(authorizationStatus: UNAuthorizationStatus, alertSetting: UNNotificationSetting) {
        self.authorizationStatus = authorizationStatus
        self.alertSetting = alertSetting
    }
}
