// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class SpyNotificationCenter: NotificationCenter {
    var notificationNameSent: NSNotification.Name?
    var notificationObjectSent: Any?
    override func post(name aName: NSNotification.Name, object anObject: Any?) {
        super.post(name: aName, object: anObject)
        notificationNameSent = aName
        notificationObjectSent = anObject
    }
}
