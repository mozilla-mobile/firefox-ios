// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import SwiftUI
import Storage
import Shared

class CreditCardTableViewModel {
    var toggleModel: ToggleModel?

    var creditCards: [CreditCard] = [CreditCard]() {
        didSet {
            didUpdateCreditCards?()
        }
    }

    var didUpdateCreditCards: (() -> Void)?

    func a11yLabel(for indexPath: IndexPath) -> NSAttributedString {
        guard indexPath.section == 1 else { return NSAttributedString() }

        let creditCard = creditCards[indexPath.row]

        let components = DateComponents(year: Int(creditCard.ccExpYear), month: Int(creditCard.ccExpMonth))
        let formattedExpiryDate = DateComponentsFormatter.localizedString(from: components,
                                                                          unitsStyle: .spellOut) ?? ""

        let string = String(format: .CreditCard.Settings.ListItemA11y,
                            creditCard.ccType,
                            creditCard.ccNumberLast4,
                            creditCard.ccName,
                            formattedExpiryDate)
        let attributedString = NSMutableAttributedString(string: string)
        if let range = attributedString.string.range(of: creditCard.ccNumberLast4) {
            attributedString.addAttributes([.accessibilitySpeechSpellOut: true],
                                           range: NSRange(range, in: attributedString.string))
        }

        return attributedString
    }
}
