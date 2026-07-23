// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UserNotifications
import Shared

protocol NotificationManagerProtocol {
    func requestAuthorization(completion: @escaping @Sendable (Bool, Error?) -> Void)
    func requestAuthorization() async throws -> Bool
    func getNotificationSettings(sendTelemetry: Bool) async -> UNNotificationSettings
    func hasPermission() async -> Bool
    func schedule(title: String,
                  body: String,
                  id: String,
                  userInfo: [AnyHashable: Any]?,
                  categoryIdentifier: String,
                  interval: TimeInterval,
                  repeats: Bool)
    func findDeliveredNotificationForId(id: String) async -> UNNotification?
}

// TODO: FXIOS-14114 - NotificationManager @unchecked Sendable
final class NotificationManager: NotificationManagerProtocol, @unchecked Sendable {
    private let telemetry: NotificationManagerTelemetry
    private let center: UserNotificationCenterProtocol

    init(center: UserNotificationCenterProtocol = UNUserNotificationCenter.current(),
         telemetry: NotificationManagerTelemetry = NotificationManagerTelemetry()) {
        self.center = center
        self.telemetry = telemetry
    }

    // Requests the user’s authorization to allow local and remote notifications and sends Telemetry
    func requestAuthorization(completion: @escaping @Sendable (Bool, Error?) -> Void) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            completion(granted, error)

            self.telemetry.sendNotificationPermissionPrompt(isPermissionGranted: granted)
        }
    }

    func requestAuthorization() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            requestAuthorization { result in
                continuation.resume(with: result)
            }
        }
    }

    // Retrieves the authorization and feature-related notification settings and sends Telemetry
    func getNotificationSettings(sendTelemetry: Bool = false) async -> UNNotificationSettings {
        let settings = await center.notificationSettings()

        if sendTelemetry {
            telemetry.sendNotificationPermission(settings: settings)
        }

        return settings
    }

    // Determines if the user has allowed notifications
    func hasPermission() async -> Bool {
        let settings = await getNotificationSettings()
        var hasPermission = false
        switch settings.authorizationStatus {
        case .authorized, .ephemeral, .provisional:
            hasPermission = true
        case .notDetermined, .denied:
            fallthrough
        @unknown default:
            hasPermission = false
        }
        return hasPermission
    }

    // Scheduling push notification based on the time interval trigger (Ex 2 sec, 10min)
    func schedule(title: String,
                  body: String,
                  id: String,
                  userInfo: [AnyHashable: Any]? = nil,
                  categoryIdentifier: String = "",
                  interval: TimeInterval,
                  repeats: Bool = false) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval,
                                                        repeats: repeats)
        schedule(title: title,
                 body: body,
                 id: id,
                 userInfo: userInfo,
                 categoryIdentifier: categoryIdentifier,
                 trigger: trigger)
    }

    // Fetches all delivered notifications that are still present in Notification Center by id
    func findDeliveredNotificationForId(id: String) async -> UNNotification? {
        let notificationList: [UNNotification] = await center.deliveredNotifications()
        let notification = notificationList.first(where: { notification -> Bool in
            notification.request.identifier == id
        })
        return notification
    }

    // MARK: - Private

    // Helper method that takes a time interval trigger
    private func schedule(title: String,
                          body: String,
                          id: String,
                          userInfo: [AnyHashable: Any]? = nil,
                          categoryIdentifier: String = "",
                          trigger: UNNotificationTrigger) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = body
        notificationContent.sound = UNNotificationSound.default
        notificationContent.categoryIdentifier = categoryIdentifier

        if let userInfo = userInfo {
            notificationContent.userInfo = userInfo
        }

        let trigger = trigger
        let request = UNNotificationRequest(identifier: id,
                                            content: notificationContent,
                                            trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }
}
