// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import struct MozillaAppServices.CreditCard

protocol CreditCardProvider {
    func addCreditCard(
        creditCard: UnencryptedCreditCardFields,
        completion: @escaping (CreditCard?, Error?) -> Void
    )
    func decryptCreditCardNumber(encryptedCCNum: String?) -> String?
    func listCreditCards(completion: @escaping ([CreditCard]?, Error?) -> Void)
    func updateCreditCard(
        id: String,
        creditCard: UnencryptedCreditCardFields,
        completion: @escaping (Bool?, Error?) -> Void
    )
}

extension RustAutofill: CreditCardProvider {}
