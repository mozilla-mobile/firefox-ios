// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// Shown only when debug menu is active
class AdvancedAccountSetting: HiddenSetting {
    private weak var settingsDelegate: AccountSettingsDelegate?
    private let profile: Profile?
    private let isHidden: Bool

    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.AdvancedAccountSettings.title
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: .SettingsAdvancedAccountTitle,
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    init(settings: SettingsTableViewController,
         isHidden: Bool,
         settingsDelegate: AccountSettingsDelegate?) {
        self.profile = settings.profile
        self.isHidden = isHidden
        self.settingsDelegate = settingsDelegate
        super.init(settings: settings)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedAdvancedAccountSetting()
    }

    override var hidden: Bool {
        return !isHidden || (profile?.hasAccount() ?? false)
    }
}
