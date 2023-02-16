// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Common

class CreditCardEditViewModel: ObservableObject {
    typealias CreditCardText = String.CreditCard.Alert
    let profile: Profile

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

    var removeButtonDetails: RemoveCardButton.AlertDetails {
        let isSignedIn = profile.hasSyncableAccount()

        if isSignedIn {
            return RemoveCardButton.AlertDetails(
                alertTitle: Text(CreditCardText.RemoveCardTitle),
                alertBody: Text(CreditCardText.RemoveCardSublabel),
                primaryButtonStyleAndText: .destructive(Text(CreditCardText.RemovedCardLabel)),
                secondaryButtonStyleAndText: .cancel(),
                primaryButtonAction: {},
                secondaryButtonAction: {})
        }

        return RemoveCardButton.AlertDetails(
            alertTitle: Text(CreditCardText.RemoveCardTitle),
            alertBody: nil,
            primaryButtonStyleAndText: .destructive(Text(CreditCardText.RemovedCardLabel)),
            secondaryButtonStyleAndText: .cancel(),
            primaryButtonAction: {},
            secondaryButtonAction: {}
        )
    }

    init(profile: Profile) {
        self.profile = profile
    }

    init(profile: Profile = AppContainer.shared.resolve(),
         firstName: String,
         lastName: String,
         errorState: String,
         enteredValue: String) {
        self.profile = profile
        self.firstName = firstName
        self.lastName = lastName
        self.errorState = errorState
        self.enteredValue = enteredValue
    }
}
