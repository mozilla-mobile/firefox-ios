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
    
    fileprivate var customSyncUrl: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.SettingsAdvanceAccountSectionName
    }
    
    func clearCustomSyncPrefs() {
        self.profile.prefs.setBool(false, forKey: PrefsKeys.KeyUseCustomSyncService)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncToken)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncProfile)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncOauth)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncAuth)
        self.profile.prefs.setString("", forKey: PrefsKeys.KeyCustomSyncWeb)
        self.profile.removeAccount()
    }
    
    func setCustomSyncPrefs(_ data: Data, url: URL) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            self.profile.prefs.setBool(true, forKey: PrefsKeys.KeyUseCustomSyncService)
            self.profile.prefs.setString(json["sync_tokenserver_base_url"] as! String, forKey: PrefsKeys.KeyCustomSyncToken)
            self.profile.prefs.setString(json["profile_server_base_url"] as! String, forKey: PrefsKeys.KeyCustomSyncProfile)
            self.profile.prefs.setString(json["oauth_server_base_url"] as! String, forKey: PrefsKeys.KeyCustomSyncOauth)
            self.profile.prefs.setString(json["auth_server_base_url"] as! String, forKey: PrefsKeys.KeyCustomSyncAuth)
            self.profile.prefs.setString(url.absoluteString, forKey: PrefsKeys.KeyCustomSyncWeb)
            
            self.profile.removeAccount()
            
            let alertController = UIAlertController(title: "", message: Strings.SettingsAdvanceAccountUrlUpdatedAlertMessage, preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: Strings.SettingsAdvanceAccountUrlUpdatedAlertOk, style: .default, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true)
        } catch let error as NSError {
            print(error)
        }
    }
    
    func setCustomAccountPrefs(_ url: URL?) {
        guard let url = url else {
            self.clearCustomSyncPrefs()
            return
        }
        
        let syncConfigureString = url.absoluteString + "/.well-known/fxa-client-configuration"
        let syncConfigureURL = URL(string: syncConfigureString)!
        
        URLSession.shared.dataTask(with:syncConfigureURL, completionHandler: {(data, response, error) in
            guard let data = data, error == nil else {
                let alertController = UIAlertController(title: Strings.SettingsAdvanceAccountUrlErrorAlertTitle, message: Strings.SettingsAdvanceAccountUrlErrorAlertMessage, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: Strings.SettingsAdvanceAccountUrlErrorAlertOk, style: .default, handler: nil)
                alertController.addAction(defaultAction)
                
                self.present(alertController, animated: true)
                return
            }
            
            self.setCustomSyncPrefs(data, url: url)
        }).resume()
    }
    
    override func generateSettings() -> [SettingSection] {
        let prefs = profile.prefs
        
        func setCustomAccountUrl(_ url: URL?) -> ((UINavigationController?) -> Void) {
            weak var tableView: UITableView? = self.tableView
            return { nav in
                self.setCustomAccountPrefs(URLFromString(self.customSyncUrl))
                tableView?.reloadData()
            }
        }
        
        func URLFromString(_ string: String?) -> URL? {
            guard let string = string else {
                return nil
            }
            return URL(string: string)
        }
        
        let customSyncSetting = CustomSyncWebPageSetting(prefs: prefs,
                                                         prefKey: PrefsKeys.KeyCustomSyncWeb,
                                                         placeholder: Strings.SettingsAdvanceAccountUrlPlaceholder,
                                                         accessibilityIdentifier: "CustomSyncSetting",
                                                         settingDidChange: {fieldText in
                                                            self.customSyncUrl = fieldText
        })
        
        var basicSettings: [Setting] = []
        
        basicSettings += [
            customSyncSetting,
            ButtonSetting(title: NSAttributedString(string: "Set"),
                          destructive: false,
                          accessibilityIdentifier: "ClearHomePage",
                          onClick: setCustomAccountUrl(nil)),
        ]
        
        let settings: [SettingSection] = [SettingSection(title: NSAttributedString(string: ""), children: basicSettings)]
        
        return settings
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
