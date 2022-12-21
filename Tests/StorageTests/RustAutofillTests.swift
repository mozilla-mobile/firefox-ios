// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client
@testable import Storage

class RustAutofillTests: XCTestCase {
    var files: FileAccessor!
    var autofill: RustAutofill!
    var encryptionKey: String!

    override func setUp() {
        files = MockFiles()

        if let rootDirectory = try? files.getAndEnsureDirectory() {
            let databasePath = URL(fileURLWithPath: rootDirectory, isDirectory: true)
                .appendingPathComponent("testAutofill.db").path
            try? files.remove("testAutofill.db")

            if let key = try? createAutofillKey() {
                encryptionKey = key
            } else {
                XCTFail("Encryption key wasn't created")
            }

            autofill = RustAutofill(databasePath: databasePath)
            _ = autofill.reopenIfClosed()
        } else {
            XCTFail("Could not retrieve root directory")
        }
    }
    
    func addCreditCard() -> Deferred<Maybe<CreditCard>> {
        let creditCard = UnencryptedCreditCardFields(
            ccName: "Jane Doe",
            ccNumber: "1234567890123456",
            ccNumberLast4: "3456",
            ccExpMonth: 03,
            ccExpYear: 2027,
            ccType: "Visa")
        return autofill.addCreditCard(creditCard: creditCard)
    }
    
    func testAddCreditCard() {
        let addResult = addCreditCard().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let getResult = autofill.getCreditCard(id: addResult.successValue!.guid).value
        XCTAssertTrue(getResult.isSuccess)
        XCTAssertNotNil(getResult.successValue!)
        XCTAssertEqual(getResult.successValue!!.guid, addResult.successValue!.guid)
    }
    
    func testListCreditCards() {
        let listResult1 = autofill.listCreditCards().value
        XCTAssertTrue(listResult1.isSuccess)
        XCTAssertNotNil(listResult1.successValue)
        XCTAssertEqual(listResult1.successValue!.count, 0)
        let addResult = addCreditCard().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let listResult2 = autofill.listCreditCards().value
        XCTAssertTrue(listResult2.isSuccess)
        XCTAssertNotNil(listResult2.successValue)
        XCTAssertEqual(listResult2.successValue!.count, 1)
    }
    
    func testUpdateCreditCard() {
        let addResult = addCreditCard().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let getResult1 = autofill.getCreditCard(id: addResult.successValue!.guid).value
        XCTAssertTrue(getResult1.isSuccess)
        XCTAssertNotNil(getResult1.successValue!)
        let creditCard = getResult1.successValue!
        XCTAssertEqual(creditCard!.guid, addResult.successValue!.guid)

        let expectedCcExpYear = Int64(2028)
        let updatedCreditCard = UnencryptedCreditCardFields(
            ccName: creditCard!.ccName,
            ccNumber: creditCard!.ccNumberEnc,
            ccNumberLast4: creditCard!.ccNumberLast4,
            ccExpMonth: creditCard!.ccExpMonth,
            ccExpYear: expectedCcExpYear,
            ccType: creditCard!.ccType)

        let updateResult = autofill.updateCreditCard(id: creditCard!.guid,
                                                     creditCard: updatedCreditCard).value
        XCTAssertTrue(updateResult.isSuccess)
        let getResult2 = autofill.getCreditCard(id: creditCard!.guid).value
        XCTAssertTrue(getResult2.isSuccess)
        XCTAssertNotNil(getResult2.successValue!)
        let actualCcExpYear = getResult2.successValue!!.ccExpYear
        XCTAssertEqual(expectedCcExpYear, actualCcExpYear)
    }
    
    func testDeleteCreditCard() {
        let addResult = addCreditCard().value
        XCTAssertTrue(addResult.isSuccess)
        XCTAssertNotNil(addResult.successValue)
        let getResult1 = autofill.getCreditCard(id: addResult.successValue!.guid).value
        XCTAssertTrue(getResult1.isSuccess)
        XCTAssertNotNil(getResult1.successValue!)
        let creditCard = getResult1.successValue!
        XCTAssertEqual(creditCard!.guid, addResult.successValue!.guid)
        let deleteResult = autofill.deleteCreditCard(id: creditCard!.guid).value
        XCTAssertTrue(deleteResult.isSuccess)
        XCTAssertNotNil(deleteResult.successValue!)
        XCTAssertTrue(deleteResult.successValue!)
        let getResult2 = autofill.getCreditCard(id: creditCard!.guid).value
        XCTAssertTrue(getResult2.isFailure)
        print("THIS", getResult2.failureValue!.description)
        let expectedError =
            "MozillaAppServices.AutofillApiError.NoSuchRecord(guid: \"\(creditCard!.guid)\")"
        XCTAssertEqual(expectedError, getResult2.failureValue!.description)
    }
}
