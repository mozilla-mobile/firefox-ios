/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Sync
import Account
import MozillaAppServices

class ManageFxAccountSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCell.AccessoryType { return .disclosureIndicator }

    override var accessibilityIdentifier: String? { return "Manage" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile

        super.init(title: NSAttributedString(string: Strings.FxAManageAccount, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.rowText]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = FxAWebViewController(pageType: .settingsPage, profile: profile, dismissalStyle: .popToRootVC, deepLinkParams: nil)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class DisconnectSetting: Setting {
    let settingsVC: SettingsTableViewController
    let profile: Profile
    override var accessoryType: UITableViewCell.AccessoryType { return .none }
    override var textAlignment: NSTextAlignment { return .center }

    override var title: NSAttributedString? {
        return NSAttributedString(string: Strings.SettingsDisconnectSyncButton, attributes: [NSAttributedString.Key.foregroundColor: UIColor.theme.general.destructiveRed])
    }
    
    init(settings: SettingsTableViewController) {
        self.settingsVC = settings
        self.profile = settings.profile
    }

    override var accessibilityIdentifier: String? { return "SignOut" }

    override func onClick(_ navigationController: UINavigationController?) {
        let alertController = UIAlertController(
            title: Strings.SettingsDisconnectSyncAlertTitle,
            message: Strings.SettingsDisconnectSyncAlertBody,
            preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(
            UIAlertAction(title: Strings.SettingsDisconnectCancelAction, style: .cancel) { (action) in
                // Do nothing.
        })
        alertController.addAction(
            UIAlertAction(title: Strings.SettingsDisconnectDestructiveAction, style: .destructive) { (action) in
                self.profile.removeAccount()
                TelemetryWrapper.recordEvent(category: .firefoxAccount, method: .settings, object: .accountDisconnected)
                LeanPlumClient.shared.set(attributes: [LPAttributeKey.signedInSync: self.profile.hasAccount()])

                // If there is more than one view controller in the navigation controller, we can pop.
                // Otherwise, assume that we got here directly from the App Menu and dismiss the VC.
                if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
                    _ = navigationController.popViewController(animated: true)
                } else {
                    self.settingsVC.dismiss(animated: true, completion: nil)
                }
        })
        navigationController?.present(alertController, animated: true, completion: nil)
    }
}

class DeviceNamePersister: SettingValuePersister {
    func readPersistedValue() -> String? {
        guard let val = RustFirefoxAccounts.shared.accountManager.peek()?.deviceConstellation()?
            .state()?.localDevice?.displayName else {
                return UserDefaults.standard.string(forKey: RustFirefoxAccounts.prefKeyLastDeviceName)
        }
        UserDefaults.standard.set(val, forKey: RustFirefoxAccounts.prefKeyLastDeviceName)
        return val
    }

    func writePersistedValue(value: String?) {
        guard let newName = value,
            let deviceConstellation = RustFirefoxAccounts.shared.accountManager.peek()?.deviceConstellation() else {
            return
        }
        UserDefaults.standard.set(newName, forKey: RustFirefoxAccounts.prefKeyLastDeviceName)

        deviceConstellation.setLocalDeviceName(name: newName)
    }
}

class DeviceNameSetting: StringSetting {
    weak var tableView: UITableViewController?

    private var notification: NSObjectProtocol?

    init(settings: SettingsTableViewController) {
        tableView = settings
        let settingsIsValid: (String?) -> Bool = { !($0?.isEmpty ?? true) }
        super.init(defaultValue: DeviceInfo.defaultClientName(), placeholder: "", accessibilityIdentifier: "DeviceNameSetting", persister: DeviceNamePersister(), settingIsValid: settingsIsValid)

        notification = NotificationCenter.default.addObserver(forName: Notification.Name.constellationStateUpdate, object: nil, queue: nil) { [weak self] notification in
            self?.tableView?.tableView.reloadData()
        }
    }

    override func onConfigureCell(_ cell: UITableViewCell) {
        super.onConfigureCell(cell)
        textField.textAlignment = .natural
    }

    deinit {
        if let notification = notification {
            NotificationCenter.default.removeObserver(notification)
        }
    }
}


class SyncContentSettingsViewController: SettingsTableViewController {
    fileprivate var enginesToSyncOnExit: Set<String> = Set()

    init() {
        super.init(style: .grouped)

        self.title = Strings.FxASettingsTitle

        RustFirefoxAccounts.shared.accountManager.peek()?.deviceConstellation()?.refreshState()
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
        let manage = ManageFxAccountSetting(settings: self)
        let manageSection = SettingSection(title: nil, footerTitle: nil, children: [manage])

        let bookmarks = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.bookmarks.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncBookmarksEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("bookmarks"))
        let history = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.history.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncHistoryEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("history"))
        let tabs = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.tabs.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncTabsEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("tabs"))
        let passwords = BoolSetting(prefs: profile.prefs, prefKey: "sync.engine.passwords.enabled", defaultValue: true, attributedTitleText: NSAttributedString(string: Strings.FirefoxSyncLoginsEngine), attributedStatusText: nil, settingDidChange: engineSettingChanged("passwords"))

        let enginesSection = SettingSection(title: NSAttributedString(string: Strings.FxASettingsSyncSettings), footerTitle: nil, children: [bookmarks, history, tabs, passwords])

        let deviceName = DeviceNameSetting(settings: self)
        let deviceNameSection = SettingSection(title: NSAttributedString(string: Strings.FxASettingsDeviceName), footerTitle: nil, children: [deviceName])

        let disconnect = DisconnectSetting(settings: self)
        let disconnectSection = SettingSection(title: nil, footerTitle: nil, children: [disconnect])

        return [manageSection, enginesSection, deviceNameSection, disconnectSection]
    }
}
