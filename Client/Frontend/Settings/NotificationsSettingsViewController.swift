// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Combine

class NotificationsSettingsViewController: SettingsTableViewController, FeatureFlaggable {
    let allowAllNotifications: BoolSettingSettable
    let tabsNotifications: BoolSettingSettable
    let syncSignInNotifications: BoolSettingSettable
    let tipsAndFeaturesNotifications: BoolSettingSettable

    private var cancellables = Set<AnyCancellable>()

    init(prefs: Prefs) {
        let enabled = prefs.boolForKey(PrefsKeys.Notifications.AllowAllNotifications) ?? false

        self.allowAllNotifications = BoolSettingSettable(
            title: .Settings.Notifications.AllowAllNotificationsTitle,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.AllowAllNotifications
        )

        self.tabsNotifications = BoolSettingSettable(
            title: .Settings.Notifications.TabsNotificationsTitle,
            description: .Settings.Notifications.TabsNotificationsStatus,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.TabsNotifications,
            enabled: enabled
        )

        self.syncSignInNotifications = BoolSettingSettable(
            title: .Settings.Notifications.SyncSignInNotificationsTitle,
            description: .Settings.Notifications.SyncSignInNotificationsStatus,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.SyncSignInNotifications,
            enabled: enabled
        )

        self.tipsAndFeaturesNotifications = BoolSettingSettable(
            title: .Settings.Notifications.TipsAndFeaturesNotificationsTitle,
            description: .Settings.Notifications.TipsAndFeaturesNotificationsStatus,
            prefs: prefs,
            prefKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications,
            enabled: enabled
        )

        super.init(style: .grouped)

        allowAllNotifications
            .$isOn
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                guard let self = self else { return }

                Task {
                    let shouldEnable = await self.notificationsChanged(value)
                    self.allowAllNotifications.isOn = shouldEnable
                    self.tabsNotifications.isOn = shouldEnable
                    self.syncSignInNotifications.isOn = shouldEnable
                    self.tipsAndFeaturesNotifications.isOn = shouldEnable

                    self.tabsNotifications.enabled = shouldEnable
                    self.syncSignInNotifications.enabled = shouldEnable
                    self.tipsAndFeaturesNotifications.enabled = shouldEnable

                    self.tableView.reloadData()
                }
                
                print("allowAllNotifications is \(value)")
            }
            .store(in: &self.cancellables)

        tabsNotifications
            .$isOn
            .dropFirst()
            .removeDuplicates()
            .sink { value in
                print("tabsNotifications is \(value)")
            }
            .store(in: &self.cancellables)

        syncSignInNotifications
            .$isOn
            .dropFirst()
            .removeDuplicates()
            .sink { value in
                print("syncSignInNotifications is \(value)")
            }
            .store(in: &self.cancellables)

        tipsAndFeaturesNotifications
            .$isOn
            .dropFirst()
            .removeDuplicates()
            .sink { value in
                print("tipsAndFeaturesNotifications is \(value)")
            }
            .store(in: &self.cancellables)

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
