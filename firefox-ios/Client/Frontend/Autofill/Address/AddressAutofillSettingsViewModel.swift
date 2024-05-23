// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage

// MARK: - AddressAutofillSettingsViewModel

/// View model for managing address autofill settings.
class AddressAutofillSettingsViewModel {
    // MARK: Properties

    /// Model for managing the state of the address autofill toggle.
    lazy var toggleModel = ToggleModel(isEnabled: isAutofillEnabled, delegate: self)

    /// ViewModel for managing the list of addresses.
    lazy var addressListViewModel = AddressListViewModel(addressProvider: profile.autofill)

    /// RustAutofill instance for handling autofill functionality.
    var autofill: RustAutofill?

    /// Profile associated with the address autofill settings.
    var profile: Profile

    /// Boolean indicating whether autofill is currently enabled.
    var isAutofillEnabled: Bool {
        get {
            let userDefaults = UserDefaults.standard
            let key = PrefsKeys.KeyAutofillAddressStatus
            guard userDefaults.value(forKey: key) != nil else {
                // Default value is true for address autofill input
                return true
            }

            return userDefaults.bool(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: PrefsKeys.KeyAutofillAddressStatus)
        }
    }

    // MARK: Initializer

    /// Initializes the AddressAutofillSettingsViewModel.
    /// - Parameter profile: The profile associated with the address autofill settings.
    init(profile: Profile) {
        self.profile = profile
        guard let browserProfile = profile as? BrowserProfile else { return }
        self.autofill = browserProfile.autofill
    }
}

// MARK: - ToggleModelDelegate

extension AddressAutofillSettingsViewModel: ToggleModelDelegate {
    /// Called when the state of the address autofill toggle changes.
    /// - Parameter toggleModel: The toggle model whose state changed.
    func toggleDidChange(_ toggleModel: ToggleModel) {
        isAutofillEnabled = toggleModel.isEnabled
    }
}
