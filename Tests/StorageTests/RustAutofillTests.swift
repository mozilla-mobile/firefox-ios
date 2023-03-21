// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Storage

class RustAutofillTests: XCTestCase {
    var files: FileAccessor!
    var autofill: RustAutofill!
    var encryptionKey: String!

    override func setUp() {
        super.setUp()
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

    func addCreditCard(completion: @escaping (CreditCard?, Error?) -> Void) {
        let creditCard = UnencryptedCreditCardFields(
            ccName: "Jane Doe",
            ccNumber: "1234567890123456",
            ccNumberLast4: "3456",
            ccExpMonth: 03,
            ccExpYear: 2027,
            ccType: "Visa")
        return autofill.addCreditCard(creditCard: creditCard, completion: completion)
    }

    func testAddCreditCard() {
        let expectationAddCard = expectation(description: "completed add card")
        let expectationGetCard = expectation(description: "completed getting card")

        addCreditCard { creditCard, err in
            XCTAssertNotNil(creditCard)
            XCTAssertNil(err)
            expectationAddCard.fulfill()

            self.autofill.getCreditCard(id: creditCard!.guid) { card, error in
                XCTAssertNotNil(card)
                XCTAssertNil(err)
                XCTAssertEqual(creditCard!.guid, card!.guid)
                expectationGetCard.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testListCreditCards() {
        let expectationCardList = expectation(description: "gettting empty card list")
        let expectationAddCard = expectation(description: "add card")
        let expectationGetCards = expectation(description: "getting card list")
        autofill.listCreditCards { cards, err in
            XCTAssertNotNil(cards)
            XCTAssertNil(err)
            XCTAssertEqual(cards!.count, 0)
            expectationCardList.fulfill()

            self.addCreditCard { creditCard, err in
                XCTAssertNotNil(creditCard)
                XCTAssertNil(err)
                expectationAddCard.fulfill()

                self.autofill.listCreditCards { cards, err in
                    XCTAssertNotNil(cards)
                    XCTAssertNil(err)
                    XCTAssertEqual(cards!.count, 1)
                    expectationGetCards.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testUpdateCreditCard() {
        let expectationAddCard = expectation(description: "completed add card")
        let expectationGetCard = expectation(description: "completed getting card")
        let expectationUpdateCard = expectation(description: "update card")
        let expectationCheckUpdateCard = expectation(description: "checking updated card")

        addCreditCard { creditCard, err in
            XCTAssertNotNil(creditCard)
            XCTAssertNil(err)
            expectationAddCard.fulfill()

            self.autofill.getCreditCard(id: creditCard!.guid) { card, error in
                XCTAssertNotNil(card)
                XCTAssertNil(err)
                XCTAssertEqual(creditCard!.guid, card!.guid)
                expectationGetCard.fulfill()

                let expectedCcExpYear = Int64(2028)
                let updatedCreditCard = UnencryptedCreditCardFields(ccName: creditCard!.ccName,
                                                                    ccNumber: creditCard!.ccNumberEnc,
                                                                    ccNumberLast4: creditCard!.ccNumberLast4,
                                                                    ccExpMonth: creditCard!.ccExpMonth,
                                                                    ccExpYear: expectedCcExpYear,
                                                                    ccType: creditCard!.ccType)
                self.autofill.updateCreditCard(id: creditCard!.guid,
                                               creditCard: updatedCreditCard) { success, err in
                    XCTAssert(success)
                    XCTAssertNil(err)
                    expectationUpdateCard.fulfill()

                    self.autofill.getCreditCard(id: creditCard!.guid) { updatedCardVal, err in
                        XCTAssertNotNil(updatedCardVal)
                        XCTAssertNil(err)
                        XCTAssertEqual(updatedCardVal!.ccExpYear, updatedCreditCard.ccExpYear)
                        expectationCheckUpdateCard.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDeleteCreditCard() {
        let expectationAddCard = expectation(description: "completed add card")
        let expectationGetCard = expectation(description: "completed getting card")
        let expectationDeleteCard = expectation(description: "delete card")
        let expectationCheckDeleteCard = expectation(description: "check that no card exist")

        addCreditCard { creditCard, err in
            XCTAssertNotNil(creditCard)
            XCTAssertNil(err)
            expectationAddCard.fulfill()

            self.autofill.getCreditCard(id: creditCard!.guid) { card, error in
                XCTAssertNotNil(card)
                XCTAssertNil(err)
                XCTAssertEqual(creditCard!.guid, card!.guid)
                expectationGetCard.fulfill()

                self.autofill.deleteCreditCard(id: card!.guid) { success, err in
                    XCTAssert(success)
                    XCTAssertNil(err)
                    expectationDeleteCard.fulfill()

                    self.autofill.getCreditCard(id: creditCard!.guid) { deletedCreditCard, error in
                        XCTAssertNil(deletedCreditCard)
                        XCTAssertNotNil(error)

                        let expectedError =
                        "NoSuchRecord(guid: \"\(creditCard!.guid)\")"
                        XCTAssertEqual(expectedError, "\(error!)")
                        expectationCheckDeleteCard.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }
}
