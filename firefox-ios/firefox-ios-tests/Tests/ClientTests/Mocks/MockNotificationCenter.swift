// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class MockNotificationCenter: NotificationProtocol, @unchecked Sendable {
    var postCalled: (NSNotification.Name) -> Void = { _ in }
    var postCallCount = 0
    var addObserverCallCount = 0
    var addPublisherCount = 0
    var removeObserverCallCount = 0
    var observers: [NSNotification.Name] = []

    var savePostName: NSNotification.Name?
    var savePostObject: Any?
    var saveUserInfo: Any?

    weak var notifiableListener: Notifiable?

    func addObserver(
        _ observer: Any,
        selector aSelector: Selector,
        name aName: NSNotification.Name?,
        object anObject: Any?
    ) {
        addObserverCallCount += 1
        guard let aName else { return }
        observers.append(aName)
    }

    func removeObserver(_ observer: Any) {
        removeObserverCallCount += 1
    }

    func post(name: NSNotification.Name, withObject: Any?, withUserInfo: [AnyHashable: Any]?) {
        savePostName = name
        savePostObject = withObject
        saveUserInfo = withUserInfo
        postCallCount += 1
        postCalled(name)
        self.notifiableListener?.handleNotifications(Notification(name: name))
    }

    func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?) {
        // Implement as needed
    }

    func publisher(for name: Notification.Name, object: AnyObject?) -> NotificationCenter.Publisher {
        addPublisherCount += 1
        observers.append(name)

        // Temporary because we probably can't create a `NotificationCenter.Publisher`, possibly we can rewrite `Notifiable`
        // to abstract this logic a bit more if you need to test with this method.
        return NotificationCenter.default.publisher(for: Notification.Name("FakeNotification"))
    }
}
