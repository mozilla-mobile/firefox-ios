// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Common
import Storage

//enum leftBarButtonState: String, Equatable, CaseIterable {
//    case close
//    case cancel
//}
//
//enum rightBarButtonState: String, Equatable, CaseIterable {
//    case save
//    case edit
//}

enum CreditCardEditState: String, Equatable, CaseIterable {
    case add
    case edit
    case view
    
    var title: String {
        switch self {
        case .add:
            return String.CreditCard.EditCard.AddCreditCardTitle
        case .edit, .view:
            return String.CreditCard.EditCard.EditCreditCardTitle
        }
    }
    
    var leftBarTitle: String {
        switch self {
        case .add:
            // close -- save (active / non-active)
            return "close"
        case .edit:
            // cancel -- save (active / non-active)
            return "cancel"
        case .view:
            // close -- edit
            return "close"
        }
    }
    
    var rightBarTitle: String {
        switch self {
        case .add:
            // close -- save (active / non-active)
            return "save"
        case .edit:
            // cancel -- save (active / non-active)
            return "save"
        case .view:
            // close -- edit
            return "edit"
        }
    }
    
}

class CreditCardEditViewModel: ObservableObject {
    typealias CreditCardText = String.CreditCard.Alert

    let profile: Profile
    let autofill: RustAutofill
    let creditCard: CreditCard?
    @Published var state: CreditCardEditState

    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var errorState: String = ""
    @Published var enteredValue: String = ""
    @Published var nameIsValid = true
    @Published var numberIsValid = true
    @Published var expirationIsValid = true
    @Published var nameOnCard: String = "" {
        didSet (val) {
            nameIsValid = nameOnCard.isEmpty
        }
    }

    @Published var expirationDate: String = "" {
        didSet (val) {
            numberIsValid = true
        }
    }

    @Published var cardNumber: String = "" {
        didSet (val) {
            expirationIsValid = true
        }
    }

    var signInRemoveButtonDetails: RemoveCardButton.AlertDetails {
        return RemoveCardButton.AlertDetails(
            alertTitle: Text(CreditCardText.RemoveCardTitle),
            alertBody: Text(CreditCardText.RemoveCardSublabel),
            primaryButtonStyleAndText: .destructive(Text(CreditCardText.RemovedCardLabel)) { [self] in
                guard let creditCard = creditCard else { return }

                removeSelectedCreditCard(creditCard: creditCard)
            },
            secondaryButtonStyleAndText: .cancel(),
            primaryButtonAction: {},
            secondaryButtonAction: {})
    }

    var regularRemoveButtonDetails: RemoveCardButton.AlertDetails {
        return RemoveCardButton.AlertDetails(
            alertTitle: Text(CreditCardText.RemoveCardTitle),
            alertBody: nil,
            primaryButtonStyleAndText: .destructive(Text(CreditCardText.RemovedCardLabel)) { [self] in
                guard let creditCard = creditCard else { return }

                removeSelectedCreditCard(creditCard: creditCard)
            },
            secondaryButtonStyleAndText: .cancel(),
            primaryButtonAction: {},
            secondaryButtonAction: {}
        )
    }

    var removeButtonDetails: RemoveCardButton.AlertDetails {
        return profile.hasSyncableAccount() ? signInRemoveButtonDetails : regularRemoveButtonDetails
    }

    init(profile: Profile,
         creditCard: CreditCard? = nil
    ) {
        self.profile = profile
        self.autofill = profile.autofill
        self.creditCard = creditCard
        self.state = .add
    }

    init(profile: Profile = AppContainer.shared.resolve(),
         firstName: String,
         lastName: String,
         errorState: String,
         enteredValue: String,
         creditCard: CreditCard? = nil,
         state: CreditCardEditState
    ) {
        self.profile = profile
        self.firstName = firstName
        self.lastName = lastName
        self.errorState = errorState
        self.enteredValue = enteredValue
        self.autofill = profile.autofill
        self.creditCard = creditCard
        self.state = state
    }

    // MARK: - Helpers

    private func removeSelectedCreditCard(creditCard: CreditCard) {
        autofill.deleteCreditCard(id: creditCard.guid) { _, error in
            // no-op
        }
    }
}
