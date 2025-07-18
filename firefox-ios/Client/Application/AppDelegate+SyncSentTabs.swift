// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import UserNotifications
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
final class AppFxACommandsDelegate: FxACommandsDelegate, Sendable {
    private let app: ApplicationStateProvider
    private let applicationHelper: ApplicationHelper

    init(app: ApplicationStateProvider,
         applicationHelper: ApplicationHelper = DefaultApplicationHelper()) {
        self.app = app
        self.applicationHelper = applicationHelper
    }

    @MainActor
    func openSendTabs(for urls: [URL]) {
        guard app.applicationState == .active else { return }

        for urlToOpen in urls {
            let urlString = URL.mozInternalScheme + "://open-url?url=\(urlToOpen)"
            guard let url = URL(string: urlString) else { continue }

            applicationHelper.open(url)
        }
    }

    func closeTabs(for urls: [URL]) {
        Task {
            await applicationHelper.closeTabs(urls)
        }
    }
}
