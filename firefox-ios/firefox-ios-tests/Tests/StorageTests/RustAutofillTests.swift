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

    let mockAddress = UpdatableAddressFields(
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

    func addCreditCard() async throws -> CreditCard {
        let creditCard = UnencryptedCreditCardFields(
            ccName: "Jane Doe",
            ccNumber: "1234567890123456",
            ccNumberLast4: "3456",
            ccExpMonth: 03,
            ccExpYear: 2027,
            ccType: "Visa")

        return try await withCheckedThrowingContinuation { continuation in
            autofill.addCreditCard(creditCard: creditCard) { card, error in
                guard let card else {
                    continuation.resume(throwing: error ?? NSError(domain: "Couldn't add credit card", code: 0))
                    return
                }
                continuation.resume(returning: card)
            }
        }
    }

    func getCreditCard(id: String) async throws -> CreditCard {
        return try await withCheckedThrowingContinuation { continuation in
            autofill.getCreditCard(id: id) { card, error in
                guard let card else {
                    continuation.resume(throwing: error ?? NSError(domain: "Couldn't get credit card", code: 0))
                    return
                }
                continuation.resume(returning: card)
            }
        }
    }

    func updateCreditCard(id: String,
                          creditCard: UnencryptedCreditCardFields) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            autofill.updateCreditCard(id: id, creditCard: creditCard) { success, error in
                guard let success else {
                    continuation.resume(throwing: error ?? NSError(domain: "Couldn't update credit card", code: 0))
                    return
                }
                continuation.resume(returning: success)
            }
        }
    }

    func listCreditCards() async throws -> [CreditCard] {
        return try await withCheckedThrowingContinuation { continuation in
            autofill.listCreditCards { cards, error in
                guard let cards else {
                    continuation.resume(throwing: error ?? NSError(domain: "Couldn't list credit cards", code: 0))
                    return
                }
                continuation.resume(returning: cards)
            }
        }
    }

    func deleteCreditCard(id: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            autofill.deleteCreditCard(id: id) { success, error in
                guard let error else {
                    continuation.resume(returning: success)
                    return
                }

                continuation.resume(throwing: error)
            }
        }
    }

    func addAddress() async throws -> Address {
        return try await withCheckedThrowingContinuation { continuation in
            autofill.addAddress(address: mockAddress) { result in
                switch result {
                case .success(let addedAddress):
                    continuation.resume(returning: addedAddress)
                    return
                case .failure(let error):
                    continuation.resume(throwing: error)
                    return
                }
            }
        }
    }

    func getAddress(id: String) async throws -> Address {
        return try await withCheckedThrowingContinuation { continuation in
            autofill.getAddress(id: id) { address, error in
                guard let address else {
                    continuation.resume(throwing: error ?? NSError(domain: "Couldn't get address", code: 0))
                    return
                }
                continuation.resume(returning: address)
            }
        }
    }

    func listAllAddresses() async throws -> [Address] {
        return try await withCheckedThrowingContinuation { continuation in
            autofill.listAllAddresses { addresses, error in
                guard let addresses else {
                    continuation.resume(throwing: error ?? NSError(domain: "Couldn't get addresses", code: 0))
                    return
                }
                continuation.resume(returning: addresses)
            }
        }
    }

    func testAddAndGetAddress() async throws {
        let address = try await addAddress()
        let retrievedAddress = try await getAddress(id: address.guid)

        XCTAssertEqual(address.name, "Jane Doe")
        XCTAssertEqual(address.streetAddress, "123 Second Avenue")
        XCTAssertEqual(address.addressLevel2, "Chicago, IL")
        XCTAssertEqual(address.country, "United States")
        XCTAssertEqual(address.guid, retrievedAddress.guid)
    }

    func testListAllAddressesSuccess() async throws {
        let addresses = try await listAllAddresses()

        for address in addresses {
            XCTAssertEqual(address.name, "Jane Doe")
            XCTAssertEqual(address.streetAddress, "123 Second Avenue")
            XCTAssertEqual(address.addressLevel2, "Chicago, IL")
            XCTAssertEqual(address.country, "United States")
        }
    }

    func testAddCreditCard() async throws {
        let creditCard = try await addCreditCard()
        let retrievedCreditCard = try await getCreditCard(id: creditCard.guid)

        XCTAssertEqual(creditCard.guid, retrievedCreditCard.guid)
    }

    func testListCreditCards() async throws {
        let cards = try await listCreditCards()
        _ = try await addCreditCard()
        let updatedCards = try await listCreditCards()

        XCTAssertEqual(cards.count, 0)
        XCTAssertEqual(updatedCards.count, 1)
    }

    func testListAllAddressesEmpty() async throws {
        let addresses = try await listAllAddresses()

        XCTAssertEqual(addresses.count, 0, "Addresses count should be 0 for an empty list")
    }

    func testUpdateCreditCard() async throws {
        let creditCard = try await addCreditCard()
        let card = try await getCreditCard(id: creditCard.guid)
        let updatedCreditCard = UnencryptedCreditCardFields(ccName: creditCard.ccName,
                                                            ccNumber: creditCard.ccNumberEnc,
                                                            ccNumberLast4: creditCard.ccNumberLast4,
                                                            ccExpMonth: creditCard.ccExpMonth,
                                                            ccExpYear: Int64(2028),
                                                            ccType: creditCard.ccType)
        let result = try await updateCreditCard(id: creditCard.guid, creditCard: updatedCreditCard)
        let updatedCardVal = try await getCreditCard(id: creditCard.guid)

        XCTAssertEqual(creditCard.guid, card.guid)
        XCTAssertTrue(result)
        XCTAssertEqual(updatedCardVal.ccName, updatedCreditCard.ccName)
        XCTAssertEqual(updatedCardVal.ccNumberEnc, updatedCreditCard.ccNumber)
        XCTAssertEqual(updatedCardVal.ccNumberLast4, updatedCreditCard.ccNumberLast4)
        XCTAssertEqual(updatedCardVal.ccExpMonth, updatedCreditCard.ccExpMonth)
        XCTAssertEqual(updatedCardVal.ccExpYear, updatedCreditCard.ccExpYear)
        XCTAssertEqual(updatedCardVal.ccType, updatedCreditCard.ccType)
    }

    func testDeleteCreditCard() async throws {
        let creditCard = try await addCreditCard()
        let retrievedCreditCard = try await getCreditCard(id: creditCard.guid)
        let deleteCreditCardResult = try await deleteCreditCard(id: retrievedCreditCard.guid)
        let result = try? await getCreditCard(id: creditCard.guid)

        XCTAssertEqual(creditCard.guid, retrievedCreditCard.guid)
        XCTAssertTrue(deleteCreditCardResult)
        XCTAssertNil(result)
    }
}
