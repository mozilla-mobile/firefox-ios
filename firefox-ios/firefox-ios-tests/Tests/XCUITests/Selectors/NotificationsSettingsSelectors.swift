// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol NotificationsSettingsSelectorsSet {
    var TIPS_AND_FEATURES_SWITCH: Selector { get }
    var SYSTEM_NOTIFICATIONS_DISABLED_MESSAGE: Selector { get }
    var all: [Selector] { get }
}

struct NotificationsSettingsSelectors: NotificationsSettingsSelectorsSet {
    private enum IDs {
        // Mirrors PrefsKeys.Notifications.TipsAndFeaturesNotifications, used as the switch identifier.
        static let tipsAndFeaturesSwitch = "TipsAndFeaturesNotificationsUserPrefsKey"
        static let systemNotificationsDisabledMessage = "You turned off all Firefox notifications. " +
            "Turn them on by going to device Settings > Notifications > Firefox"
    }

    let TIPS_AND_FEATURES_SWITCH = Selector.switchById(
        IDs.tipsAndFeaturesSwitch,
        description: "Tips and Features toggle in notifications settings",
        groups: ["notifications_settings"]
    )

    let SYSTEM_NOTIFICATIONS_DISABLED_MESSAGE = Selector.staticTextId(
        IDs.systemNotificationsDisabledMessage,
        description: "Footer shown when Firefox notifications are turned off at the system level",
        groups: ["notifications_settings"]
    )

    var all: [Selector] {
        [
            TIPS_AND_FEATURES_SWITCH,
            SYSTEM_NOTIFICATIONS_DISABLED_MESSAGE
        ]
    }
}
