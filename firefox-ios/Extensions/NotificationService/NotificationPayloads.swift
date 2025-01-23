// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct NotificationSentTabs {
    static let sentTabsKey = "sentTabs"

    struct Payload {
        static let titleKey = "title"
        static let urlKey = "url"
        static let displayURLKey = "displayURL"
        static let deviceNameKey = "deviceName"
    }
}

struct NotificationCloseTabs {
    static let closeTabsKey = "closeRemoteTabs"
    static let notificationCategoryId: String = "org.mozilla.ios.fxa.notification.category"
    static let messageIdKey: String = "messageId"
}
