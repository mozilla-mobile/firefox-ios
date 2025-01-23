// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

// MARK: - AddressAutofillSetting
class AddressAutofillSetting: Setting {
    // MARK: Properties

    // Delegate for handling privacy settings interactions
    private weak var settingsDelegate: PrivacySettingsDelegate?

    // User profile associated with the address autofill setting
    private let profile: Profile

    // MARK: Computed Properties

    /// The accessory view for the setting, indicating it has additional details.
    override var accessoryView: UIImageView? {
        guard let theme else { return nil }
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    /// Accessibility identifier for UI testing purposes.
    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Address.title
    }

    // MARK: Initializers

    /// Initialize the AddressAutofillSetting.
    /// - Parameters:
    ///   - theme: The theme used for styling the setting.
    ///   - profile: The user profile associated with the address autofill setting.
    ///   - settingsDelegate: The delegate for handling privacy settings interactions.
    init(theme: Theme,
         profile: Profile,
         settingsDelegate: PrivacySettingsDelegate?) {
        self.profile = profile
        self.settingsDelegate = settingsDelegate
        super.init(
            title: NSAttributedString(
                string: .SettingsAddressAutofill,
                attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
            )
        )
    }

    // MARK: Action

    /// Triggered when the setting is clicked.
    /// - Parameter navigationController: The navigation controller, if applicable.
    override func onClick(_ navigationController: UINavigationController?) {
        settingsDelegate?.pressedAddressAutofill()
    }
}
