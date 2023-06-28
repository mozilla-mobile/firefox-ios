// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class SiriPageSetting: Setting {
    private weak var settingsDelegate: GeneralSettingsDelegate?
    private let profile: Profile

    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Siri.title
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: GeneralSettingsDelegate?) {
        self.profile = settings.profile
        self.settingsDelegate = settingsDelegate

        super.init(title: NSAttributedString(string: .SettingsSiriSectionName,
                                             attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.pressedSiri()
        } else {
            let viewController = SiriSettingsViewController(prefs: profile.prefs)
            viewController.profile = profile
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
