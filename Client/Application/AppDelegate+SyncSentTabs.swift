// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage
import Sync
import UserNotifications
import Account
import Common

extension UIApplication {
    var sendTabDelegate: SendTabDelegate {
        return AppSendTabDelegate(app: self)
    }
}

/**
 Sent tabs can be displayed not only by receiving push notifications, but by sync.
 Sync will get the list of sent tabs, and try to display any in that list.
 Thus, push notifications are not needed to receive sent tabs, they can be handled
 when the app performs a sync.
 */
class AppSendTabDelegate: SendTabDelegate {
    private let app: UIApplication
    private let logger: Logger

    init(app: UIApplication, logger: Logger = DefaultLogger.shared) {
        self.app = app
        self.logger = logger
    }

    func openSendTabs(for urls: [URL]) {
        DispatchQueue.main.async {
            if self.app.applicationState == .active {
                for url in urls {
                    let object = OpenTabNotificationObject(type: .switchToTabForURLOrOpen(url))
                    NotificationCenter.default.post(name: .OpenTabNotification, object: object)
                }
            }
        }
    }
}
