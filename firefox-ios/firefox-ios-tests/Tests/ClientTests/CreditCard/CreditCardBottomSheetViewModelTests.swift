// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import Storage
import UIKit
import XCTest

@testable import Client

class CreditCardBottomSheetViewModelTests: XCTestCase {
    private var viewModel: CreditCardBottomSheetViewModel?
    private var mockAutofill: MockCreditCardProvider?
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

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockAutofill = MockCreditCardProvider()
        let autofill = try XCTUnwrap(mockAutofill)
        viewModel = CreditCardBottomSheetViewModel(
            creditCardProvider: autofill,
            creditCard: sampleCreditCard,
            decryptedCreditCard: samplePlainTextCard,
            state: CreditCardBottomSheetState.save
        )
    }

    override func tearDown() {
        mockAutofill = nil
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Test Cases
    func test_saveCreditCard_callsAddCreditCard() throws {
        let subject = try XCTUnwrap(viewModel)
        let autofill = try XCTUnwrap(mockAutofill)

        let expectation = expectation(description: "wait for credit card fields to be saved")
        let decryptedCreditCard = try XCTUnwrap(subject.getPlainCreditCardValues(bottomSheetState: .save))
        // Make sure the year saved is a 4 digit year and not 2 digit
        // 2000 because that is our current period
        XCTAssertTrue(decryptedCreditCard.ccExpYear > 2000)
        subject.saveCreditCard(with: decryptedCreditCard) { creditCard, error in
            XCTAssertEqual(autofill.addCreditCardCalledCount, 1)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_saveAndUpdateCreditCard_callsProperAutofillMethods() throws {
        let subject = try XCTUnwrap(viewModel)
        let autofill = try XCTUnwrap(mockAutofill)

        subject.state = .save
        let expectationSave = expectation(description: "wait for credit card fields to be saved")
        let expectationUpdate = expectation(description: "wait for credit card fields to be updated")

        subject.saveCreditCard(with: samplePlainTextCard) { creditCard, error in
            XCTAssertEqual(autofill.addCreditCardCalledCount, 1)
            expectationSave.fulfill()
            subject.state = .update
            subject.updateCreditCard(for: creditCard?.guid,
                                     with: self.samplePlainTextCard
            ) { didUpdate, error in
                XCTAssertEqual(autofill.updateCreditCardCalledCount, 1)
                expectationUpdate.fulfill()
            }
        }
        waitForExpectations(timeout: 6.0)
    }

    func testViewSetupForRememberCreditCard() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.state = .save
        XCTAssertTrue(subject.state.yesButtonTitle == .CreditCard.RememberCreditCard.MainButtonTitle)
        XCTAssertTrue(subject.state.notNowButtonTitle == .CreditCard.RememberCreditCard.SecondaryButtonTitle)
        XCTAssertTrue(subject.state.header == String(
            format: String.CreditCard.RememberCreditCard.Header,
            AppName.shortName.rawValue))
        XCTAssertTrue(subject.state.title == .CreditCard.RememberCreditCard.MainTitle)
    }

    func testViewSetupForUpdateCreditCard() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.state = .update
        XCTAssertTrue(subject.state.yesButtonTitle == .CreditCard.UpdateCreditCard.MainButtonTitle)
        XCTAssertTrue(subject.state.notNowButtonTitle == .CreditCard.UpdateCreditCard.SecondaryButtonTitle)
        XCTAssertTrue(subject.state.title == .CreditCard.UpdateCreditCard.MainTitle)
    }

    // Update the test to also account for save and selected card flow
    // Ticket: FXIOS-6719
    func test_save_getPlainCreditCardValues() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.state = .save
        let value = try XCTUnwrap(subject.getPlainCreditCardValues(bottomSheetState: .save))
        XCTAssertEqual(value.ccName, samplePlainTextCard.ccName)
        XCTAssertEqual(value.ccExpMonth, samplePlainTextCard.ccExpMonth)
        XCTAssertEqual(value.ccNumberLast4, samplePlainTextCard.ccNumberLast4)
        XCTAssertEqual(value.ccType, samplePlainTextCard.ccType)
        // Make sure the year saved is a 4 digit year and not 2 digit
        // 2000 because that is our current period
        XCTAssertTrue(value.ccExpYear > 2000)
    }

    func test_getPlainCreditCardValues_NilDecryptedCard() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.state = .save
        subject.decryptedCreditCard = nil
        let value = subject.getPlainCreditCardValues(bottomSheetState: .save)
        XCTAssertNil(value)
    }

    func test_getConvertedCreditCardValues_MasterCard() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.state = .save
        let masterCard = UnencryptedCreditCardFields(ccName: "John Doe",
                                                     ccNumber: "5555555555554444",
                                                     ccNumberLast4: "4444",
                                                     ccExpMonth: 12,
                                                     ccExpYear: 2023,
                                                     ccType: "MasterCard")
        subject.decryptedCreditCard = masterCard
        let value = subject.getConvertedCreditCardValues(
            bottomSheetState: .save,
            ccNumberDecrypted: masterCard.ccNumber
        )
        let cardValue = try XCTUnwrap(value)
        XCTAssertEqual(cardValue.ccType, "MasterCard")
    }

    func test_getPlainCreditCardValues_InvalidMonth() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.state = .save
        let invalidCard = UnencryptedCreditCardFields(ccName: "Jane Smith",
                                                      ccNumber: "4111111111111111",
                                                      ccNumberLast4: "1111",
                                                      ccExpMonth: 13, // Invalid month
                                                      ccExpYear: 2023,
                                                      ccType: "VISA")
        subject.decryptedCreditCard = invalidCard
        let value = subject.getPlainCreditCardValues(bottomSheetState: .save)
        XCTAssertNotNil(value)
    }

    func test_getConvertedCreditCardValues_UpcomingExpiry() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.state = .save
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
        subject.decryptedCreditCard = upcomingExpiryCard
        let value = try XCTUnwrap(subject.getConvertedCreditCardValues(
            bottomSheetState: .save,
            ccNumberDecrypted: upcomingExpiryCard.ccNumber
        ))
        XCTAssertEqual(value.ccExpMonth, Int64(upcomingMonth))
        XCTAssertEqual(value.ccExpYear, Int64(upcomingYear))
    }

    func test_getConvertedCreditCardValues_WhenStateIsSelectAndRowIsOutOfBounds() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.state = .selectSavedCard
        let result = subject.getConvertedCreditCardValues(bottomSheetState: .selectSavedCard,
                                                          ccNumberDecrypted: "1234567890123456",
                                                          row: 9999)
        XCTAssertNil(result)
    }

    func test_select_PlainCreditCard_WithNegativeRow() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.state = .selectSavedCard
        subject.creditCards = [sampleCreditCard]
        let value = subject.getPlainCreditCardValues(bottomSheetState: .selectSavedCard, row: -1)
        XCTAssertNil(value)
    }

    func test_save_getConvertedCreditCardValues() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.state = .save
        let value = try XCTUnwrap(
            subject.getConvertedCreditCardValues(
                bottomSheetState: .save,
                ccNumberDecrypted: ""
            )
        )

        XCTAssertEqual(value.ccName, samplePlainTextCard.ccName)
        XCTAssertEqual(value.ccExpMonth, samplePlainTextCard.ccExpMonth)
        XCTAssertEqual(value.ccNumberLast4, samplePlainTextCard.ccNumberLast4)
        XCTAssertEqual(value.ccType, samplePlainTextCard.ccType)
    }

    func test_update_getConvertedCreditCardValues() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.creditCard = sampleCreditCard
        subject.decryptedCreditCard = samplePlainTextCard

        // convert the saved credit card and check values
        let decryptedCCNumber = "4111111111111111"
        let value = try XCTUnwrap(
            subject.getConvertedCreditCardValues(
                bottomSheetState: .update,
                ccNumberDecrypted: decryptedCCNumber
            )
        )
        XCTAssertEqual(value.ccName, self.samplePlainTextCard.ccName)
        XCTAssertEqual(value.ccExpMonth, self.samplePlainTextCard.ccExpMonth)
        XCTAssertEqual(value.ccNumberLast4, self.samplePlainTextCard.ccNumberLast4)
        XCTAssertEqual(value.ccType, self.samplePlainTextCard.ccType)
    }

    func test_update_selectConvertedCreditCardValues_ForSpecificRow() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.creditCards = [sampleCreditCard]

        let value = try XCTUnwrap(
            subject.getConvertedCreditCardValues(
                bottomSheetState: .selectSavedCard,
                ccNumberDecrypted: "",
                row: 0
            )
        )
        XCTAssertEqual(value.ccName, self.samplePlainTextCard.ccName)
        XCTAssertEqual(value.ccExpMonth, self.samplePlainTextCard.ccExpMonth)
        XCTAssertEqual(value.ccNumberLast4, self.samplePlainTextCard.ccNumberLast4)
        XCTAssertEqual(value.ccType, self.samplePlainTextCard.ccType)
    }

    func test_update_selectConvertedCreditCardValues_ForInvalidRow() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.creditCards = [sampleCreditCard]

        let value = subject.getConvertedCreditCardValues(
            bottomSheetState: .selectSavedCard,
            ccNumberDecrypted: ""
        )
        XCTAssertNil(value)
    }

    func test_update_selectConvertedCreditCardValues_ForMinusRow() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.creditCards = [sampleCreditCard]

        let value = subject.getConvertedCreditCardValues(
            bottomSheetState: .selectSavedCard,
            ccNumberDecrypted: "",
            row: -1
        )
        XCTAssertNil(value)
    }

    func test_update_selectConvertedCreditCardValues_ForEmptyCreditCards() throws {
        let subject = try XCTUnwrap(viewModel)

        subject.creditCards = []

        let value = subject.getConvertedCreditCardValues(
            bottomSheetState: .selectSavedCard,
            ccNumberDecrypted: "",
            row: 1
        )
        XCTAssertNil(value)
    }

    func test_updateDecryptedCreditCard() throws {
        let subject = try XCTUnwrap(viewModel)

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
        let value = try XCTUnwrap(
            subject.updateDecryptedCreditCard(
                from: sampleCreditCardVal,
                with: sampleCreditCardVal.ccNumberEnc,
                fieldValues: newUnencryptedCreditCard
            )
        )
        XCTAssertEqual(value.ccName, updatedName)
        XCTAssertEqual(value.ccExpMonth, updatedMonth)
        XCTAssertEqual(value.ccExpYear, updatedYear)
        XCTAssertEqual(value.ccNumber, sampleCreditCardVal.ccNumberEnc)
    }

    func test_didTapMainButton_withSaveState_callsAddCreditCard() throws {
        let subject = try XCTUnwrap(viewModel)
        let autofill = try XCTUnwrap(mockAutofill)

        subject.state = .save
        subject.decryptedCreditCard = samplePlainTextCard
        let expectation = expectation(description: "wait for credit card fields to be saved")

        subject.didTapMainButton { error in
            guard error == nil else {
                XCTFail("Should not have received error: \(String(describing: error?.localizedDescription))")
                return
            }

            XCTAssertEqual(autofill.addCreditCardCalledCount, 1)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func test_didTapMainButton_withUpdateState_callsAddCreditCard() throws {
        let subject = try XCTUnwrap(viewModel)
        let autofill = try XCTUnwrap(mockAutofill)

        subject.state = .update
        subject.decryptedCreditCard = samplePlainTextCard
        let expectation = expectation(description: "wait for credit card fields to be updated")

        subject.didTapMainButton { error in
            guard error == nil else {
                XCTFail("Should not have received error: \(String(describing: error?.localizedDescription))")
                return
            }
            XCTAssertEqual(autofill.updateCreditCardCalledCount, 1)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func test_updateCreditCardList_callsListCreditCards() throws {
        let subject = try XCTUnwrap(viewModel)
        let autofill = try XCTUnwrap(mockAutofill)

        let expectation = expectation(description: "wait for credit card to be added")
        subject.creditCard = nil
        subject.decryptedCreditCard = nil
        subject.state = .selectSavedCard

        subject.updateCreditCardList({ cards in
            XCTAssertEqual(subject.creditCards, cards)
            XCTAssertEqual(cards?.count, 1)
            XCTAssertEqual(cards?.first?.guid, "1")
            XCTAssertEqual(cards?.first?.ccName, "Allen Burges")
            XCTAssertEqual(autofill.listCreditCardsCalledCount, 1)
            expectation.fulfill()
        })
        waitForExpectations(timeout: 5.0)
    }

    func test_updateCreditCardList_withoutSelectedSavedCardState_doesNotCallListCreditCards() throws {
        let subject = try XCTUnwrap(viewModel)

        let expectation = expectation(description: "wait for credit card to be added")
        expectation.isInverted = true
        subject.creditCard = nil
        subject.decryptedCreditCard = nil

        subject.updateCreditCardList({ cards in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 1.0)
    }
}
