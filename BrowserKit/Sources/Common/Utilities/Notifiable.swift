// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@objc
public protocol NotificationProtocol {
    func post(name: NSNotification.Name, withObject object: Any?, withUserInfo info: Any?)
    func addObserver(_ observer: Any,
                     selector aSelector: Selector,
                     name aName: NSNotification.Name?,
                     object anObject: Any?)
    func addObserver(name: NSNotification.Name?,
                     queue: OperationQueue?,
                     using block: @escaping (Notification) -> Void) -> NSObjectProtocol?
    func removeObserver(_ observer: Any)
}

extension NotificationProtocol {
    public func post(name: NSNotification.Name, withObject object: Any? = nil, withUserInfo info: Any? = nil) {
        self.post(name: name, withObject: object, withUserInfo: info)
    }
}

extension NotificationCenter: NotificationProtocol {
    public func post(name: NSNotification.Name, withObject object: Any?, withUserInfo info: Any?) {
        let payload = (info as? [AnyHashable: Any])
        self.post(name: name, object: object, userInfo: payload)
    }

    public func addObserver(name: NSNotification.Name?,
                            queue: OperationQueue?,
                            using block: @escaping (Notification) -> Void) -> NSObjectProtocol? {
        self.addObserver(forName: name,
                         object: nil,
                         queue: queue,
                         using: block)
    }
}

@objc
public protocol Notifiable {
    var notificationCenter: NotificationProtocol { get set }
    @MainActor
    func handleNotifications(_ notification: Notification)
}

public extension Notifiable {
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
