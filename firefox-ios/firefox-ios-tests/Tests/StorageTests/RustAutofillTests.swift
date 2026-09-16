// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import XCTest

@testable import Storage

final class RustAutofillTests: XCTestCase {
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

    let mockCreditCard = UnencryptedCreditCardFields(
        ccName: "Jane Doe",
        ccNumber: "1234567890123456",
        ccNumberLast4: "3456",
        ccExpMonth: 03,
        ccExpYear: 2027,
        ccType: "Visa")

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

    override func tearDown() {
        autofill.rustKeychain.removeAutofillKeysForDebugMenuItem()
        _ = autofill?.forceClose()
        autofill = nil
        encryptionKey = nil
        files = nil
        super.tearDown()
    }

    func addCreditCard() async throws -> CreditCard {
        return try await withCheckedThrowingContinuation { continuation in
            autofill.addCreditCard(creditCard: mockCreditCard) { card, error in
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

        XCTAssertEqual(address.name, retrievedAddress.name)
        XCTAssertEqual(address.streetAddress, retrievedAddress.streetAddress)
        XCTAssertEqual(address.addressLevel2, retrievedAddress.addressLevel2)
        XCTAssertEqual(address.country, retrievedAddress.country)
        XCTAssertEqual(address.guid, retrievedAddress.guid)
    }

    func testListAllAddressesSuccess() async throws {
        let addresses = try await listAllAddresses()

        for address in addresses {
            XCTAssertEqual(address.name, mockAddress.name)
            XCTAssertEqual(address.streetAddress, mockAddress.streetAddress)
            XCTAssertEqual(address.addressLevel2, mockAddress.addressLevel2)
            XCTAssertEqual(address.country, mockAddress.country)
        }
    }

    func testAddCreditCard() async throws {
        let creditCard = try await addCreditCard()
        let retrievedCreditCard = try await getCreditCard(id: creditCard.guid)

        XCTAssertEqual(creditCard.guid, retrievedCreditCard.guid)
        XCTAssertEqual(creditCard.ccName, retrievedCreditCard.ccName)
        XCTAssertEqual(creditCard.ccNumberEnc, retrievedCreditCard.ccNumberEnc)
        XCTAssertEqual(creditCard.ccNumberLast4, retrievedCreditCard.ccNumberLast4)
        XCTAssertEqual(creditCard.ccExpMonth, retrievedCreditCard.ccExpMonth)
        XCTAssertEqual(creditCard.ccExpYear, retrievedCreditCard.ccExpYear)
        XCTAssertEqual(creditCard.ccType, retrievedCreditCard.ccType)
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
        let creditCardVal = UnencryptedCreditCardFields(ccName: "Jane Smith",
                                                        ccNumber: "0123456789987654",
                                                        ccNumberLast4: "7654",
                                                        ccExpMonth: 01,
                                                        ccExpYear: 2028,
                                                        ccType: "Master")
        let result = try await updateCreditCard(id: creditCard.guid, creditCard: creditCardVal)
        let updatedCreditCardVal = try await getCreditCard(id: creditCard.guid)

        XCTAssertEqual(creditCard.guid, card.guid)
        XCTAssertTrue(result)
        XCTAssertEqual(updatedCreditCardVal.ccName, creditCardVal.ccName)
        XCTAssertEqual(updatedCreditCardVal.ccNumberLast4, creditCardVal.ccNumberLast4)
        XCTAssertEqual(updatedCreditCardVal.ccExpMonth, creditCardVal.ccExpMonth)
        XCTAssertEqual(updatedCreditCardVal.ccExpYear, creditCardVal.ccExpYear)
        XCTAssertEqual(updatedCreditCardVal.ccType, creditCardVal.ccType)
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

    func testDecryptCreditCardNumber() async throws {
        let creditCard = try await addCreditCard()
        let decryptedNumber = await Self.decryptCreditCardNumber(autofill, encryptedCCNum: creditCard.ccNumberEnc)

        XCTAssertEqual(decryptedNumber, mockCreditCard.ccNumber)
    }

    func testDecryptCreditCardNumberWithNilAndEmptyInput() async {
        let nilResult = await Self.decryptCreditCardNumber(autofill, encryptedCCNum: nil)
        let emptyResult = await Self.decryptCreditCardNumber(autofill, encryptedCCNum: "")

        XCTAssertNil(nilResult)
        XCTAssertNil(emptyResult)
    }

    func testDecryptCreditCardNumberWithInvalidCiphertext() async {
        let result = await Self.decryptCreditCardNumber(autofill, encryptedCCNum: "not-a-valid-ciphertext")

        XCTAssertNil(result)
    }

    func testGetStoredKeyReturnsExistingValidKey() async throws {
        let seededKey = try seedValidCreditCardKey()
        let storedKey = try await Self.getStoredKey(autofill)

        XCTAssertEqual(storedKey, seededKey)
    }

    func testConcurrentGetStoredKeyCallsReturnTheSameKey() async throws {
        // With a valid key seeded, any caller that wrongly triggers a key
        // regeneration would receive a newly created key instead of the seeded
        // one and fail the assertions below.
        let seededKey = try seedValidCreditCardKey()
        let autofill: RustAutofill = autofill

        let keys = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<20 {
                group.addTask { try await Self.getStoredKey(autofill) }
            }
            return try await group.reduce(into: [String]()) { $0.append($1) }
        }

        XCTAssertEqual(keys.count, 20)
        XCTAssertEqual(Set(keys), [seededKey])
    }

    func testConcurrentGetStoredKeyCallsWithNoExistingKey() async throws {
        // With no key data present, concurrent callers coalesce onto a single
        // key fetch. Every caller must still receive a completion callback and
        // they must all get the same generated key.
        autofill.rustKeychain.removeAutofillKeysForDebugMenuItem()
        let autofill: RustAutofill = autofill

        let keys = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<20 {
                group.addTask { try await Self.getStoredKey(autofill) }
            }
            return try await group.reduce(into: [String]()) { $0.append($1) }
        }

        XCTAssertEqual(keys.count, 20)
        XCTAssertEqual(Set(keys).count, 1, "All concurrent callers should receive the same generated key.")
    }

    func testConcurrentDecryptCreditCardNumber() async throws {
        let creditCard = try await addCreditCard()
        let encryptedCCNum = creditCard.ccNumberEnc
        let autofill: RustAutofill = autofill

        let decryptedNumbers = await withTaskGroup(of: String?.self) { group in
            for _ in 0..<10 {
                group.addTask { await Self.decryptCreditCardNumber(autofill, encryptedCCNum: encryptedCCNum) }
            }
            return await group.reduce(into: [String?]()) { $0.append($1) }
        }

        XCTAssertEqual(decryptedNumbers.count, 10)
        for decryptedNumber in decryptedNumbers {
            XCTAssertEqual(decryptedNumber, mockCreditCard.ccNumber)
        }
    }

    // MARK: - Helpers

    // Static so task group closures don't have to capture the non-Sendable test case.
    static func getStoredKey(_ autofill: RustAutofill) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            autofill.getStoredKey { result in
                switch result {
                case .success(let key):
                    continuation.resume(returning: key)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func decryptCreditCardNumber(_ autofill: RustAutofill, encryptedCCNum: String?) async -> String? {
        return await withCheckedContinuation { continuation in
            autofill.decryptCreditCardNumber(encryptedCCNum: encryptedCCNum) { ccNumber in
                continuation.resume(returning: ccNumber)
            }
        }
    }

    /// Stores a valid key and matching canary in the keychain so `getStoredKey`
    /// takes the existing-key path instead of generating a new one.
    func seedValidCreditCardKey() throws -> String {
        let key = try createAutofillKey()
        let canary = try createCanary(text: autofill.rustKeychain.creditCardCanaryPhrase, encryptionKey: key)
        autofill.rustKeychain.setCreditCardsKeyData(keyValue: key, canaryValue: canary)
        return key
    }
}
