// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockNotificationManager: NotificationManagerProtocol {
    let wasAuthorizationSuccessful = true
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
    }

    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void) {
    }

    func requestAuthorization() async throws -> Bool {
        return wasAuthorizationSuccessful
    }

    func getNotificationSettings(sendTelemetry: Bool, completion: @escaping (UNNotificationSettings) -> Void) {
    }

    func getNotificationSettings(sendTelemetry: Bool) async -> UNNotificationSettings {
        return await NotificationManager().getNotificationSettings()
    }

    var hasPermission = true
    func hasPermission(completion: @escaping (Bool) -> Void) {
        completion(hasPermission)
    }

    func hasPermission() async -> Bool {
        return hasPermission
    }

    var scheduledNotifications = 0
    var scheduleWithDateWasCalled = false
    func schedule(title: String,
                  body: String,
                  id: String,
                  userInfo: [AnyHashable: Any]?,
                  categoryIdentifier: String,
                  date: Date,
                  repeats: Bool) {
        scheduledNotifications += 1
        scheduleWithDateWasCalled = true
    }

    var scheduleWithIntervalWasCalled = false
    func schedule(title: String,
                  body: String,
                  id: String,
                  userInfo: [AnyHashable: Any]?,
                  categoryIdentifier: String,
                  interval: TimeInterval,
                  repeats: Bool) {
        scheduledNotifications += 1
        scheduleWithIntervalWasCalled = true
    }

    func findDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void) {
    }

    func findDeliveredNotificationForId(id: String, completion: @escaping (UNNotification?) -> Void) {
        completion(nil)
    }

    var removeAllPendingNotificationsWasCalled = false
    func removeAllPendingNotifications() {
        removeAllPendingNotificationsWasCalled = true
        scheduledNotifications = 0
    }

    var removePendingNotificationsWithIdWasCalled = false
    func removePendingNotificationsWithId(ids: [String]) {
        scheduledNotifications -= 1
        removePendingNotificationsWithIdWasCalled = true
    }
}
