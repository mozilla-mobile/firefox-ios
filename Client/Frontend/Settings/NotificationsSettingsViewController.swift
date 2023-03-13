// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class NotificationsSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    private lazy var syncSignInNotifications: BoolSetting = {
        return BoolSetting(
            title: .Settings.Notifications.SyncNotificationsTitle,
            description: .Settings.Notifications.SyncNotificationsStatus,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.SyncSignInNotifications,
            enabled: true
        ) { _ in
            // enable/disable syncSignIn notifications
        }
    }()

    private lazy var tipsAndFeaturesNotifications: BoolSetting = {
        return BoolSetting(
            title: .Settings.Notifications.TipsAndFeaturesNotificationsTitle,
            description: String(format: .Settings.Notifications.TipsAndFeaturesNotificationsStatus, AppName.shortName.rawValue),
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications,
            enabled: true
        ) { _ in
            // enable/disable tipsAndFeatures notifications
        }
    }()

    private let prefs: Prefs
    private let hasAccount: Bool

    init(prefs: Prefs, hasAccount: Bool) {
        self.prefs = prefs
        self.hasAccount = hasAccount
        super.init(style: .grouped)
        self.title = .SettingsSiriSectionName
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        let childrenSection: [Setting]
        if hasAccount {
            childrenSection = [syncSignInNotifications, tipsAndFeaturesNotifications]
        } else {
            childrenSection = [tipsAndFeaturesNotifications]
        }

        return [
            SettingSection(children: childrenSection)
        ]
    }
}
