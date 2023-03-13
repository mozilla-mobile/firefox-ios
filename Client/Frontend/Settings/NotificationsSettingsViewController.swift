// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class NotificationsSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    private lazy var syncSignInNotifications: BoolSetting = {
        let enabled = prefs.boolForKey(PrefsKeys.Notifications.AllowAllNotifications) ?? false
        return BoolSetting(
            title: .Settings.Notifications.SyncNotificationsTitle,
            description: .Settings.Notifications.SyncNotificationsStatus,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.SyncSignInNotifications,
            enabled: enabled
        ) { _ in
            // enable/disable syncSignIn notifications
        }
    }()

    private lazy var tipsAndFeaturesNotifications: BoolSetting = {
        let enabled = prefs.boolForKey(PrefsKeys.Notifications.AllowAllNotifications) ?? false
        return BoolSetting(
            title: .Settings.Notifications.TipsAndFeaturesNotificationsTitle,
            description: .Settings.Notifications.TipsAndFeaturesNotificationsStatus,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications,
            enabled: enabled
        ) { _ in
            // enable/disable tipsAndFeatures notifications
        }
    }()

    private let prefs: Prefs

    init(prefs: Prefs) {
        self.prefs = prefs
        super.init(style: .grouped)
        self.title = .SettingsSiriSectionName
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        return [
            SettingSection(children: [syncSignInNotifications, tipsAndFeaturesNotifications])
        ]
    }
}
