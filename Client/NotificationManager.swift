// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UserNotifications

class NotificationManager {
    private var center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = UNUserNotificationCenter.current()) {
        self.center = center
    }

    // Requests the user’s authorization to allow local and remote notifications and sends Telemetry
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            completion(granted, error)

            let extras = [TelemetryWrapper.EventExtraKey.notificationPermissionIsGranted.rawValue:
                            granted]
            TelemetryWrapper.recordEvent(category: .prompt,
                                         method: .tap,
                                         object: .notificationPermission,
                                         extras: extras)
        }
    }

    // Retrieves the authorization and feature-related notification settings and sends Telemetry
    func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        center.getNotificationSettings { settings in
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

            completion(settings)
        }
    }

    // Scheduling push notification based on the Date trigger (Ex 25 December at 10:00PM)
    func schedule(title: String,
                  body: String,
                  id: String,
                  date: Date,
                  repeats: Bool = false) {
        let units: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
        let dateComponents = Calendar.current.dateComponents(units, from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents,
                                                    repeats: repeats)
        schedule(title: title, body: body, id: id, trigger: trigger)
    }

    // Scheduling push notification based on the time interval trigger (Ex 2 sec, 10min)
    func schedule(title: String,
                  body: String,
                  id: String,
                  interval: TimeInterval,
                  repeats: Bool = false) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval,
                                                        repeats: repeats)
        schedule(title: title, body: body, id: id, trigger: trigger)
    }

    // Remove Pending
    func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func removePendingNotificationsWithId(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // Mark: - Private

    // Helper method that takes trigger based on date or time interval
    private func schedule(title: String,
                          body: String,
                          id: String,
                          trigger: UNNotificationTrigger) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = body
        notificationContent.sound = UNNotificationSound.default
        let trigger = trigger
        let request = UNNotificationRequest(identifier: id,
                                            content: notificationContent,
                                            trigger: trigger)
        center.add(request)
    }
}
