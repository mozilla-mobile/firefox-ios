// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

class NotificationsSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    private lazy var syncNotifications: BoolSetting = {
        return BoolSetting(
            title: .Settings.Notifications.SyncNotificationsTitle,
            description: .Settings.Notifications.SyncNotificationsStatus,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.SyncNotifications,
            enabled: true
        ) { [weak self] value in
            guard let self = self else { return }

            Task {
                let shouldEnable = await self.notificationsChanged(value)
                self.syncNotifications.control.setOn(shouldEnable, animated: true)
                self.syncNotifications.writeBool(self.syncNotifications.control)
            }

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
        ) { [weak self] value in
            guard let self = self else { return }

            Task {
                let shouldEnable = await self.notificationsChanged(value)
                self.tipsAndFeaturesNotifications.control.setOn(shouldEnable, animated: true)
                self.tipsAndFeaturesNotifications.writeBool(self.tipsAndFeaturesNotifications.control)
            }

            // enable/disable tipsAndFeatures notifications
        }
    }()

    private let prefs: Prefs
    private let hasAccount: Bool

    init(prefs: Prefs, hasAccount: Bool) {
        self.prefs = prefs
        self.hasAccount = hasAccount
        super.init(style: .grouped)
        self.title = .Settings.Notifications.Title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func generateSettings() -> [SettingSection] {
        let childrenSection: [Setting]
        if hasAccount {
            childrenSection = [syncNotifications, tipsAndFeaturesNotifications]
        } else {
            childrenSection = [tipsAndFeaturesNotifications]
        }

        return [
            SettingSection(children: childrenSection)
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
                self.present(accessDenied, animated: true, completion: nil)
            }
        @unknown default:
            sendNotifications = false
        }
        return sendNotifications
    }

    var accessDenied: UIAlertController {
        let accessDenied = UIAlertController(
            title: .Settings.Notifications.TurnOnNotificationsTitle,
            message: String(format: .Settings.Notifications.TurnOnNotificationsMessage, AppName.shortName.rawValue),
            preferredStyle: .alert
        )
        let dismissAction = UIAlertAction(
            title: .CancelString,
            style: .default,
            handler: nil
        )
        accessDenied.addAction(dismissAction)
        let settingsAction = UIAlertAction(
            title: .OpenSettingsString,
            style: .default
        ) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
        }
        accessDenied.addAction(settingsAction)
        return accessDenied
    }
}
