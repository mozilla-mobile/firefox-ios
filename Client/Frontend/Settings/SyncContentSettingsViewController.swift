/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Sync

class ManageSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .disclosureIndicator }

    override var accessibilityIdentifier: String? { return "Manage" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile

        super.init(title: NSAttributedString(string: Strings.FxAManageAccount, attributes: [NSForegroundColorAttributeName: SettingsUX.TableViewRowTextColor]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = FxAContentViewController(profile: profile)

        if let account = profile.getAccount() {
            var cs = URLComponents(url: account.configuration.settingsURL, resolvingAgainstBaseURL: false)
            cs?.queryItems?.append(URLQueryItem(name: "email", value: account.email))
            if let url = try? cs?.asURL() {
                viewController.url = url
            }
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class DisconnectSetting: Setting {
    let profile: Profile
    override var accessoryType: UITableViewCellAccessoryType { return .none }
    override var textAlignment: NSTextAlignment { return .center }

    override var title: NSAttributedString? {
        return NSAttributedString(string: Strings.SettingsDisconnectSyncButton, attributes: [NSForegroundColorAttributeName: UIConstants.DestructiveRed])
    }
    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
    }

    override var accessibilityIdentifier: String? { return "SignOut" }

    override func onClick(_ navigationController: UINavigationController?) {
        let alertController = UIAlertController(
            title: Strings.SettingsDisconnectSyncAlertTitle,
            message: Strings.SettingsDisconnectSyncAlertBody,
            preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(
            UIAlertAction(title: Strings.SettingsDisconnectCancelAction, style: .cancel) { (action) in
                // Do nothing.
        })
        alertController.addAction(
            UIAlertAction(title: Strings.SettingsDisconnectDestructiveAction, style: .destructive) { (action) in
                FxALoginHelper.sharedInstance.applicationDidDisconnect(UIApplication.shared)
                LeanPlumClient.shared.set(attributes: [LPAttributeKey.signedInSync: self.profile.hasAccount()])
                _ = navigationController?.popViewController(animated: true)
        })
        navigationController?.present(alertController, animated: true, completion: nil)
    }
}

class SyncContentSettingsViewController: SettingsTableViewController {
    fileprivate var enginesToSyncOnExit: Set<String> = Set()

    init() {
        super.init(style: .grouped)

        self.title = Strings.FxASettingsTitle
        hasSectionSeparatorLine = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        if !enginesToSyncOnExit.isEmpty {
            _ = self.profile.syncManager.syncNamedCollections(why: SyncReason.engineEnabled, names: Array(enginesToSyncOnExit))
            enginesToSyncOnExit.removeAll()
        }
        super.viewWillDisappear(animated)
    }

    func engineSettingChanged(_ engineName: String) -> (Bool) -> Void {
        let prefName = "sync.engine.\(engineName).enabledStateChanged"
        return { enabled in
            if let _ = self.profile.prefs.boolForKey(prefName) { // Switch it back to not-changed
                self.profile.prefs.removeObjectForKey(prefName)
                self.enginesToSyncOnExit.remove(engineName)
            } else {
                self.profile.prefs.setBool(true, forKey: prefName)
                self.enginesToSyncOnExit.insert(engineName)
            }
        }
    }

    override func generateSettings() -> [SettingSection] {
        let manage = ManageSetting(settings: self)
        let manageSection = SettingSection(title: nil, footerTitle: nil, children: [manage])

        let bookmarks = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.bookmarks.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncBookmarksEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("bookmarks"))
        let history = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.history.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncHistoryEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("history"))
        let tabs = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.tabs.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncTabsEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("tabs"))
        let passwords = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.passwords.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncLoginsEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("passwords"))

        let enginesSection = SettingSection(title: NSAttributedString(string: Strings.FxASettingsSyncSettings), footerTitle: nil, children: [bookmarks, history, tabs, passwords])

        let disconnect = DisconnectSetting(settings: self)
        let disconnectSection = SettingSection(title: nil, footerTitle: nil, children: [disconnect])

        return [manageSection, enginesSection, disconnectSection]
    }
}
