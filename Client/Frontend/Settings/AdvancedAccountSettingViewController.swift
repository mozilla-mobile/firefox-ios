/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit
import FxA
import Account

class AdvancedAccountSettingViewController: SettingsTableViewController {
    fileprivate let SectionHeaderIdentifier = "SectionHeaderIdentifier"

    fileprivate var customAutoconfigURI: String?
    fileprivate var customSyncTokenServerURI: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsAdvancedAccountTitle
        self.customAutoconfigURI = self.profile.prefs.stringForKey(PrefsKeys.KeyCustomSyncWeb)
        self.customSyncTokenServerURI = self.profile.prefs.stringForKey(PrefsKeys.KeyCustomSyncTokenServerOverride)
    }

    func clearCustomAutoconfigPrefs() {
        self.profile.prefs.setBool(false, forKey: PrefsKeys.KeyUseCustomAccountAutoconfig)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncToken)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncProfile)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncOauth)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncAuth)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncWeb)

        // To help prevent the account being in a strange state, we force it to
        // log out when user clears their custom server preferences.
        self.profile.removeAccount()
    }

    func setCustomAutoconfigPrefs() {
        guard let customAutoconfigURIString = self.customAutoconfigURI, let customAutoconfigURI = URL(string: customAutoconfigURIString), customAutoconfigURI.schemeIsValid, customAutoconfigURI.host != nil  else {
            // If the user attempts to set a nil url, clear all the custom service perferences
            // and use default FxA servers.
            self.displayNoAutoconfigSetAlert()
            return
        }

        // FxA stores its server configuation under a well-known path. This attempts to download the configuration
        // and save it into the users preferences.
        let syncConfigureString = customAutoconfigURIString + "/.well-known/fxa-client-configuration"
        guard let syncConfigureURL = URL(string: syncConfigureString) else {
            return
        }

        URLSession.shared.dataTask(with: syncConfigureURL, completionHandler: {(data, response, error) in
            guard error == nil,
                let data = data,
                let json = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any],
                let customSyncToken = json["sync_tokenserver_base_url"] as? String,
                let customSyncProfile = json["profile_server_base_url"] as? String,
                let customSyncOauth = json["oauth_server_base_url"] as? String,
                let customSyncAuth = json["auth_server_base_url"] as? String else {

                // Something went wrong while downloading or parsing the configuration.
                self.displayAutoconfigErrorAlert()
                return
            }

            self.profile.prefs.setBool(true, forKey: PrefsKeys.KeyUseCustomAccountAutoconfig)
            self.profile.prefs.setString(customSyncToken, forKey: PrefsKeys.KeyCustomSyncToken)
            self.profile.prefs.setString(customSyncProfile, forKey: PrefsKeys.KeyCustomSyncProfile)
            self.profile.prefs.setString(customSyncOauth, forKey: PrefsKeys.KeyCustomSyncOauth)
            self.profile.prefs.setString(customSyncAuth, forKey: PrefsKeys.KeyCustomSyncAuth)
            self.profile.prefs.setString(customAutoconfigURI.absoluteString, forKey: PrefsKeys.KeyCustomSyncWeb)
            self.profile.removeAccount()
            self.displaySuccessAlert()
        }).resume()
    }

    func clearCustomSyncTokenServerPrefs() {
        self.profile.prefs.setBool(false, forKey: PrefsKeys.KeyUseCustomSyncTokenServerOverride)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncTokenServerOverride)
    }

    func setCustomSyncTokenServerPrefs() {
        guard let customSyncTokenServerURIString = self.customSyncTokenServerURI, let customSyncTokenServerURI = URL(string: customSyncTokenServerURIString), customSyncTokenServerURI.schemeIsValid, customSyncTokenServerURI.host != nil else {
            // If the user attempts to set a nil url, clear all the custom service perferences
            // and use default FxA servers.
            self.displayNoTokenServerSetAlert()
            return
        }

        self.profile.prefs.setBool(true, forKey: PrefsKeys.KeyUseCustomSyncTokenServerOverride)
        self.profile.prefs.setString(customSyncTokenServerURI.absoluteString, forKey: PrefsKeys.KeyCustomSyncTokenServerOverride)
        self.displaySuccessAlert()
    }

    func displaySuccessAlert() {
        let alertController = UIAlertController(title: "", message: Strings.SettingsAdvancedAccountUrlUpdatedAlertMessage, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: Strings.OKString, style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true)
    }

    func displayAutoconfigErrorAlert() {
        self.profile.prefs.setBool(false, forKey: PrefsKeys.KeyUseCustomAccountAutoconfig)
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
        let alertController = UIAlertController(title: Strings.SettingsAdvancedAccountUrlErrorAlertTitle, message: Strings.SettingsAdvancedAccountUrlErrorAlertMessage, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: Strings.OKString, style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true)
    }

    func displayNoAutoconfigSetAlert() {
        self.profile.prefs.setBool(false, forKey: PrefsKeys.KeyUseCustomAccountAutoconfig)
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
        let alertController = UIAlertController(title: Strings.SettingsAdvancedAccountUrlErrorAlertTitle, message: Strings.SettingsAdvancedAccountEmptyAutoconfigURIErrorAlertMessage, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: Strings.OKString, style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true)
    }

    func displayNoTokenServerSetAlert() {
        self.profile.prefs.setBool(false, forKey: PrefsKeys.KeyUseCustomSyncTokenServerOverride)
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .automatic)
        }
        let alertController = UIAlertController(title: Strings.SettingsAdvancedAccountUrlErrorAlertTitle, message: Strings.SettingsAdvancedAccountEmptyTokenServerURIErrorAlertMessage, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: Strings.OKString, style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true)
    }

    override func generateSettings() -> [SettingSection] {
        let prefs = profile.prefs
        let customAutoconfigURISetting = CustomURLSetting(prefs: prefs,
                                                         prefKey: PrefsKeys.KeyCustomSyncWeb,
                                                         placeholder: Strings.SettingsAdvancedAccountCustomAutoconfigURIPlaceholder,
                                                         accessibilityIdentifier: "CustomAutoconfigURISetting",
                                                         settingDidChange: { fieldText in
                                                            self.customAutoconfigURI = fieldText
                                                            if let customAutoconfigURI = self.customAutoconfigURI, customAutoconfigURI.isEmpty {
                                                                self.clearCustomAutoconfigPrefs()
                                                                return
                                                            }
        })
        let customSyncTokenServerURISetting = CustomURLSetting(prefs: prefs,
                                                    prefKey: PrefsKeys.KeyCustomSyncTokenServerOverride,
                                                    placeholder: Strings.SettingsAdvancedAccountCustomSyncTokenServerURIPlaceholder,
                                                    accessibilityIdentifier: "CustomSyncTokenServerURISetting",
                                                    settingDidChange: { fieldText in
                                                        self.customSyncTokenServerURI = fieldText
                                                        if let customSyncTokenServerURI = self.customSyncTokenServerURI, customSyncTokenServerURI.isEmpty {
                                                            self.clearCustomSyncTokenServerPrefs()
                                                            return
                                                        }
        })

        let autoconfigSettings = [
            CustomAutoconfigEnableSetting(
                prefs: prefs,
                settingDidChange: { result in
                    if result == true {
                        // Reload the table data to ensure that the updated value is set
                        self.tableView?.reloadData()
                        self.setCustomAutoconfigPrefs()
                    }
            }),
            customAutoconfigURISetting
        ]

        let tokenServerSettings = [
            CustomSyncTokenServerEnableSetting(
                prefs: prefs,
                settingDidChange: { result in
                    if result == true {
                        // Reload the table data to ensure that the updated value is set
                        self.tableView?.reloadData()
                        self.setCustomSyncTokenServerPrefs()
                    }
            }),
            customSyncTokenServerURISetting
        ]

        let settings: [SettingSection] = [
            SettingSection(title: nil, children: autoconfigSettings),
            SettingSection(title: NSAttributedString(string: Strings.SettingsAdvancedAccountAutoconfigSectionFooter), children: []),
            SettingSection(title: nil, children: tokenServerSettings),
            SettingSection(title: NSAttributedString(string: Strings.SettingsAdvancedAccountTokenServerSectionFooter), children: [])
        ]

        return settings
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderIdentifier) as! ThemedTableSectionHeaderFooterView
        let sectionSetting = settings[section]
        headerView.titleLabel.text = sectionSetting.title?.string

        switch section {
        // Hide the bottom border for the FxA custom server notes.
        case 1, 3:
            headerView.titleAlignment = .top
            headerView.titleLabel.numberOfLines = 0
            headerView.showBottomBorder = false
        default:
            return super.tableView(tableView, viewForHeaderInSection: section)
        }
        return headerView
    }
}

class CustomAutoconfigEnableSetting: BoolSetting {
    init(prefs: Prefs, settingDidChange: ((Bool?) -> Void)? = nil) {
        super.init(
            prefs: prefs, prefKey: PrefsKeys.KeyUseCustomAccountAutoconfig, defaultValue: false,
            attributedTitleText: NSAttributedString(string: Strings.SettingsAdvancedAccountUseCustomAccountsServiceTitle),
            settingDidChange: settingDidChange
        )
    }
}

class CustomSyncTokenServerEnableSetting: BoolSetting {
    init(prefs: Prefs, settingDidChange: ((Bool?) -> Void)? = nil) {
        super.init(
            prefs: prefs, prefKey: PrefsKeys.KeyUseCustomSyncTokenServerOverride, defaultValue: false,
            attributedTitleText: NSAttributedString(string: Strings.SettingsAdvancedAccountUseCustomSyncTokenServerTitle),
            settingDidChange: settingDidChange
        )
    }
}

class CustomURLSetting: WebPageSetting {
    override init(prefs: Prefs, prefKey: String, defaultValue: String? = nil, placeholder: String, accessibilityIdentifier: String, settingDidChange: ((String?) -> Void)? = nil) {
        super.init(prefs: prefs,
                   prefKey: prefKey,
                   defaultValue: defaultValue,
                   placeholder: placeholder,
                   accessibilityIdentifier: accessibilityIdentifier,
                   settingDidChange: settingDidChange)
        textField.clearButtonMode = .always
    }
}
