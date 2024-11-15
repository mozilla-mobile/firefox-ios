// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import XCTest

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

    func addAddress(completion: @escaping (Result<Address, Error>) -> Void) {
        let address = UpdatableAddressFields(
            name: "Jane Doe",
            organization: "",
            streetAddress: "123 Second Avenue",
            addressLevel3: "",
            addressLevel2: "Chicago, IL",
            addressLevel1: "",
            postalCode: "",
            country: "United States",
            tel: "",
            email: "")
        return autofill.addAddress(address: address, completion: completion)
    }

    func testAddAndGetAddress() {
        let expectationAddAddress = expectation(description: "Completes the add address operation")
        let expectationGetAddress = expectation(description: "Completes the get address operation")

        addAddress { result in
            switch result {
            case .success(let address):
                XCTAssertEqual(address.name, "Jane Doe")
                XCTAssertEqual(address.streetAddress, "123 Second Avenue")
                XCTAssertEqual(address.addressLevel2, "Chicago, IL")
                XCTAssertEqual(address.country, "United States")
                expectationAddAddress.fulfill()
                self.autofill.getAddress(id: address.guid) { retrievedAddress, getAddressError in
                    guard let retrievedAddress = retrievedAddress, getAddressError == nil else {
                        XCTFail("Failed to get address. Retrieved Address: \(String(describing: retrievedAddress)), Error: \(String(describing: getAddressError))")
                        expectationGetAddress.fulfill()
                        return
                    }
                    XCTAssertEqual(address.guid, retrievedAddress.guid)
                    expectationGetAddress.fulfill()
                }

            case .failure(let error):
                XCTFail("Failed to add address, Error: \(String(describing: error))")
                expectationAddAddress.fulfill()
                return
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testListAllAddressesSuccess() {
        let expectationListAddresses = expectation(description: "Completes the list all addresses operation")

        autofill.listAllAddresses { addresses, error in
            XCTAssertNil(error, "Error should be nil")
            XCTAssertNotNil(addresses, "Addresses should not be nil")

            // Assert on individual addresses in the list
            for address in addresses ?? [] {
                XCTAssertEqual(address.name, "Jane Doe")
                XCTAssertEqual(address.streetAddress, "123 Second Avenue")
                XCTAssertEqual(address.addressLevel2, "Chicago, IL")
                XCTAssertEqual(address.country, "United States")
            }

            expectationListAddresses.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
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
        let expectationCardList = expectation(description: "getting empty card list")
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

    func testListAllAddressesEmpty() {
        let expectationListAddresses = expectation(
            description: "Completes the list all addresses operation for an empty list"
        )

        autofill.listAllAddresses { addresses, error in
            XCTAssertNil(error, "Error should be nil")
            XCTAssertNotNil(addresses, "Addresses should not be nil")
            XCTAssertEqual(addresses?.count, 0, "Addresses count should be 0 for an empty list")

            expectationListAddresses.fulfill()
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testUpdateCreditCard() {
        let expectationAddCard = expectation(description: "completed add card")
        let expectationGetCard = expectation(description: "completed getting card")
        let expectationUpdateCard = expectation(description: "update card")
        let expectationCheckUpdateCard = expectation(description: "checking updated card")

        addCreditCard { creditCard, err in
            do {
                let creditCard = try XCTUnwrap(creditCard)

                XCTAssertNil(err)
                expectationAddCard.fulfill()

                self.autofill.getCreditCard(id: creditCard.guid) { card, err in
                    do {
                        let card = try XCTUnwrap(card)

                        XCTAssertNil(err)
                        XCTAssertEqual(creditCard.guid, card.guid)
                        expectationGetCard.fulfill()

                        let updatedCreditCard = self.createUnencryptedCreditCardFields(creditCard: creditCard)
                        self.autofill.updateCreditCard(id: creditCard.guid,
                                                       creditCard: updatedCreditCard) { success, err in
                            self.makeAssertionsForUpdateCard(success: success, err: err, expectation: expectationUpdateCard)

                            self.getCreditCardAndMakeAssertionsToCheckUpdatedCard(id: creditCard.guid,
                                                                                  updatedCreditCard: updatedCreditCard,
                                                                                  expectation: expectationCheckUpdateCard)
                        }
                    } catch {
                        XCTFail("The card variable should not be nil.")
                        expectationGetCard.fulfill()
                    }
                }
            } catch {
                XCTFail("The creditCard variable should not be nil.")
                expectationAddCard.fulfill()
            }
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    private func createUnencryptedCreditCardFields(creditCard: CreditCard) -> UnencryptedCreditCardFields {
        return UnencryptedCreditCardFields(ccName: creditCard.ccName,
                                           ccNumber: creditCard.ccNumberEnc,
                                           ccNumberLast4: creditCard.ccNumberLast4,
                                           ccExpMonth: creditCard.ccExpMonth,
                                           ccExpYear: Int64(2028),
                                           ccType: creditCard.ccType)
    }

    private func makeAssertionsForUpdateCard(success: Bool?, err: Error?, expectation: XCTestExpectation) {
        XCTAssertNotNil(success)
        if let updated = success {
            XCTAssert(updated)
        }
        XCTAssertNil(err)
        expectation.fulfill()
    }

    private func getCreditCardAndMakeAssertionsToCheckUpdatedCard(id: String,
                                                                  updatedCreditCard: UnencryptedCreditCardFields,
                                                                  expectation: XCTestExpectation) {
        self.autofill.getCreditCard(id: id) { updatedCardVal, err in
            do {
                let updatedCardVal = try XCTUnwrap(updatedCardVal)

                XCTAssertNil(err)
                XCTAssertEqual(updatedCardVal.ccExpYear, updatedCreditCard.ccExpYear)
                expectation.fulfill()
            } catch {
                XCTFail("The updatedCardVal variable should not be nil.")
                expectation.fulfill()
            }
        }
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
