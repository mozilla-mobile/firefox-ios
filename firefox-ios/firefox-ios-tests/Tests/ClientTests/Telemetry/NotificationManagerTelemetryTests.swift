// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

// TODO: FXIOS-13744 - Migrate NotificationManagerTelemetryTests to use mock telemetry or GleanWrapper
final class NotificationManagerTelemetryTests: XCTestCase {
    func test_onboardingNotificationPermission_GleanIsCalled() throws {
        let isGranted = true
        let subject = createSubject()

        subject.sendNotificationPermissionPrompt(isPermissionGranted: isGranted)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.notificationPermissionPrompt)
    }

    func test_appNotificationPermission_GleanIsCalled() throws {
        let subject = createSubject()
        let settings = MockUNNotificationSettings(authorizationStatus: .authorized, alertSetting: .enabled)

        subject.sendNotificationPermission(settings: settings)

        try testEventMetricRecordingSuccess(metric: GleanMetrics.App.notificationPermission)
    }

    func createSubject() -> NotificationManagerTelemetry {
        return NotificationManagerTelemetry()
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
