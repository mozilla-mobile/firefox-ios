// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

final class MockNotificationCenter: NotificationProtocol, @unchecked Sendable {
    var postCalled: (NSNotification.Name) -> Void = { _ in }
    var postCallCount = 0
    var addObserverCallCount = 0
    var removeObserverCallCount = 0
    var observers: [NSNotification.Name] = []

    var savePostName: NSNotification.Name?
    var savePostObject: Any?
    var saveUserInfo: Any?

    weak var notifiableListener: Notifiable?

    func post(name: NSNotification.Name) {
        savePostName = name
        postCallCount += 1
        self.notifiableListener?.handleNotifications(Notification(name: name))
    }

    func post(name aName: NSNotification.Name, withObject anObject: Any?, withUserInfo info: Any?) {
        savePostName = aName
        savePostObject = anObject
        saveUserInfo = info
        postCallCount += 1
        postCalled(aName)
        self.notifiableListener?.handleNotifications(Notification(name: aName))
    }

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

    func addObserver(
        name: NSNotification.Name?,
        queue: OperationQueue?,
        using block: @escaping (Notification) -> Void
    ) -> NSObjectProtocol? {
        addObserverCallCount += 1
        guard let name else { return nil }
        observers.append(name)
        return nil
    }

    func removeObserver(_ observer: Any) {
        removeObserverCallCount += 1
    }
}
