// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage

/// Decides whether credit card security codes (CVV) are saved, autofilled and shown in settings.
///
/// Security codes are only used when the `creditCardSecurityCode` feature is enabled and the user kept
/// "Save security codes" on. Turning it off never deletes codes that are already stored, it only hides
/// them and stops new ones from being saved.
struct CreditCardSecurityCodeSettings: Sendable {
    private let featureFlagsProvider: FeatureFlagProviding
    private let userDefaults: UserDefaultsInterface

    init(featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
         userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.featureFlagsProvider = featureFlagsProvider
        self.userDefaults = userDefaults
    }

    /// Whether the security code feature, and with it the "Save security codes" toggle, is available.
    var isFeatureEnabled: Bool {
        return featureFlagsProvider.isEnabled(.creditCardSecurityCode)
    }

    /// The user's "Save security codes" choice. Defaults to on.
    var isSaveSecurityCodesEnabled: Bool {
        return userDefaults.object(forKey: PrefsKeys.KeyAutofillCreditCardSecurityCodeStatus) as? Bool ?? true
    }

    /// Whether security codes should be saved, autofilled and shown.
    var isSecurityCodeEnabled: Bool {
        return isFeatureEnabled && isSaveSecurityCodesEnabled
    }

    func setSaveSecurityCodesEnabled(_ isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: PrefsKeys.KeyAutofillCreditCardSecurityCodeStatus)
    }

    /// Returns `card` without its security code when security codes are disabled. A `nil` code keeps the
    /// stored one untouched on update, so previously saved codes survive.
    func applying(to card: UnencryptedCreditCardFields) -> UnencryptedCreditCardFields {
        guard !isSecurityCodeEnabled else { return card }
        var card = card
        card.ccCvv = nil
        return card
    }
}
