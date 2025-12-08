// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

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
    func stopObservingNotifications(
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
