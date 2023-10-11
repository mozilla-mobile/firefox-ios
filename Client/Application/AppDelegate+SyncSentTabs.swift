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
    private var applicationHelper: ApplicationHelper

    init(app: UIApplication, 
         logger: Logger = DefaultLogger.shared,
         applicationHelper: ApplicationHelper = DefaultApplicationHelper()) {
        self.app = app
        self.logger = logger
        self.applicationHelper = applicationHelper
    }

    func openSendTabs(for urls: [URL]) {
        DispatchQueue.main.async {
            guard self.app.applicationState == .active else { return }
            // TODO: Laurie check what happens with multiple URLs
            for urlToOpen in urls {
                let urlString = URL.mozInternalScheme + "://open-url?url=\(urlToOpen)}"
                guard let url = URL(string: urlString) else { continue }
                self.applicationHelper.open(url)
            }
        }
    }
}
