// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

class CreditCardEditViewModel: ObservableObject {
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

    init() {}

    init(firstName: String,
         lastName: String,
         errorState: String,
         enteredValue: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.errorState = errorState
        self.enteredValue = enteredValue
    }
}
