// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import UIKit
import Common

import struct MozillaAppServices.CreditCard

enum CreditCardSettingsState: String, Equatable, CaseIterable {
    // Default state
    case empty = "Empty"
    case add = "Add"
    case view = "View"
    case list = "List"
}

class CreditCardSettingsViewModel {
    var autofill: RustAutofill?
    var profile: Profile
    let windowUUID: WindowUUID
    var appAuthenticator: AppAuthenticationProtocol?

    lazy var cardInputViewModel = CreditCardInputViewModel(profile: profile)
    lazy var toggleModel = ToggleModel(isEnabled: isAutofillEnabled, delegate: self)
    var tableViewModel = CreditCardTableViewModel()

    public init(profile: Profile,
                windowUUID: WindowUUID,
                appAuthenticator: AppAuthenticationProtocol = AppAuthenticator()
    ) {
        self.profile = profile
        self.windowUUID = windowUUID
        guard let profile = profile as? BrowserProfile else { return }
        self.autofill = profile.autofill
        self.appAuthenticator = appAuthenticator

        tableViewModel.toggleModel = toggleModel
    }

    var isAutofillEnabled: Bool {
        get {
            let userDefaults = UserDefaults.standard
            let key = PrefsKeys.KeyAutofillCreditCardStatus
            guard userDefaults.value(forKey: key) != nil else {
                // Default value is true for autofill credit card input
                return true
            }

            return userDefaults.bool(forKey: key)
        }
        set {
            // Telemetry for card autofill
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .tap,
                object: .creditCardAutofillToggle,
                extras: [
                    TelemetryWrapper.ExtraKey.isCreditCardAutofillToggleEnabled.rawValue: newValue
                ]
            )

            UserDefaults.standard.set(newValue, forKey: PrefsKeys.KeyAutofillCreditCardStatus)
        }
    }

    func getCreditCardList(_ completionHandler: @escaping ([CreditCard]?) -> Void) {
        autofill?.listCreditCards(completion: { creditCards, error in
            guard let cards = creditCards,
                  error == nil else {
                completionHandler(nil)
                return
            }
            self.updateCreditCardsList(creditCards: cards)
            completionHandler(creditCards)
        })
    }

    private func updateCreditCardsList(creditCards: [CreditCard]) {
        DispatchQueue.main.async { [weak self] in
            self?.tableViewModel.creditCards = creditCards
        }
    }
}

extension CreditCardSettingsViewModel: ToggleModelDelegate {
    func toggleDidChange(_ toggleModel: ToggleModel) {
        isAutofillEnabled = toggleModel.isEnabled
    }
}
