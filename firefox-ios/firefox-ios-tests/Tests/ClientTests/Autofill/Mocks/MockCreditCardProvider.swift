// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Storage

class MockCreditCardProvider: CreditCardProvider {
    var addCreditCardCalledCount = 0
    var updateCreditCardCalledCount = 0
    var listCreditCardsCalledCount = 0
    var deleteCreditCardsCalledCount = 0
    var verifyCreditCardsCalled = 0
    var creditCardsVerified = true

    var exampleCreditCard = CreditCard(
        guid: "1",
        ccName: "Allen Burges",
        ccNumberEnc: "4111111111111111",
        ccNumberLast4: "1111",
        ccExpMonth: 3,
        ccExpYear: 2043,
        ccType: "VISA",
        timeCreated: 1234678,
        timeLastUsed: nil,
        timeLastModified: 123123,
        timesUsed: 123123
    )

    private(set) var lastDeletedID: String?
    var deleteResult: (status: Bool, error: Error?) = (false, nil)
    var updateResult: (status: Bool?, error: Error?) = (nil, nil)

    func addCreditCard(
        creditCard: UnencryptedCreditCardFields,
        completion: @escaping (CreditCard?, Error?) -> Void
    ) {
        addCreditCardCalledCount += 1
        completion(exampleCreditCard, nil)
    }
    func decryptCreditCardNumber(encryptedCCNum: String?) -> String? { return "testCCNum" }
    func deleteCreditCard(id: String, completion: @escaping @Sendable (Bool, (any Error)?) -> Void) {
        deleteCreditCardsCalledCount += 1
        lastDeletedID = id
        completion(deleteResult.status, deleteResult.error)
    }
    func listCreditCards(completion: @escaping ([CreditCard]?, Error?) -> Void) {
        listCreditCardsCalledCount += 1
        completion([exampleCreditCard], nil)
    }
    func updateCreditCard(
        id: String,
        creditCard: UnencryptedCreditCardFields,
        completion: @escaping (Bool?, Error?) -> Void
    ) {
        updateCreditCardCalledCount += 1
        completion(updateResult.status, updateResult.error)
    }

    func verifyCreditCards(key: String, completionHandler: @escaping @Sendable (Bool) -> Void) {
        verifyCreditCardsCalled += 1
        completionHandler(creditCardsVerified)
    }
}
