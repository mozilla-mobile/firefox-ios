/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared
import Account

/// App Settings Screen (triggered by tapping the 'Gear' in the Tab Tray Controller)
class AppSettingsTableViewController: SettingsTableViewController {
    fileprivate let SectionHeaderIdentifier = "SectionHeaderIdentifier"

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Settings", comment: "Title in the settings view controller title bar")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"),
            style: UIBarButtonItemStyle.done,
            target: navigationController, action: #selector((navigationController as! SettingsNavigationController).SELdone))
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "AppSettingsTableViewController.navigationItem.leftBarButtonItem"

        tableView.accessibilityIdentifier = "AppSettingsTableViewController.tableView"
        
        // Refresh the user's FxA profile upon viewing settings. This will update their avatar,
        // display name, etc.
        if AppConstants.MOZ_SHOW_FXA_AVATAR {
            profile.getAccount()?.updateProfile()
        }
    }

    override func generateSettings() -> [SettingSection] {
        var settings = [SettingSection]()

        let privacyTitle = NSLocalizedString("Privacy", comment: "Privacy section title")
        let accountDebugSettings = [
            // Debug settings:
            RequirePasswordDebugSetting(settings: self),
            RequireUpgradeDebugSetting(settings: self),
            ForgetSyncAuthStateDebugSetting(settings: self),
            StageSyncServiceDebugSetting(settings: self),
        ]

        let prefs = profile.prefs
        var generalSettings: [Setting] = [
            SearchSetting(settings: self),
            NewTabPageSetting(settings: self),
            HomePageSetting(settings: self),
            OpenWithSetting(settings: self),
            BoolSetting(prefs: prefs, prefKey: "blockPopups", defaultValue: true,
                        titleText: NSLocalizedString("Block Pop-up Windows", comment: "Block pop-up windows setting")),
            BoolSetting(prefs: prefs, prefKey: "saveLogins", defaultValue: true,
                        titleText: NSLocalizedString("Save Logins", comment: "Setting to enable the built-in password manager")),
            ]        
        
        let accountChinaSyncSetting: [Setting]
        if !profile.isChinaEdition {
            accountChinaSyncSetting = []
        } else {
            accountChinaSyncSetting = [
                // Show China sync service setting:
                ChinaSyncServiceSetting(settings: self)
            ]
        }
        // There is nothing to show in the Customize section if we don't include the compact tab layout
        // setting on iPad. When more options are added that work on both device types, this logic can
        // be changed.

        if AppConstants.MOZ_CLIPBOARD_BAR {
            generalSettings += [
                BoolSetting(prefs: prefs, prefKey: "showClipboardBar", defaultValue: false,
                            titleText: Strings.SettingsOfferClipboardBarTitle,
                            statusText: Strings.SettingsOfferClipboardBarStatus)
            ]
        }

        var accountSectionTitle: NSAttributedString?
        if AppConstants.MOZ_SHOW_FXA_AVATAR {
            accountSectionTitle = NSAttributedString(string: Strings.FxAFirefoxAccount)
        }

        let footerText = !profile.hasAccount() ? NSAttributedString(string: Strings.FxASyncUsageDetails) : nil
        settings += [
            SettingSection(title: accountSectionTitle, footerTitle: footerText, children: [
                // Without a Firefox Account:
                ConnectSetting(settings: self),
                AdvanceAccountSetting(settings: self),
                // With a Firefox Account:
                AccountStatusSetting(settings: self),
                SyncNowSetting(settings: self),
                SyncSetting(settings: self)
            ] + accountChinaSyncSetting + accountDebugSettings)]

        settings += [ SettingSection(title: NSAttributedString(string: NSLocalizedString("General", comment: "General settings section title")), children: generalSettings)]

        var privacySettings = [Setting]()
        privacySettings.append(LoginsSetting(settings: self, delegate: settingsDelegate))
        privacySettings.append(TouchIDPasscodeSetting(settings: self))

        privacySettings.append(ClearPrivateDataSetting(settings: self))

        privacySettings += [
            BoolSetting(prefs: prefs,
                prefKey: "settings.closePrivateTabs",
                defaultValue: false,
                titleText: NSLocalizedString("Close Private Tabs", tableName: "PrivateBrowsing", comment: "Setting for closing private tabs"),
                statusText: NSLocalizedString("When Leaving Private Browsing", tableName: "PrivateBrowsing", comment: "Will be displayed in Settings under 'Close Private Tabs'"))
        ]

        if #available(iOS 11, *) {
            privacySettings.append(ContentBlockerSetting(settings: self))
        }

        privacySettings += [
            PrivacyPolicySetting()
        ]

        settings += [
            SettingSection(title: NSAttributedString(string: privacyTitle), children: privacySettings),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("Support", comment: "Support section title")), children: [
                ShowIntroductionSetting(settings: self),
                SendFeedbackSetting(),
                SendAnonymousUsageDataSetting(prefs: prefs, delegate: settingsDelegate),
                OpenSupportPageSetting(delegate: settingsDelegate),
            ]),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("About", comment: "About settings section title")), children: [
                VersionSetting(settings: self),
                LicenseAndAcknowledgementsSetting(),
                YourRightsSetting(),
                ExportBrowserDataSetting(settings: self),
                DeleteExportedDataSetting(settings: self),
                EnableBookmarkMergingSetting(settings: self),
                ForceCrashSetting(settings: self)
            ])]
    
            if profile.hasAccount() {
                settings += [SettingSection(title: nil, footerTitle: NSAttributedString(string: ""), children: [DisconnectSetting(settings: self)])]
            }

        return settings
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = super.tableView(tableView, viewForHeaderInSection: section) as! SettingsTableSectionHeaderFooterView
        // Prevent the top border from showing for the General section.
        if !profile.hasAccount() {
            switch section {
                case 1:
                    headerView.showTopBorder = false
            default:
                break
            }
        }
        return headerView
    }
}

extension AppSettingsTableViewController {
    func navigateToLoginsList() {
        let viewController = LoginListViewController(profile: profile)
        viewController.settingsDelegate = settingsDelegate
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension AppSettingsTableViewController: PasscodeEntryDelegate {
    @objc func passcodeValidationDidSucceed() {
        navigationController?.dismiss(animated: true) {
            self.navigateToLoginsList()
        }
    }
}
