// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import SwiftUI
import Storage
import Shared

class CreditCardTableViewModel {
    var creditCards: [CreditCard] = [CreditCard]() {
        didSet {
            didUpdateCreditCards?()
        }
    }

    var didUpdateCreditCards: (() -> Void)?

    var isAutofillEnabled: Bool {
        get {
            let userdefaults = UserDefaults.standard
            let key = PrefsKeys.KeyAutofillCreditCardStatus
            guard userdefaults.value(forKey: key) != nil else {
                // Default value is true for autofill credit card input
                return true
            }

            return userdefaults.bool(forKey: key)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: PrefsKeys.KeyAutofillCreditCardStatus)
        }
    }

    func updateToggle() {
        isAutofillEnabled = !isAutofillEnabled
    }
}
