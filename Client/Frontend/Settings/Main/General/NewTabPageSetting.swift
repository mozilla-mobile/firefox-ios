// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class NewTabPageSetting: Setting {
    private let profile: Profile
    private weak var settingsDelegate: GeneralSettingsDelegate?

    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.NewTab.title
    }

    override var status: NSAttributedString {
        return NSAttributedString(string: NewTabAccessors.getNewTabPage(self.profile.prefs).settingTitle)
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController,
         settingsDelegate: GeneralSettingsDelegate?) {
        self.profile = settings.profile
        self.settingsDelegate = settingsDelegate
        super.init(title: NSAttributedString(string: .SettingsNewTabSectionName,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.pressedNewTab()
        } else {
            let viewController = NewTabContentSettingsViewController(prefs: profile.prefs)
            viewController.profile = profile
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
