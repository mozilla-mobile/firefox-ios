// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean

struct NotificationManagerTelemetry {
    static func sendTelemetry(settings: NotificationSettingsSnapshot) {
        guard !AppConstants.isRunningUnitTest else { return }

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

        let extras = [TelemetryWrapper.EventExtraKey.notificationPermissionStatus.rawValue: authorizationStatus,
                      TelemetryWrapper.EventExtraKey.notificationPermissionAlertSetting.rawValue: alertSetting]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .notificationPermission,
                                     extras: extras)
    }
}
