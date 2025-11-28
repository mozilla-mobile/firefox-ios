// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import struct MozillaAppServices.CreditCard

protocol CreditCardProvider {
    func addCreditCard(
        creditCard: UnencryptedCreditCardFields,
        completion: @escaping @Sendable (CreditCard?, Error?) -> Void
    )
    func decryptCreditCardNumber(encryptedCCNum: String?) -> String?
    func deleteCreditCard(id: String, completion: @escaping @Sendable (Bool, Error?) -> Void)
    func listCreditCards(completion: @escaping @Sendable ([CreditCard]?, Error?) -> Void)
    func updateCreditCard(
        id: String,
        creditCard: UnencryptedCreditCardFields,
        completion: @escaping @Sendable (Bool?, Error?) -> Void
    )
    func verifyCreditCards(key: String, completionHandler: @escaping @Sendable (Bool) -> Void)
}

extension RustAutofill: CreditCardProvider {}
