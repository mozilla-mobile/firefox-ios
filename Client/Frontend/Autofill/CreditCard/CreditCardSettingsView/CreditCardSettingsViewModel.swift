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
    case list = "List"
}

struct CreditCardSettingsStartingConfig {
    var actionToPerform: CreditCardSettingsState?
    var creditCard: CreditCard?
}

class CreditCardSettingsViewModel {
    var autofill: RustAutofill?
    var profile: Profile
    var addEditViewModel: CreditCardEditViewModel = CreditCardEditViewModel()
    var creditCardTableViewModel: CreditCardTableViewModel = CreditCardTableViewModel()

    public init(profile: Profile) {
        self.profile = profile
        guard let profile = profile as? BrowserProfile else { return }
        self.autofill = profile.autofill
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
