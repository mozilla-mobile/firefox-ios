// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class ThemeSetting: Setting {
    private weak var settingsDelegate: GeneralSettingsDelegate?
    private let profile: Profile
    private let themeManager: ThemeManager
    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }
    override var style: UITableViewCell.CellStyle { return .value1 }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Theme.title
    }

    override var status: NSAttributedString {
        if themeManager.isSystemThemeOn() {
            return NSAttributedString(string: .SystemThemeSectionHeader)
        } else if !themeManager.isAutomaticBrightnessOn() {
            return NSAttributedString(string: .DisplayThemeManualStatusLabel)
        } else if themeManager.isAutomaticBrightnessOn() {
            return NSAttributedString(string: .DisplayThemeAutomaticStatusLabel)
        }
        return NSAttributedString(string: "")
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: GeneralSettingsDelegate?) {
        self.profile = settings.profile
        self.themeManager = settings.themeManager
        self.settingsDelegate = settingsDelegate
        super.init(title: NSAttributedString(string: .SettingsDisplayThemeTitle,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedTheme()
    }
}
