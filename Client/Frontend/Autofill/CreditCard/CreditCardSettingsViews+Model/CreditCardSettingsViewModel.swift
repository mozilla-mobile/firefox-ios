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
    var subCardListViewModel: CreditCardListViewModel = CreditCardListViewModel()
    var subCardAddEditViewModel: CreditCardEditViewModel = CreditCardEditViewModel()

    public init(profile: Profile) {
        self.profile = profile
        guard let profile = profile as? BrowserProfile else { return }
        self.autofill = profile.autofill
        setupListViewModel()
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

    func setupListViewModel() {
        autofill?.listCreditCards(completion: { creditCards, err in
            guard err == nil, let creditCards = creditCards else {
                return
            }

            self.subCardListViewModel.creditCards = creditCards
        })
    }

//    func injectDummyData() {
//        let cardList: [UnencryptedCreditCardFields] = [
//            UnencryptedCreditCardFields(ccName: "Allen Burges", ccNumber: "1234567891234567", ccNumberLast4: "4567", ccExpMonth: 8, ccExpYear: 2023, ccType: "VISA"),
//
//            UnencryptedCreditCardFields(ccName: "Macky Otter", ccNumber: "0987654323456789", ccNumberLast4: "6789", ccExpMonth: 9, ccExpYear: 2023, ccType: "MASTERCARD")
//        ]
//
//        cardList.forEach { card in
//            autofill?.addCreditCard(creditCard: card, completion: { _,_ in
//                self.setupListViewModel()
//            })
//        }
//    }
}
