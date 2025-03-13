// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UserNotifications
import Shared

protocol NotificationManagerProtocol {
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void)
    func requestAuthorization() async throws -> Bool
    func getNotificationSettings(sendTelemetry: Bool, completion: @escaping (UNNotificationSettings) -> Void)
    func getNotificationSettings(sendTelemetry: Bool) async -> UNNotificationSettings
    func hasPermission(completion: @escaping (Bool) -> Void)
    func hasPermission() async -> Bool
    func schedule(title: String,
                  body: String,
                  id: String,
                  userInfo: [AnyHashable: Any]?,
                  categoryIdentifier: String,
                  date: Date,
                  repeats: Bool)
    func schedule(title: String,
                  body: String,
                  id: String,
                  userInfo: [AnyHashable: Any]?,
                  categoryIdentifier: String,
                  interval: TimeInterval,
                  repeats: Bool)
    func findDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void)
    func findDeliveredNotificationForId(id: String, completion: @escaping (UNNotification?) -> Void)
    func removeAllPendingNotifications()
    func removePendingNotificationsWithId(ids: [String])
}

class NotificationManager: NotificationManagerProtocol {
    private var center: UserNotificationCenterProtocol

    init(center: UserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.center = center
    }

    // Requests the user’s authorization to allow local and remote notifications and sends Telemetry
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            completion(granted, error)

            guard !AppConstants.isRunningUnitTest else { return }

            let extras = [TelemetryWrapper.EventExtraKey.notificationPermissionIsGranted.rawValue:
                            granted]
            TelemetryWrapper.recordEvent(category: .prompt,
                                         method: .tap,
                                         object: .notificationPermission,
                                         extras: extras)
        }
    }

    @available(*, renamed: "requestAuthorization()")
    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void) {
        self.requestAuthorization { granted, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(granted))
            }
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
    func getNotificationSettings(sendTelemetry: Bool = false,
                                 completion: @escaping (UNNotificationSettings) -> Void) {
        center.getNotificationSettings { settings in
            completion(settings)

            guard sendTelemetry else { return }
            self.sendTelemetry(settings: settings)
        }
    }

    func getNotificationSettings(sendTelemetry: Bool = false) async -> UNNotificationSettings {
        return await withCheckedContinuation { continuation in
            getNotificationSettings(sendTelemetry: sendTelemetry) { result in
                continuation.resume(returning: result)
            }
        }
    }

    // Determines if the user has allowed notifications
    func hasPermission(completion: @escaping (Bool) -> Void) {
        getNotificationSettings { settings in
            var hasPermission = false
            switch settings.authorizationStatus {
            case .authorized, .ephemeral, .provisional:
                hasPermission = true
            case .notDetermined, .denied:
                fallthrough
            @unknown default:
                hasPermission = false
            }
            completion(hasPermission)
        }
    }

    // Determines if the user has allowed notifications
    func hasPermission() async -> Bool {
        // NOTE: Testing "unsafe" variant of this method, see FXIOS-10832 for details.
        await withUnsafeContinuation { continuation in
            hasPermission { hasPermission in
                continuation.resume(returning: hasPermission)
            }
        }
    }

    // Scheduling push notification based on the Date trigger (Ex 25 December at 10:00PM)
    func schedule(title: String,
                  body: String,
                  id: String,
                  userInfo: [AnyHashable: Any]? = nil,
                  categoryIdentifier: String = "",
                  date: Date,
                  repeats: Bool = false) {
        let units: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
        let dateComponents = Calendar.current.dateComponents(units, from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents,
                                                    repeats: repeats)
        schedule(title: title,
                 body: body,
                 id: id,
                 userInfo: userInfo,
                 categoryIdentifier: categoryIdentifier,
                 trigger: trigger)
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

    // Fetches all delivered notifications that are still present in Notification Center.
    func findDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void) {
        center.getDeliveredNotifications { notificationList in
            completion(notificationList)
        }
    }

    // Fetches all delivered notifications that are still present in Notification Center by id
    func findDeliveredNotificationForId(id: String,
                                        completion: @escaping (UNNotification?) -> Void) {
        findDeliveredNotifications { notificationList in
            let notification = notificationList.first(where: { notification -> Bool in
                notification.request.identifier == id
            })
            completion(notification)
        }
    }

    // Remove all pending notifications
    func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // Remove pending notifications with id
    func removePendingNotificationsWithId(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Private

    // Helper method that takes trigger based on date or time interval
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

    private func sendTelemetry(settings: UNNotificationSettings) {
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
