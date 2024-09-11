// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum CreditCardType: String, Equatable, CaseIterable {
    case visa = "VISA"
    case mastercard = "MASTERCARD"
    case amex = "AMEX"
    case diners = "DINERS"
    case jcb = "JCB"
    case discover = "DISCOVER"
    case mir = "MIR"
    case unionpay = "UNIONPAY"

    var imageName: String? {
        switch self {
        case .visa:
            return ImageIdentifiers.logoVisa
        case .mastercard:
            return ImageIdentifiers.logoMastercard
        case .amex:
            return ImageIdentifiers.logoAmex
        case .diners:
            return ImageIdentifiers.logoDiners
        case .jcb:
            return ImageIdentifiers.logoJcb
        case .discover:
            return ImageIdentifiers.logoDiscover
        case .mir:
            return ImageIdentifiers.logoMir
        case .unionpay:
            return ImageIdentifiers.logoUnionpay
        }
    }

    var validNumberLength: IndexSet {
        switch self {
        case .visa:
            return IndexSet([13, 16])
        case .amex:
            return IndexSet(integer: 15)
        case .diners:
            return IndexSet(integersIn: 14...19)
        case .jcb, .discover, .unionpay, .mir:
            return IndexSet(integersIn: 16...19)
        default:
            return IndexSet(integer: 16)
        }
    }
}

struct CreditCardValidator {
    let regEx: [CreditCardType: String] = [
        .visa: "^4[0-9]{6,}$",
        .mastercard: "^(?:5[1-5][0-9]{2}|222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}$",
        .amex: "^3[47][0-9]{5,}$",
        .diners: "^3(?:0[0-5]|[68][0-9])[0-9]{4,}$",
        .jcb: "^(?:2131|1800|35[0-9]{3})[0-9]{3,}$",
        .discover: "^6(?:011|5[0-9]{2})[0-9]{3,}$",
        .mir: "^2[0-9]{6,}$",
        .unionpay: "^62[0-5]\\d{13,16}$"
    ]

    func cardTypeFor(_ card: String) -> CreditCardType? {
        let val = regEx.first { _, regex in
            let result = "\(card)".range(of: regex, options: .regularExpression)
            return (result != nil)
        }
        return val?.key
    }

    func isCardNumberValidFor(card: String) -> Bool {
        guard let cardType = cardTypeFor(card) else { return false }

        return cardType.validNumberLength.contains(String(card).count)
    }

    func isExpirationValidFor(date: String) -> Bool {
        guard date.count == 4,
              let inputMonth = Int(date.prefix(2)),
              let inputYear = Int(date.suffix(2)),
              let currentYear = Calendar(identifier: .gregorian).dateComponents([.year], from: Date()).year,
              inputMonth < 13 && inputMonth > 0,
              (inputYear + 2000) < currentYear + 100 && (inputYear + 2000) >= currentYear else {
            return false
        }

        var userInputtedDate = DateComponents()
        userInputtedDate.year = inputYear + 2000
        userInputtedDate.month = inputMonth
        let userCalendar = Calendar(identifier: .gregorian)

        guard let userCardExpirationDate = userCalendar.date(from: userInputtedDate),
              userCardExpirationDate >= Date() else {
            return false
        }

        return true
    }
}
