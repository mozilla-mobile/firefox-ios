// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UserNotifications

/// Protocol for `UNUserNotificationCenter` methods so we can mock `UNUserNotificationCenter` for unit testing. We do this
/// because the `init` method is marked unavailable for subclasses of the `UNUserNotificationCenter` (can't override it).
protocol UserNotificationCenterProtocol {
    func notificationSettings() async -> UNNotificationSettings
    func requestAuthorization(options: UNAuthorizationOptions,
                              completionHandler: @escaping @Sendable (Bool, Error?) -> Void)
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: (@Sendable (Error?) -> Void)?)
    func getPendingNotificationRequests(completionHandler: @escaping @Sendable ([UNNotificationRequest]) -> Void)
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeAllPendingNotificationRequests()
    func deliveredNotifications() async -> [UNNotification]
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func removeAllDeliveredNotifications()
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol {
}
