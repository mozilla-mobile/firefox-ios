// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class NotificationsSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    lazy var allowAllNotifications: BoolSetting = {
        return BoolSetting(
            title: .Settings.Notifications.AllowAllNotificationsTitle,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.AllowAllNotifications
        ) { [weak self] value in
            guard let self = self else { return }

            Task {
                let shouldEnable = await self.notificationsChanged(value)
                self.allowAllNotifications.control.setOn(shouldEnable, animated: true)
                self.allowAllNotifications.writeBool(self.allowAllNotifications.control)

                self.tabsNotifications.control.setOn(shouldEnable, animated: true)
                self.tabsNotifications.writeBool(self.tabsNotifications.control)

                self.syncSignInNotifications.control.setOn(shouldEnable, animated: true)
                self.syncSignInNotifications.writeBool(self.syncSignInNotifications.control)

                self.tipsAndFeaturesNotifications.control.setOn(shouldEnable, animated: true)
                self.tipsAndFeaturesNotifications.writeBool(self.tipsAndFeaturesNotifications.control)

                self.tabsNotifications.enabled = shouldEnable
                self.syncSignInNotifications.enabled = shouldEnable
                self.tipsAndFeaturesNotifications.enabled = shouldEnable

                self.tableView.reloadData()
            }
        }
    }()

    lazy var tabsNotifications: BoolSetting = {
        let enabled = prefs.boolForKey(PrefsKeys.Notifications.AllowAllNotifications) ?? false
        return BoolSetting(
            title: .Settings.Notifications.TabsNotificationsTitle,
            description: .Settings.Notifications.TabsNotificationsStatus,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.TabsNotifications,
            enabled: enabled
        ) { value in
            print("tabsNotifications is \(value)")
        }
    }()

    lazy var syncSignInNotifications: BoolSetting = {
        let enabled = prefs.boolForKey(PrefsKeys.Notifications.AllowAllNotifications) ?? false
        return BoolSetting(
            title: .Settings.Notifications.SyncSignInNotificationsTitle,
            description: .Settings.Notifications.SyncSignInNotificationsStatus,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.SyncSignInNotifications,
            enabled: enabled
        ) { value in
            print("syncSignInNotifications is \(value)")
        }
    }()

    lazy var tipsAndFeaturesNotifications: BoolSetting = {
        let enabled = prefs.boolForKey(PrefsKeys.Notifications.AllowAllNotifications) ?? false
        return BoolSetting(
            title: .Settings.Notifications.TipsAndFeaturesNotificationsTitle,
            description: .Settings.Notifications.TipsAndFeaturesNotificationsStatus,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications,
            enabled: enabled
        ) { value in
            print("tipsAndFeaturesNotifications is \(value)")
        }
    }()

    let prefs: Prefs

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
            SettingSection(children: [allowAllNotifications]),
            SettingSection(children: [tabsNotifications, syncSignInNotifications, tipsAndFeaturesNotifications])
        ]
    }

    func notificationsChanged(_ sendNotifications: Bool) async -> Bool {
        guard sendNotifications else { return false }

        let notificationManager = NotificationManager()
        var sendNotifications = true
        let settings = await notificationManager.getNotificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined, .authorized, .provisional, .ephemeral:
            sendNotifications = true
            do {
                sendNotifications = try await notificationManager.requestAuthorization()
            } catch {
                sendNotifications = false
            }

        case .denied:
            sendNotifications = false
            await MainActor.run {
                let accessDenied = UIAlertController(title: "Notifications Disabled", message: "You need to enable permissions from iOS Settings", preferredStyle: .alert)
                let dismissAction = UIAlertAction(title: .CancelString, style: .default, handler: nil)
                accessDenied.addAction(dismissAction)
                let settingsAction = UIAlertAction(title: .OpenSettingsString, style: .default ) { _ in
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
                }
                accessDenied.addAction(settingsAction)
                self.present(accessDenied, animated: true, completion: nil)
            }

        @unknown default:
            ()
        }
        return sendNotifications
    }
}
