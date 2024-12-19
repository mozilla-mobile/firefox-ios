// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class ClearPrivateDataSetting: Setting {
    private let profile: Profile
    private var tabManager: TabManager?
    private weak var settingsDelegate: PrivacySettingsDelegate?

    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? { return AccessibilityIdentifiers.Settings.ClearData.title }

    init(settings: SettingsTableViewController,
         settingsDelegate: PrivacySettingsDelegate?) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        self.settingsDelegate = settingsDelegate

        let clearTitle: String = .SettingsDataManagementSectionName
        let theme = settings.themeManager.getCurrentTheme(for: settings.windowUUID)
        super.init(
            title: NSAttributedString(
                string: clearTitle,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textPrimary
                ]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedClearPrivateData()
    }
}
