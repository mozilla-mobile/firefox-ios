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

@objc
public protocol Notifiable: AnyObject {
    /// We must treat `@objc` methods as `nonisolated`, as we cannot guarantee actor isolation when called outside
    /// asynchronous contexts. This will change in Swift 6.2 when we can start using `MainActorMessage` to guarantee
    /// threading.
    nonisolated func handleNotifications(_ notification: Notification)
}

public extension Notifiable {
    /// Registers an observer for the given notifications.
    func startObservingNotifications(
        withNotificationCenter notificationCenter: NotificationProtocol,
        forObserver observer: Any,
        observing notifications: [Notification.Name]
    ) {
        // It is possible to add duplicate observers, so to be extra safe with this Notifiable API we will attempt to remove
        // any existing observers matching these requirements first.
        stopObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: observer,
            observing: notifications
        )

        // Set up observers, calling our nonisolated handle method to ensure we don't make the mistake of thinking we can
        // handle notifications on `@MainActor` methods when using `@objc`.
        for notification in notifications {
            notificationCenter.addObserver(
                observer,
                selector: #selector(handleNotifications),
                name: notification,
                object: nil
            )
        }
    }

    /// Deregisters a notification observer for the given notifications.
    ///
    /// It is not necessary to call this on `deinit`. Your theme observer is automatically cleaned up once it is deallocated.
    /// You only need to call this if you want to stop observing a notification during the lifetime of your observer.
    private func stopObservingNotifications(
        withNotificationCenter notificationCenter: NotificationProtocol,
        forObserver observer: Any,
        observing notifications: [Notification.Name]
    ) {
        // Set up observers, calling our nonisolated handle method to ensure we don't make the mistake of thinking we can
        // handle notifications on `@MainActor` methods when using `@objc`.
        for notification in notifications {
            notificationCenter.removeObserver(
                observer,
                name: notification,
                object: nil
            )
        }
    }
}
