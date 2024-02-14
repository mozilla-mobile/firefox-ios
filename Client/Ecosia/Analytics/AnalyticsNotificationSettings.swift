// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UserNotifications

/// A protocol that abstracts the `UNUserNotificationCenter` to allow for dependency injection and mocking.
/// Utilized for integration tests. Specifically `AnalyticsSpyTests`
///
/// By conforming to this protocol, you can replace the notification center with a mock implementation during testing.
protocol AnalyticsUserNotificationCenterProtocol {
    /// Retrieves the notification settings asynchronously.
    ///
    /// - Parameter completionHandler: A closure that is executed with the retrieved `AnalyticsUNNotificationSettingsProtocol` object.
    func getNotificationSettingsProtocol(completionHandler: @escaping (AnalyticsUNNotificationSettingsProtocol) -> Void)
}

/// A protocol that abstracts `UNNotificationSettings`, focusing on the authorization status.
///
/// This protocol allows for mocking the notification settings during testing by providing a custom implementation.
protocol AnalyticsUNNotificationSettingsProtocol {
    /// The authorization status that indicates whether the app is authorized to schedule or receive notifications.
    var authorizationStatus: UNAuthorizationStatus { get }
}

/// Extends `UNNotificationSettings` to conform to `AnalyticsUNNotificationSettingsProtocol`.
///
/// This allows `UNNotificationSettings` instances to be used wherever `AnalyticsUNNotificationSettingsProtocol` is expected.
extension UNNotificationSettings: AnalyticsUNNotificationSettingsProtocol {}

/// A wrapper class for `UNUserNotificationCenter` that conforms to `AnalyticsUserNotificationCenterProtocol`.
///
/// This class provides a concrete implementation of the protocol by forwarding calls to an instance of `UNUserNotificationCenter`.
class AnalyticsUserNotificationCenterWrapper: AnalyticsUserNotificationCenterProtocol {
    /// The underlying `UNUserNotificationCenter` instance.
    private let center: UNUserNotificationCenter

    /// Initializes the wrapper with a specific `UNUserNotificationCenter` instance.
    ///
    /// - Parameter center: The `UNUserNotificationCenter` instance to wrap. Defaults to the current notification center.
    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Retrieves the notification settings asynchronously.
    ///
    /// - Parameter completionHandler: A closure that is executed with the retrieved `AnalyticsUNNotificationSettingsProtocol` object.
    func getNotificationSettingsProtocol(completionHandler: @escaping (AnalyticsUNNotificationSettingsProtocol) -> Void) {
        center.getNotificationSettings { settings in
            completionHandler(settings)
        }
    }
}
