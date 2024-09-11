// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class AutofillCreditCardSettings: Setting, FeatureFlaggable {
    private weak var settingsDelegate: PrivacySettingsDelegate?
    private let profile: Profile
    weak var settings: AppSettingsTableViewController?

    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.CreditCard.title
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: PrivacySettingsDelegate?) {
        self.profile = settings.profile
        self.settings = settings as? AppSettingsTableViewController
        self.settingsDelegate = settingsDelegate

        let theme = settings.themeManager.getCurrentTheme(for: settings.windowUUID)
        super.init(
            title: NSAttributedString(
                string: .SettingsAutofillCreditCard,
                attributes: [
                    NSAttributedString.Key.foregroundColor: theme.colors.textPrimary
                ]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardAutofillSettings)
        settingsDelegate?.pressedCreditCard()
    }
}
