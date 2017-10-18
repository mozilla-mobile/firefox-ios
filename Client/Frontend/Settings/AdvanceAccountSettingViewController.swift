/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit
import Foundation
import FxA
import Account

class AdvanceAccountSettingViewController: SettingsTableViewController {
    fileprivate let SectionHeaderIdentifier = "SectionHeaderIdentifier"
    
    fileprivate var customSyncUrl: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsAdvanceAccountSectionName
        self.customSyncUrl = self.profile.prefs.stringForKey(PrefsKeys.KeyCustomSyncWeb)
    }
    
    func clearCustomAccountPrefs() {
        self.profile.prefs.setBool(false, forKey: PrefsKeys.KeyUseCustomSyncService)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncToken)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncProfile)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncOauth)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncAuth)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncWeb)
        
        // To help prevent the account being in a strange state, we force it to
        // log out when user clears their custom server preferences.
        self.profile.removeAccount()
    }
    
    func setCustomAccountPrefs(_ data: Data, url: URL) {        
        guard let settings = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String:Any],
                let customSyncToken = settings["sync_tokenserver_base_url"] as? String,
                let customSyncProfile = settings["profile_server_base_url"] as? String,
                let customSyncOauth = settings["oauth_server_base_url"] as? String,
                let customSyncAuth = settings["auth_server_base_url"] as? String else {
            return
        }

        self.profile.prefs.setBool(true, forKey: PrefsKeys.KeyUseCustomSyncService)
        self.profile.prefs.setString(customSyncToken, forKey: PrefsKeys.KeyCustomSyncToken)
        self.profile.prefs.setString(customSyncProfile, forKey: PrefsKeys.KeyCustomSyncProfile)
        self.profile.prefs.setString(customSyncOauth, forKey: PrefsKeys.KeyCustomSyncOauth)
        self.profile.prefs.setString(customSyncAuth, forKey: PrefsKeys.KeyCustomSyncAuth)
        self.profile.prefs.setString(url.absoluteString, forKey: PrefsKeys.KeyCustomSyncWeb)
        self.profile.removeAccount()
        self.displaySuccessAlert()
    }
    
    func setCustomAccountPrefs() {
        guard let urlString = self.customSyncUrl, let url = URL(string: urlString) else {
            // If the user attempts to set a nil url, clear all the custom service perferences
            // and use default FxA servers.
            self.displayNoServiceSetAlert()
            return
        }
        
        // FxA stores its server configuation under a well-known path. This attempts to download the configuration
        // and save it into the users preferences.
        let syncConfigureString = urlString + "/.well-known/fxa-client-configuration"
        guard let syncConfigureURL = URL(string: syncConfigureString) else {
            return
        }
        
        URLSession.shared.dataTask(with: syncConfigureURL, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else {
                // Something went wrong while downloading or parsing the configuration.
                self.displayErrorAlert()
                return
            }
            self.setCustomAccountPrefs(data, url: url)
        }).resume()
    }
    
    func displaySuccessAlert() {
        let alertController = UIAlertController(title: "", message: Strings.SettingsAdvanceAccountUrlUpdatedAlertMessage, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: Strings.SettingsAdvanceAccountUrlUpdatedAlertOk, style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true)
    }
    
    func displayErrorAlert() {
        self.profile.prefs.setBool(false, forKey: PrefsKeys.KeyUseCustomSyncService)
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: UITableViewRowAnimation.automatic)
        }
        let alertController = UIAlertController(title: Strings.SettingsAdvanceAccountUrlErrorAlertTitle, message: Strings.SettingsAdvanceAccountUrlErrorAlertMessage, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: Strings.SettingsAdvanceAccountUrlErrorAlertOk, style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true)
    }
    
    func displayNoServiceSetAlert() {
        self.profile.prefs.setBool(false, forKey: PrefsKeys.KeyUseCustomSyncService)
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: UITableViewRowAnimation.automatic)
        }
        let alertController = UIAlertController(title: Strings.SettingsAdvanceAccountUrlErrorAlertTitle, message: Strings.SettingsAdvanceAccountEmptyUrlErrorAlertMessage, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: Strings.SettingsAdvanceAccountUrlUpdatedAlertOk, style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true)
    }

    override func generateSettings() -> [SettingSection] {
        let prefs = profile.prefs
        let customSyncSetting = CustomSyncWebPageSetting(prefs: prefs,
                                                         prefKey: PrefsKeys.KeyCustomSyncWeb,
                                                         placeholder: Strings.SettingsAdvanceAccountUrlPlaceholder,
                                                         accessibilityIdentifier: "CustomSyncSetting",
                                                         settingDidChange: { fieldText in
                                                            self.customSyncUrl = fieldText
                                                            if let customSyncUrl = self.customSyncUrl, customSyncUrl.isEmpty {
                                                                self.clearCustomAccountPrefs()
                                                                return
                                                            }
        })
        
        var basicSettings: [Setting] = []
        basicSettings += [
            CustomSyncEnableSetting(
                prefs: prefs,
                settingDidChange: { result in
                    if result == true {
                        // Reload the table data to ensure that the updated custom url is set
                        self.tableView?.reloadData()
                        self.setCustomAccountPrefs()
                    } 
            }),
            customSyncSetting
        ]
        
        let settings: [SettingSection] = [
            SettingSection(title: NSAttributedString(string: ""), children: basicSettings),
            SettingSection(title: NSAttributedString(string: Strings.SettingsAdvanceAccountSectionFooter), children: [])
        ]

        return settings
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: SectionHeaderIdentifier) as! SettingsTableSectionHeaderFooterView
        let sectionSetting = settings[section]
        headerView.titleLabel.text = sectionSetting.title?.string
        
        switch section {
        // Hide the bottom border for the FxA custom server notes.
        case 1:
            headerView.titleAlignment = .top
            headerView.titleLabel.numberOfLines = 0
            headerView.showBottomBorder = false
        default:
            return super.tableView(tableView, viewForHeaderInSection: section)
        }
        return headerView
    }
}

class CustomSyncEnableSetting: BoolSetting {
    init(prefs: Prefs, settingDidChange: ((Bool?) -> Void)? = nil) {
        super.init(
            prefs: prefs, prefKey: PrefsKeys.KeyUseCustomSyncService, defaultValue: false,
            attributedTitleText: NSAttributedString(string: Strings.SettingsAdvanceAccountUseCustomAccountsServiceTitle),
            settingDidChange: settingDidChange
        )
    }
}

class CustomSyncWebPageSetting: WebPageSetting {
    override init(prefs: Prefs, prefKey: String, defaultValue: String? = nil, placeholder: String, accessibilityIdentifier: String, settingDidChange: ((String?) -> Void)? = nil) {
        super.init(prefs: prefs,
                   prefKey: prefKey,
                   defaultValue: defaultValue,
                   placeholder: placeholder,
                   accessibilityIdentifier: accessibilityIdentifier,
                   settingDidChange: settingDidChange)
        textField.clearButtonMode = UITextFieldViewMode.always
    }
}
