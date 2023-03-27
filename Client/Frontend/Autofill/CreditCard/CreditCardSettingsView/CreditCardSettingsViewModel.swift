// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import UIKit

enum CreditCardSettingsState: String, Equatable, CaseIterable {
    // Default state
    case empty = "Empty"
    case add = "Add"
    case edit = "Edit"
    case view = "View"
    case list = "List"
}

struct CreditCardSettingsStartingConfig {
    var actionToPerform: CreditCardSettingsState?
    var creditCard: CreditCard?
}

class CreditCardSettingsViewModel {
    var autofill: RustAutofill?
    var profile: Profile
    var appAuthenticator: AppAuthenticationProtocol?

    lazy var addEditViewModel: CreditCardEditViewModel = CreditCardEditViewModel(profile: profile)
    var creditCardTableViewModel: CreditCardTableViewModel = CreditCardTableViewModel()
    var toggleModel: ToggleModel!

    public init(profile: Profile,
                appAuthenticator: AppAuthenticationProtocol = AppAuthenticator()
    ) {
        self.profile = profile
        guard let profile = profile as? BrowserProfile else { return }
        self.autofill = profile.autofill
        self.appAuthenticator = appAuthenticator
        self.toggleModel = ToggleModel(isEnabled: isAutofillEnabled, delegate: self)
        creditCardTableViewModel.toggleModel = toggleModel
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
            UserDefaults.standard.set(newValue, forKey: PrefsKeys.KeyAutofillCreditCardStatus)
        }
    }

    func listCreditCard(_ completionHandler: @escaping ([CreditCard]?) -> Void) {
        autofill?.listCreditCards(completion: { creditCards, error in
            guard error == nil else {
                completionHandler(nil)
                return
            }
            completionHandler(creditCards)
        })
    }

    func updateCreditCardsList(creditCards: [CreditCard]) {
        DispatchQueue.main.async { [weak self] in
            self?.creditCardTableViewModel.creditCards = creditCards
        }
    }
}

extension CreditCardSettingsViewModel: ToggleModelDelegate {
    func toggleDidChange(_ toggleModel: ToggleModel) {
        isAutofillEnabled = toggleModel.isEnabled
    }
}
