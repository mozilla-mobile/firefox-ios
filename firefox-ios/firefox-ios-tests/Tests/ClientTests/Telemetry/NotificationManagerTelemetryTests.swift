// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class NotificationManagerTelemetryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
    }

    func test_onboardingNotificationPermission_GleanIsCalled() {
        let isGranted = true
        let subject = createSubject()

        subject.sendNotificationPermissionPrompt(isPermissionGranted: isGranted)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Onboarding.notificationPermissionPrompt)
    }

    func test_appNotificationPermission_GleanIsCalled() {
        let subject = createSubject()
        let settings = MockUNNotificationSettings(authorizationStatus: .authorized, alertSetting: .enabled)

        subject.sendNotificationPermission(settings: settings)

        testEventMetricRecordingSuccess(metric: GleanMetrics.App.notificationPermission)
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
