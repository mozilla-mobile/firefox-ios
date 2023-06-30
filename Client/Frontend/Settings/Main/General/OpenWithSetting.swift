// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class OpenWithSetting: Setting {
    private weak var settingsDelegate: GeneralSettingsDelegate?
    private let profile: Profile

    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.OpenWithMail.title
    }

    override var status: NSAttributedString {
        guard let provider = self.profile.prefs.stringForKey(PrefsKeys.KeyMailToOption) else {
            return NSAttributedString(string: "")
        }
        if let path = Bundle.main.path(forResource: "MailSchemes", ofType: "plist"),
            let dictRoot = NSArray(contentsOfFile: path) {
            let mailProvider = dictRoot.compactMap({$0 as? NSDictionary }).first { (dict) -> Bool in
                return (dict["scheme"] as? String) == provider
            }
            return NSAttributedString(string: (mailProvider?["name"] as? String) ?? "")
        }
        return NSAttributedString(string: "")
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController,
         settingsDelegate: GeneralSettingsDelegate?) {
        self.profile = settings.profile
        self.settingsDelegate = settingsDelegate

        super.init(title: NSAttributedString(string: .SettingsOpenWithSectionName,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.pressedMailApp()
        } else {
            let viewController = OpenWithSettingsViewController(prefs: profile.prefs)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
