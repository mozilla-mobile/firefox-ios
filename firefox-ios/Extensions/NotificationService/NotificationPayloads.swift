// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum NotificationSentTabs {
    static let sentTabsKey = "sentTabs"

    enum Payload {
        static let titleKey = "title"
        static let urlKey = "url"
        static let displayURLKey = "displayURL"
        static let deviceNameKey = "deviceName"
    }
}

enum NotificationCloseTabs {
    static let closeTabsKey = "closeRemoteTabs"
    static let notificationCategoryId = "org.mozilla.ios.fxa.notification.category"
    static let messageIdKey = "messageId"
}
