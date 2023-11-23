// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client
import Storage
import Shared
import XCTest

class CreditCardBottomSheetViewModelTests: XCTestCase {
    private var profile: MockProfile!
    private var viewModel: CreditCardBottomSheetViewModel!
    private var files: FileAccessor!
    private var autofill: RustAutofill!
    private var encryptionKey: String!
    private var samplePlainTextCard = UnencryptedCreditCardFields(ccName: "Allen Burges",
                                                                  ccNumber: "4111111111111111",
                                                                  ccNumberLast4: "1111",
                                                                  ccExpMonth: 3,
                                                                  ccExpYear: 2043,
                                                                  ccType: "VISA")

    private var samplePlainTextUpdateCard = UnencryptedCreditCardFields(ccName: "Allen Burgers",
                                                                        ccNumber: "4111111111111111",
                                                                        ccNumberLast4: "1111",
                                                                        ccExpMonth: 09,
                                                                        ccExpYear: 2056,
                                                                        ccType: "VISA")
    private var sampleCreditCard = CreditCard(guid: "1",
                                              ccName: "Allen Burges",
                                              ccNumberEnc: "4111111111111111",
                                              ccNumberLast4: "1111",
                                              ccExpMonth: 3,
                                              ccExpYear: 2043,
                                              ccType: "VISA",
                                              timeCreated: 1234678,
                                              timeLastUsed: nil,
                                              timeLastModified: 123123,
                                              timesUsed: 123123)

    private var invalidSampleCreditCard = CreditCard(guid: "1",
                                                     ccName: "Allen Burges",
                                                     ccNumberEnc: "",
                                                     ccNumberLast4: "",
                                                     ccExpMonth: 1,
                                                     ccExpYear: 0,
                                                     ccType: "",
                                                     timeCreated: 0,
                                                     timeLastUsed: nil,
                                                     timeLastModified: 2,
                                                     timesUsed: 0)

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

        profile = MockProfile()
        _ = profile.autofill.reopenIfClosed()

        viewModel = CreditCardBottomSheetViewModel(profile: profile,
                                                   creditCard: nil,
                                                   decryptedCreditCard: samplePlainTextCard,
                                                   state: .save)
    }

    override func tearDown() {
        super.tearDown()
        profile.shutdown()
        profile = nil
        autofill = nil
        files = nil
        viewModel = nil
    }

    // MARK: - Test Cases
    func testSavingCard() {
        viewModel.creditCard = sampleCreditCard
        let expectation = expectation(description: "wait for credit card fields to be saved")
        let decryptedCreditCard = viewModel.getPlainCreditCardValues(bottomSheetState: .save)
        // Make sure the year saved is a 4 digit year and not 2 digit
        // 2000 because that is our current period
        XCTAssertTrue(decryptedCreditCard!.ccExpYear > 2000)
        viewModel.saveCreditCard(with: decryptedCreditCard) { creditCard, error in
            guard error == nil, let creditCard = creditCard else {
                XCTFail()
                return
            }
            XCTAssertEqual(creditCard.ccName, self.viewModel.creditCard?.ccName)
            // Note: the number for credit card is encrypted so that part
            // will get added later and for now we will check the name only
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func testUpdatingCard() {
        viewModel.state = .save
        viewModel.decryptedCreditCard = samplePlainTextCard
        let expectationSave = expectation(description: "wait for credit card fields to be saved")
        let expectationUpdate = expectation(description: "wait for credit card fields to be updated")

        viewModel.saveCreditCard(with: samplePlainTextCard) { creditCard, error in
            guard error == nil, let creditCard = creditCard else {
                XCTFail()
                return
            }
            expectationSave.fulfill()
            XCTAssertEqual(creditCard.ccName, self.viewModel.decryptedCreditCard?.ccName)
            // Note: the number for credit card is encrypted so that part
            // will get added later and for now we will check the name only

            self.samplePlainTextCard.ccExpYear = 2045
            self.samplePlainTextCard.ccName = "Test"
            self.viewModel.state = .update

            self.viewModel.updateCreditCard(for: creditCard.guid,
                                            with: self.samplePlainTextCard) { didUpdate, error in
                XCTAssertTrue(didUpdate)
                XCTAssertNil(error)
                expectationUpdate.fulfill()
            }
        }
        waitForExpectations(timeout: 6.0)
    }

    func testViewSetupForRememberCreditCard() {
        viewModel.state = .save
        XCTAssertTrue(viewModel.state.yesButtonTitle == .CreditCard.RememberCreditCard.MainButtonTitle)
        XCTAssertTrue(viewModel.state.notNowButtonTitle == .CreditCard.RememberCreditCard.SecondaryButtonTitle)
        XCTAssertTrue(viewModel.state.header == String(
            format: String.CreditCard.RememberCreditCard.Header,
            AppName.shortName.rawValue))
        XCTAssertTrue(viewModel.state.title == .CreditCard.RememberCreditCard.MainTitle)
    }

    func testViewSetupForUpdateCreditCard() {
        viewModel.state = .update
        XCTAssertTrue(viewModel.state.yesButtonTitle == .CreditCard.UpdateCreditCard.MainButtonTitle)
        XCTAssertTrue(viewModel.state.notNowButtonTitle == .CreditCard.UpdateCreditCard.SecondaryButtonTitle)
        XCTAssertTrue(viewModel.state.title == .CreditCard.UpdateCreditCard.MainTitle)
    }

    // Update the test to also account for save and selected card flow
    // Ticket: FXIOS-6719
    func test_save_getPlainCreditCardValues() {
        viewModel.state = .save
        let value = viewModel.getPlainCreditCardValues(bottomSheetState: .save)
        XCTAssertNotNil(value)
        XCTAssertEqual(value!.ccName, samplePlainTextCard.ccName)
        XCTAssertEqual(value!.ccExpMonth, samplePlainTextCard.ccExpMonth)
        XCTAssertEqual(value!.ccNumberLast4, samplePlainTextCard.ccNumberLast4)
        XCTAssertEqual(value!.ccType, samplePlainTextCard.ccType)
        // Make sure the year saved is a 4 digit year and not 2 digit
        // 2000 because that is our current period
        XCTAssertTrue(value!.ccExpYear > 2000)
    }

    func test_getPlainCreditCardValues_NilDecryptedCard() {
        viewModel.state = .save
        viewModel.decryptedCreditCard = nil
        let value = viewModel.getPlainCreditCardValues(bottomSheetState: .save)
        XCTAssertNil(value)
    }

    func test_getConvertedCreditCardValues_MasterCard() {
        viewModel.state = .save
        let masterCard = UnencryptedCreditCardFields(ccName: "John Doe",
                                                     ccNumber: "5555555555554444",
                                                     ccNumberLast4: "4444",
                                                     ccExpMonth: 12,
                                                     ccExpYear: 2023,
                                                     ccType: "MasterCard")
        viewModel.decryptedCreditCard = masterCard
        let value = viewModel.getConvertedCreditCardValues(bottomSheetState: .save, ccNumberDecrypted: masterCard.ccNumber)
        XCTAssertNotNil(value)
        XCTAssertEqual(value!.ccType, "MasterCard")
    }

    func test_getPlainCreditCardValues_InvalidMonth() {
        viewModel.state = .save
        let invalidCard = UnencryptedCreditCardFields(ccName: "Jane Smith",
                                                      ccNumber: "4111111111111111",
                                                      ccNumberLast4: "1111",
                                                      ccExpMonth: 13, // Invalid month
                                                      ccExpYear: 2023,
                                                      ccType: "VISA")
        viewModel.decryptedCreditCard = invalidCard
        let value = viewModel.getPlainCreditCardValues(bottomSheetState: .save)
        XCTAssertNotNil(value)
    }

    func test_getConvertedCreditCardValues_UpcomingExpiry() {
        viewModel.state = .save
        let currentDate = Date()
        let calendar = Calendar.current
        let upcomingMonth = calendar.component(.month, from: currentDate) + 1
        let upcomingYear = calendar.component(.year, from: currentDate)
        let upcomingExpiryCard = UnencryptedCreditCardFields(ccName: "Jane Smith",
                                                             ccNumber: "4111111111111111",
                                                             ccNumberLast4: "1111",
                                                             ccExpMonth: Int64(upcomingMonth),
                                                             ccExpYear: Int64(upcomingYear),
                                                             ccType: "VISA")
        viewModel.decryptedCreditCard = upcomingExpiryCard
        let value = viewModel.getConvertedCreditCardValues(bottomSheetState: .save, ccNumberDecrypted: upcomingExpiryCard.ccNumber)
        XCTAssertNotNil(value)
        XCTAssertEqual(value!.ccExpMonth, Int64(upcomingMonth))
        XCTAssertEqual(value!.ccExpYear, Int64(upcomingYear))
    }

    func test_getConvertedCreditCardValues_WhenStateIsSelectAndRowIsOutOfBounds() {
        viewModel.state = .selectSavedCard
        let result = viewModel.getConvertedCreditCardValues(bottomSheetState: .selectSavedCard,
                                                            ccNumberDecrypted: "1234567890123456",
                                                            row: 9999)
        XCTAssertNil(result)
    }

    func test_select_PlainCreditCard_WithNegativeRow() {
        viewModel.state = .selectSavedCard
        viewModel.creditCards = [sampleCreditCard]
        let value = viewModel.getPlainCreditCardValues(bottomSheetState: .selectSavedCard, row: -1)
        XCTAssertNil(value)
    }

    func test_save_getConvertedCreditCardValues() {
        viewModel.state = .save
        let value = viewModel.getConvertedCreditCardValues(bottomSheetState: .save,
                                                           ccNumberDecrypted: "")
        XCTAssertNotNil(value)
        XCTAssertEqual(value!.ccName, samplePlainTextCard.ccName)
        XCTAssertEqual(value!.ccExpMonth, samplePlainTextCard.ccExpMonth)
        XCTAssertEqual(value!.ccNumberLast4, samplePlainTextCard.ccNumberLast4)
        XCTAssertEqual(value!.ccType, samplePlainTextCard.ccType)
    }

    func test_update_getConvertedCreditCardValues() {
        viewModel.creditCard = sampleCreditCard
        viewModel.decryptedCreditCard = samplePlainTextCard

        // convert the saved credit card and check values
        let decryptedCCNumber = "4111111111111111"
        let value = self.viewModel.getConvertedCreditCardValues(bottomSheetState: .update,
                                                                ccNumberDecrypted: decryptedCCNumber)
        XCTAssertNotNil(value)
        XCTAssertEqual(value!.ccName, self.samplePlainTextCard.ccName)
        XCTAssertEqual(value!.ccExpMonth, self.samplePlainTextCard.ccExpMonth)
        XCTAssertEqual(value!.ccNumberLast4, self.samplePlainTextCard.ccNumberLast4)
        XCTAssertEqual(value!.ccType, self.samplePlainTextCard.ccType)
    }

    func test_update_selectConvertedCreditCardValues_ForSpecificRow() {
        viewModel.creditCards = [sampleCreditCard]

        let value = self.viewModel.getConvertedCreditCardValues(bottomSheetState: .selectSavedCard,
                                                                ccNumberDecrypted: "",
                                                                row: 0)
        XCTAssertNotNil(value)
        XCTAssertEqual(value!.ccName, self.samplePlainTextCard.ccName)
        XCTAssertEqual(value!.ccExpMonth, self.samplePlainTextCard.ccExpMonth)
        XCTAssertEqual(value!.ccNumberLast4, self.samplePlainTextCard.ccNumberLast4)
        XCTAssertEqual(value!.ccType, self.samplePlainTextCard.ccType)
    }

    func test_update_selectConvertedCreditCardValues_ForInvalidRow() {
        viewModel.creditCards = [sampleCreditCard]

        let value = self.viewModel.getConvertedCreditCardValues(bottomSheetState: .selectSavedCard,
                                                                ccNumberDecrypted: "")
        XCTAssertNil(value)
    }

    func test_update_selectConvertedCreditCardValues_ForMinusRow() {
        viewModel.creditCards = [sampleCreditCard]

        let value = self.viewModel.getConvertedCreditCardValues(bottomSheetState: .selectSavedCard,
                                                                ccNumberDecrypted: "",
                                                                row: -1)
        XCTAssertNil(value)
    }

    func test_update_selectConvertedCreditCardValues_ForEmptyCreditCards() {
        viewModel.creditCards = []

        let value = self.viewModel.getConvertedCreditCardValues(bottomSheetState: .selectSavedCard,
                                                                ccNumberDecrypted: "",
                                                                row: 1)
        XCTAssertNil(value)
    }

    func test_updateDecryptedCreditCard() {
        let sampleCreditCardVal = sampleCreditCard
        let updatedName = "Red Dragon"
        let updatedMonth: Int64 = 12
        let updatedYear: Int64 = 2048
        let newUnencryptedCreditCard = UnencryptedCreditCardFields(ccName: updatedName,
                                                                   ccNumber: sampleCreditCardVal.ccNumberEnc,
                                                                   ccNumberLast4: sampleCreditCardVal.ccNumberLast4,
                                                                   ccExpMonth: updatedMonth,
                                                                   ccExpYear: updatedYear,
                                                                   ccType: sampleCreditCardVal.ccType)
        let value = viewModel.updateDecryptedCreditCard(from: sampleCreditCardVal,
                                                        with: sampleCreditCardVal.ccNumberEnc,
                                                        fieldValues: newUnencryptedCreditCard)
        XCTAssertNotNil(value)
        XCTAssertEqual(value!.ccName, updatedName)
        XCTAssertEqual(value!.ccExpMonth, updatedMonth)
        XCTAssertEqual(value!.ccExpYear, updatedYear)
        XCTAssertEqual(value!.ccNumber, sampleCreditCardVal.ccNumberEnc)
    }

    func test_didTapMainButton() {
        viewModel.state = .save
        viewModel.decryptedCreditCard = samplePlainTextCard
        let expectation = expectation(description: "wait for credit card fields to be saved")

        viewModel.didTapMainButton { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_invalidCreditCardUpdateDidTapMainButton() {
        viewModel.state = .update
        viewModel.creditCard = invalidSampleCreditCard
        viewModel.decryptedCreditCard = samplePlainTextCard
        let expectation = expectation(description: "wait for credit card fields to be updated")

        viewModel.didTapMainButton { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func test_updateCreditCardList() {
        let expectation = expectation(description: "wait for credit card to be added")
        viewModel.creditCard = nil
        viewModel.decryptedCreditCard = nil
        // Add a sample card to the storage
        viewModel.saveCreditCard(with: samplePlainTextCard) { creditCard, error in
            guard error == nil, creditCard != nil else {
                XCTFail()
                return
            }
            // Make the view model state selected card
            self.viewModel.state = .selectSavedCard
            // Perform update
            self.viewModel.updateCreditCardList({ cards in
                // Check if the view model updated the list
                let cards = self.viewModel.creditCards
                XCTAssertNotNil(cards)
                XCTAssert(!cards!.isEmpty)
                expectation.fulfill()
            })
        }
        waitForExpectations(timeout: 3.0)
    }
}
