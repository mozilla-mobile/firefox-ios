// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import struct MozillaAppServices.CreditCard

// Note: This was created in lieu of a view model
public struct UnencryptedCreditCardFields {
    public var ccName: String = ""
    public var ccNumber: String = ""
    public var ccNumberLast4: String = ""
    public var ccExpMonth: Int64 = 0
    public var ccExpYear: Int64 = 0
    public var ccType: String = ""

    public init() { }

    public init(ccName: String,
                ccNumber: String,
                ccNumberLast4: String,
                ccExpMonth: Int64,
                ccExpYear: Int64,
                ccType: String) {
        self.ccName = ccName
        self.ccNumber = ccNumber
        self.ccNumberLast4 = ccNumberLast4
        self.ccExpMonth = ccExpMonth
        self.ccExpYear = ccExpYear
        self.ccType = ccType
    }

    public func convertToTempCreditCard() -> CreditCard {
        let convertedCreditCard = CreditCard(guid: "",
                                             ccName: self.ccName,
                                             ccNumberEnc: "",
                                             ccNumberLast4: self.ccNumberLast4,
                                             ccExpMonth: self.ccExpMonth,
                                             ccExpYear: self.ccExpYear,
                                             ccType: self.ccType,
                                             timeCreated: Int64(Date().timeIntervalSince1970),
                                             timeLastUsed: nil,
                                             timeLastModified: Int64(Date().timeIntervalSince1970),
                                             timesUsed: 0)
        return convertedCreditCard
    }

    public func isEqualToCreditCard(creditCard: CreditCard) -> Bool {
        return creditCard.ccExpMonth == ccExpMonth &&
        creditCard.ccExpYear == ccExpYear &&
        creditCard.ccName == ccName &&
        creditCard.ccNumberLast4 == ccNumberLast4
    }
}
