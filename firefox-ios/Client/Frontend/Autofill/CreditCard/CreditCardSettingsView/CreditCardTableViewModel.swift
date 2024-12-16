// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import SwiftUI
import Shared

import struct MozillaAppServices.CreditCard

class CreditCardTableViewModel {
    var toggleModel: ToggleModel?

    var creditCards = [CreditCard]() {
        didSet {
            didUpdateCreditCards?()
        }
    }

    var didUpdateCreditCards: (() -> Void)?

    func a11yLabel(for indexPath: IndexPath) -> NSAttributedString {
        guard indexPath.section == 1 else { return NSAttributedString() }

        let creditCard = creditCards[indexPath.row]

        let localizedDate = localizedDate(year: Int(creditCard.ccExpYear), month: Int(creditCard.ccExpMonth)) ?? ""
        let string = String(format: .CreditCard.Settings.ListItemA11y,
                            creditCard.ccType,
                            creditCard.ccName,
                            creditCard.ccNumberLast4,
                            localizedDate)
        let attributedString = NSMutableAttributedString(string: string)
        if let range = attributedString.string.range(of: creditCard.ccNumberLast4) {
            attributedString.addAttributes([.accessibilitySpeechSpellOut: true],
                                           range: NSRange(range, in: attributedString.string))
        }

        return attributedString
    }

    func localizedDate(year: Int, month: Int) -> String? {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1

        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: dateComponents) else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: date)
    }
}
