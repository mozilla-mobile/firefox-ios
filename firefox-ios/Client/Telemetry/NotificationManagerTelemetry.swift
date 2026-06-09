// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean

struct NotificationManagerTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func sendNotificationPermission(settings: NotificationSettings) {
        var authorizationStatus = ""
        switch settings.authorizationStatus {
        case .authorized: authorizationStatus = "authorized"
        case .denied: authorizationStatus = "denied"
        case .ephemeral: authorizationStatus = "ephemeral"
        case .provisional: authorizationStatus = "provisional"
        case .notDetermined: authorizationStatus = "notDetermined"
        @unknown default: authorizationStatus = "notDetermined"
        }

        var alertSetting = ""
        switch settings.alertSetting {
        case .enabled: alertSetting = "enabled"
        case .disabled: alertSetting = "disabled"
        case .notSupported: alertSetting = "notSupported"
        @unknown default: alertSetting = "notSupported"
        }

        let permissionExtra = GleanMetrics.App.NotificationPermissionExtra(
            alertSetting: alertSetting,
            status: authorizationStatus
        )
        gleanWrapper.recordEvent(for: GleanMetrics.App.notificationPermission,
                                 extras: permissionExtra)
    }

    func sendNotificationPermissionPrompt(isPermissionGranted: Bool, onboardingReason: OnboardingReason = .newUser) {
        let permissionExtra = GleanMetrics.Onboarding.NotificationPermissionPromptExtra(
            granted: isPermissionGranted,
            onboardingReason: onboardingReason.rawValue
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.notificationPermissionPrompt,
                                 extras: permissionExtra)
    }
}

protocol NotificationSettings {
    var authorizationStatus: UNAuthorizationStatus { get }
    var alertSetting: UNNotificationSetting { get }
}

extension UNNotificationSettings: NotificationSettings {}
