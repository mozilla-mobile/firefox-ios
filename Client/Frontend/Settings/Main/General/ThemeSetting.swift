// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ThemeSetting: Setting {
    let profile: Profile
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }
    override var style: UITableViewCell.CellStyle { return .value1 }
    override var accessibilityIdentifier: String? { return "DisplayThemeOption" }

    override var status: NSAttributedString {
        if LegacyThemeManager.instance.systemThemeIsOn {
            return NSAttributedString(string: .SystemThemeSectionHeader)
        } else if !LegacyThemeManager.instance.automaticBrightnessIsOn {
            return NSAttributedString(string: .DisplayThemeManualStatusLabel)
        } else if LegacyThemeManager.instance.automaticBrightnessIsOn {
            return NSAttributedString(string: .DisplayThemeAutomaticStatusLabel)
        }
        return NSAttributedString(string: "")
    }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: .SettingsDisplayThemeTitle,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.pushViewController(ThemeSettingsController(), animated: true)
    }
}
