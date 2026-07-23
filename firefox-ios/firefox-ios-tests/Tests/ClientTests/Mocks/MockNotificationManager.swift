// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockNotificationManager: NotificationManagerProtocol {
    let wasAuthorizationSuccessful = true
    var requestAuthorizationCalled = false
    var shouldGrantPermission = true
    var errorToReturn: Error?

    func requestAuthorization(completion: @escaping @Sendable (Bool, Error?) -> Void) {
        requestAuthorizationCalled = true
        completion(shouldGrantPermission, errorToReturn)
    }

    func requestAuthorization() async throws -> Bool {
        return wasAuthorizationSuccessful
    }

    func getNotificationSettings(sendTelemetry: Bool) async -> UNNotificationSettings {
        return await NotificationManager().getNotificationSettings()
    }

    var hasPermission = true
    func hasPermission(completion: @escaping @Sendable (Bool) -> Void) {
        completion(hasPermission)
    }

    func hasPermission() async -> Bool {
        return hasPermission
    }

    var scheduledNotifications = 0
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

    func findDeliveredNotificationForId(id: String) async -> UNNotification? {
        return nil
    }
}
