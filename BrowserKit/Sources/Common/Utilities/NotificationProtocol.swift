// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol NotificationProtocol: Sendable {
    /// Posts a notification with an optional object and/or userInfo dictionary.
    nonisolated func post(name: NSNotification.Name, withObject: Any?, withUserInfo: [AnyHashable: Any]?)

    /// Adds an observer.
    /// **NOTE**: Do not call this method directly. Use the `Notifiable` helper method `startObservingNotifications` instead.
    ///
    /// Our `Notifiable` protocol relies on this method to provide default implementations.
    nonisolated func addObserver(
        _ observer: Any,
        selector aSelector: Selector,
        name aName: NSNotification.Name?,
        object anObject: Any?
    )

    /// Removes an observer.
    /// **NOTE**: Do not call this method directly. Use the `Notifiable` helper method `stopObservingNotifications` instead.
    ///
    /// Our `Notifiable` protocol relies on this method to provide default implementations.
    nonisolated func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?)

    /// Removes an observer.
    ///
    /// Our `Notifiable` protocol relies on this method to provide default implementations.
    nonisolated func removeObserver(_ observer: Any)

    /// Combine-based variant for listening to posted notifications from `NSNotificationCenter`.
    ///
    /// Our `Themeable` protocol relies on this method to provide default implementations that automatically clean up
    /// observers without having to remove them in the `deinit`, or worry about `nonisolated` handler methods.
    func publisher(for name: Notification.Name, object: AnyObject?) -> NotificationCenter.Publisher
}

/// Provides default implementation for `NotificationCenter` conformance to `NotificationProtocol` with default params.
extension NotificationProtocol {
    public func post(
        name: NSNotification.Name,
        withObject object: Any? = nil,
        withUserInfo userInfo: [AnyHashable: Any]? = nil
    ) {
        self.post(name: name, withObject: object, withUserInfo: userInfo)
    }
}

/// Make NotificationCenter conform to our `NotificationProtocol` protocol. This will allow us to mock the notification
/// center in our tests.
extension NotificationCenter: NotificationProtocol {
    public func post(
        name: NSNotification.Name,
        withObject object: Any? = nil,
        withUserInfo userInfo: [AnyHashable: Any]? = nil
    ) {
        self.post(name: name, object: object, userInfo: userInfo)
    }
}
