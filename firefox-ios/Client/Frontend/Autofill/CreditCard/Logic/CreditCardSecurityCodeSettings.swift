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
/// "Save Security Codes" on. Turning it off never deletes codes that are already stored, it only hides
/// them and stops new ones from being saved.
struct CreditCardSecurityCodeSettings: Sendable {
    private let featureFlagsProvider: FeatureFlagProviding
    private let userDefaults: UserDefaultsInterface
    private let telemetry: SettingsTelemetry

    init(featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
         userDefaults: UserDefaultsInterface = UserDefaults.standard,
         telemetry: SettingsTelemetry = SettingsTelemetry()) {
        self.featureFlagsProvider = featureFlagsProvider
        self.userDefaults = userDefaults
        self.telemetry = telemetry
    }

    /// Whether the security code feature, and with it the "Save Security Codes" toggle, is available.
    var isFeatureEnabled: Bool {
        return featureFlagsProvider.isEnabled(.creditCardSecurityCode)
    }

    /// The user's "Save Security Codes" choice. Defaults to on.
    var isSaveSecurityCodesEnabled: Bool {
        return userDefaults.object(forKey: PrefsKeys.KeyAutofillCreditCardSecurityCodeStatus) as? Bool ?? true
    }

    /// Whether security codes should be saved, autofilled and shown.
    var isSecurityCodeEnabled: Bool {
        return isFeatureEnabled && isSaveSecurityCodesEnabled
    }

    /// Persists the user's "Save Security Codes" choice and records the standard `settings.changed` event,
    /// the same one `BoolSetting` toggles record.
    func setSaveSecurityCodesEnabled(_ isEnabled: Bool) {
        userDefaults.set(isEnabled, forKey: PrefsKeys.KeyAutofillCreditCardSecurityCodeStatus)
        telemetry.changedSetting(PrefsKeys.KeyAutofillCreditCardSecurityCodeStatus,
                                 to: "\(isEnabled)",
                                 from: "\(!isEnabled)")
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
