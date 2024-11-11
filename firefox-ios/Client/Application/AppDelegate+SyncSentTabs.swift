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
    var fxaCommandsDelegate: FxACommandsDelegate {
        return AppFxACommandsDelegate(app: self)
    }
}

/// Close and Sent tabs can be displayed not only by receiving push notifications,
/// but by sync.
/// Sync will get the list of sent tabs, and try to display any in that list.
/// Thus, push notifications are not needed to receive sent or closed tabs;
/// they can be handled when the app performs a sync.
class AppFxACommandsDelegate: FxACommandsDelegate {
    private let app: ApplicationStateProvider
    private let logger: Logger
    private var applicationHelper: ApplicationHelper
    private var mainQueue: DispatchQueueInterface

    init(app: ApplicationStateProvider,
         logger: Logger = DefaultLogger.shared,
         applicationHelper: ApplicationHelper = DefaultApplicationHelper(),
         mainQueue: DispatchQueueInterface = DispatchQueue.main) {
        self.app = app
        self.logger = logger
        self.applicationHelper = applicationHelper
        self.mainQueue = mainQueue
    }

    func openSendTabs(for urls: [URL]) {
        mainQueue.async {
            guard self.app.applicationState == .active else { return }

            for urlToOpen in urls {
                let urlString = URL.mozInternalScheme + "://open-url?url=\(urlToOpen)"
                guard let url = URL(string: urlString) else { continue }
                self.applicationHelper.open(url)
            }
        }
    }

    func closeTabs(for urls: [URL]) {
        Task {
            await self.applicationHelper.closeTabs(urls)
        }
    }
}
