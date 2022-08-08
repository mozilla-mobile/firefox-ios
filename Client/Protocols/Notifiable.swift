// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@objc protocol NotificationProtocol {
    func post(name: NSNotification.Name)
    func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?)
    func removeObserver(_ observer: Any)
}

extension NotificationCenter: NotificationProtocol {
    func post(name: NSNotification.Name) {
        self.post(name: name, object: nil)
    }
}

@objc protocol Notifiable {
    var notificationCenter: NotificationProtocol { get set }
    func handleNotifications(_ notification: Notification)
}

extension Notifiable {
    func setupNotifications(forObserver observer: Any,
                            observing notifications: [Notification.Name]) {

        notifications.forEach {
            notificationCenter.addObserver(observer,
                                           selector: #selector(handleNotifications),
                                           name: $0,
                                           object: nil)
        }
    }
}
