// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// import MozillaAppServices
// import Shared
// import Storage
// import UIKit
// import XCTest
//
// @testable import Client
//
// class CreditCardBottomSheetViewModelTests: XCTestCase {
//    private var profile: MockProfile!
//    private var viewModel: CreditCardBottomSheetViewModel!
//    private var mockAutofill: MockCreditCardProvider!
//    private var samplePlainTextCard = UnencryptedCreditCardFields(ccName: "Allen Burges",
//                                                                  ccNumber: "4111111111111111",
//                                                                  ccNumberLast4: "1111",
//                                                                  ccExpMonth: 3,
//                                                                  ccExpYear: 2043,
//                                                                  ccType: "VISA")
//
//    private var samplePlainTextUpdateCard = UnencryptedCreditCardFields(ccName: "Allen Burgers",
//                                                                        ccNumber: "4111111111111111",
//                                                                        ccNumberLast4: "1111",
//                                                                        ccExpMonth: 09,
//                                                                        ccExpYear: 2056,
//                                                                        ccType: "VISA")
//    private var sampleCreditCard = CreditCard(guid: "1",
//                                              ccName: "Allen Burges",
//                                              ccNumberEnc: "4111111111111111",
//                                              ccNumberLast4: "1111",
//                                              ccExpMonth: 3,
//                                              ccExpYear: 2043,
//                                              ccType: "VISA",
//                                              timeCreated: 1234678,
//                                              timeLastUsed: nil,
//                                              timeLastModified: 123123,
//                                              timesUsed: 123123)
//
//    override func setUp() {
//        super.setUp()
//        mockAutofill = MockCreditCardProvider()
//        viewModel = CreditCardBottomSheetViewModel(
//            creditCardProvider: mockAutofill,
//            creditCard: nil,
//            decryptedCreditCard: samplePlainTextCard,
//            state: .save
//        )
//    }
//
//    override func tearDown() {
//        mockAutofill = nil
//        viewModel = nil
//        super.tearDown()
//    }
//
//    // MARK: - Test Cases
//    func test_saveCreditCard_callsAddCreditCard() {
//        let expectation = expectation(description: "wait for credit card fields to be saved")
//        let decryptedCreditCard = viewModel.getPlainCreditCardValues(bottomSheetState: .save)
//        // Make sure the year saved is a 4 digit year and not 2 digit
//        // 2000 because that is our current period
//        XCTAssertTrue(decryptedCreditCard!.ccExpYear > 2000)
//        viewModel.saveCreditCard(with: decryptedCreditCard) { creditCard, error in
//            XCTAssertEqual(self.mockAutofill.addCreditCardCalledCount, 1)
//            expectation.fulfill()
//        }
//        waitForExpectations(timeout: 1.0)
//    }
//
//    func test_saveAndUpdateCreditCard_callsProperAutofillMethods() {
//        viewModel.state = .save
//        let expectationSave = expectation(description: "wait for credit card fields to be saved")
//        let expectationUpdate = expectation(description: "wait for credit card fields to be updated")
//
//        viewModel.saveCreditCard(with: samplePlainTextCard) { creditCard, error in
//            XCTAssertEqual(self.mockAutofill.addCreditCardCalledCount, 1)
//            expectationSave.fulfill()
//            self.viewModel.state = .update
//            self.viewModel.updateCreditCard(for: creditCard?.guid,
//                                            with: self.samplePlainTextCard) { didUpdate, error in
//                XCTAssertEqual(self.mockAutofill.updateCreditCardCalledCount, 1)
//                expectationUpdate.fulfill()
//            }
//        }
//        waitForExpectations(timeout: 6.0)
//    }
//
//    func testViewSetupForRememberCreditCard() {
//        viewModel.state = .save
//        XCTAssertTrue(viewModel.state.yesButtonTitle == .CreditCard.RememberCreditCard.MainButtonTitle)
//        XCTAssertTrue(viewModel.state.notNowButtonTitle == .CreditCard.RememberCreditCard.SecondaryButtonTitle)
//        XCTAssertTrue(viewModel.state.header == String(
//            format: String.CreditCard.RememberCreditCard.Header,
//            AppName.shortName.rawValue))
//        XCTAssertTrue(viewModel.state.title == .CreditCard.RememberCreditCard.MainTitle)
//    }
//
//    func testViewSetupForUpdateCreditCard() {
//        viewModel.state = .update
//        XCTAssertTrue(viewModel.state.yesButtonTitle == .CreditCard.UpdateCreditCard.MainButtonTitle)
//        XCTAssertTrue(viewModel.state.notNowButtonTitle == .CreditCard.UpdateCreditCard.SecondaryButtonTitle)
//        XCTAssertTrue(viewModel.state.title == .CreditCard.UpdateCreditCard.MainTitle)
//    }
//
//    // Update the test to also account for save and selected card flow
//    // Ticket: FXIOS-6719
//    func test_save_getPlainCreditCardValues() {
//        viewModel.state = .save
//        let value = viewModel.getPlainCreditCardValues(bottomSheetState: .save)
//        XCTAssertNotNil(value)
//        XCTAssertEqual(value!.ccName, samplePlainTextCard.ccName)
//        XCTAssertEqual(value!.ccExpMonth, samplePlainTextCard.ccExpMonth)
//        XCTAssertEqual(value!.ccNumberLast4, samplePlainTextCard.ccNumberLast4)
//        XCTAssertEqual(value!.ccType, samplePlainTextCard.ccType)
//        // Make sure the year saved is a 4 digit year and not 2 digit
//        // 2000 because that is our current period
//        XCTAssertTrue(value!.ccExpYear > 2000)
//    }
//
//    func test_getPlainCreditCardValues_NilDecryptedCard() {
//        viewModel.state = .save
//        viewModel.decryptedCreditCard = nil
//        let value = viewModel.getPlainCreditCardValues(bottomSheetState: .save)
//        XCTAssertNil(value)
//    }
//
//    func test_getConvertedCreditCardValues_MasterCard() {
//        viewModel.state = .save
//        let masterCard = UnencryptedCreditCardFields(ccName: "John Doe",
//                                                     ccNumber: "5555555555554444",
//                                                     ccNumberLast4: "4444",
//                                                     ccExpMonth: 12,
//                                                     ccExpYear: 2023,
//                                                     ccType: "MasterCard")
//        viewModel.decryptedCreditCard = masterCard
//        let value = viewModel.getConvertedCreditCardValues(
//            bottomSheetState: .save,
//            ccNumberDecrypted: masterCard.ccNumber
//        )
//        XCTAssertNotNil(value)
//        XCTAssertEqual(value!.ccType, "MasterCard")
//    }
//
//    func test_getPlainCreditCardValues_InvalidMonth() {
//        viewModel.state = .save
//        let invalidCard = UnencryptedCreditCardFields(ccName: "Jane Smith",
//                                                      ccNumber: "4111111111111111",
//                                                      ccNumberLast4: "1111",
//                                                      ccExpMonth: 13, // Invalid month
//                                                      ccExpYear: 2023,
//                                                      ccType: "VISA")
//        viewModel.decryptedCreditCard = invalidCard
//        let value = viewModel.getPlainCreditCardValues(bottomSheetState: .save)
//        XCTAssertNotNil(value)
//    }
//
//    func test_getConvertedCreditCardValues_UpcomingExpiry() {
//        viewModel.state = .save
//        let currentDate = Date()
//        let calendar = Calendar.current
//        let upcomingMonth = calendar.component(.month, from: currentDate) + 1
//        let upcomingYear = calendar.component(.year, from: currentDate)
//        let upcomingExpiryCard = UnencryptedCreditCardFields(ccName: "Jane Smith",
//                                                             ccNumber: "4111111111111111",
//                                                             ccNumberLast4: "1111",
//                                                             ccExpMonth: Int64(upcomingMonth),
//                                                             ccExpYear: Int64(upcomingYear),
//                                                             ccType: "VISA")
//        viewModel.decryptedCreditCard = upcomingExpiryCard
//        let value = viewModel.getConvertedCreditCardValues(
//            bottomSheetState: .save,
//            ccNumberDecrypted: upcomingExpiryCard.ccNumber
//        )
//        XCTAssertNotNil(value)
//        XCTAssertEqual(value!.ccExpMonth, Int64(upcomingMonth))
//        XCTAssertEqual(value!.ccExpYear, Int64(upcomingYear))
//    }
//
//    func test_getConvertedCreditCardValues_WhenStateIsSelectAndRowIsOutOfBounds() {
//        viewModel.state = .selectSavedCard
//        let result = viewModel.getConvertedCreditCardValues(bottomSheetState: .selectSavedCard,
//                                                            ccNumberDecrypted: "1234567890123456",
//                                                            row: 9999)
//        XCTAssertNil(result)
//    }
//
//    func test_select_PlainCreditCard_WithNegativeRow() {
//        viewModel.state = .selectSavedCard
//        viewModel.creditCards = [sampleCreditCard]
//        let value = viewModel.getPlainCreditCardValues(bottomSheetState: .selectSavedCard, row: -1)
//        XCTAssertNil(value)
//    }
//
//    func test_save_getConvertedCreditCardValues() {
//        viewModel.state = .save
//        let value = viewModel.getConvertedCreditCardValues(bottomSheetState: .save,
//                                                           ccNumberDecrypted: "")
//        XCTAssertNotNil(value)
//        XCTAssertEqual(value!.ccName, samplePlainTextCard.ccName)
//        XCTAssertEqual(value!.ccExpMonth, samplePlainTextCard.ccExpMonth)
//        XCTAssertEqual(value!.ccNumberLast4, samplePlainTextCard.ccNumberLast4)
//        XCTAssertEqual(value!.ccType, samplePlainTextCard.ccType)
//    }
//
//    func test_update_getConvertedCreditCardValues() {
//        viewModel.creditCard = sampleCreditCard
//        viewModel.decryptedCreditCard = samplePlainTextCard
//
//        // convert the saved credit card and check values
//        let decryptedCCNumber = "4111111111111111"
//        let value = self.viewModel.getConvertedCreditCardValues(bottomSheetState: .update,
//                                                                ccNumberDecrypted: decryptedCCNumber)
//        XCTAssertNotNil(value)
//        XCTAssertEqual(value!.ccName, self.samplePlainTextCard.ccName)
//        XCTAssertEqual(value!.ccExpMonth, self.samplePlainTextCard.ccExpMonth)
//        XCTAssertEqual(value!.ccNumberLast4, self.samplePlainTextCard.ccNumberLast4)
//        XCTAssertEqual(value!.ccType, self.samplePlainTextCard.ccType)
//    }
//
//    func test_update_selectConvertedCreditCardValues_ForSpecificRow() {
//        viewModel.creditCards = [sampleCreditCard]
//
//        let value = self.viewModel.getConvertedCreditCardValues(bottomSheetState: .selectSavedCard,
//                                                                ccNumberDecrypted: "",
//                                                                row: 0)
//        XCTAssertNotNil(value)
//        XCTAssertEqual(value!.ccName, self.samplePlainTextCard.ccName)
//        XCTAssertEqual(value!.ccExpMonth, self.samplePlainTextCard.ccExpMonth)
//        XCTAssertEqual(value!.ccNumberLast4, self.samplePlainTextCard.ccNumberLast4)
//        XCTAssertEqual(value!.ccType, self.samplePlainTextCard.ccType)
//    }
//
//    func test_update_selectConvertedCreditCardValues_ForInvalidRow() {
//        viewModel.creditCards = [sampleCreditCard]
//
//        let value = self.viewModel.getConvertedCreditCardValues(bottomSheetState: .selectSavedCard,
//                                                                ccNumberDecrypted: "")
//        XCTAssertNil(value)
//    }
//
//    func test_update_selectConvertedCreditCardValues_ForMinusRow() {
//        viewModel.creditCards = [sampleCreditCard]
//
//        let value = self.viewModel.getConvertedCreditCardValues(bottomSheetState: .selectSavedCard,
//                                                                ccNumberDecrypted: "",
//                                                                row: -1)
//        XCTAssertNil(value)
//    }
//
//    func test_update_selectConvertedCreditCardValues_ForEmptyCreditCards() {
//        viewModel.creditCards = []
//
//        let value = self.viewModel.getConvertedCreditCardValues(bottomSheetState: .selectSavedCard,
//                                                                ccNumberDecrypted: "",
//                                                                row: 1)
//        XCTAssertNil(value)
//    }
//
//    func test_updateDecryptedCreditCard() {
//        let sampleCreditCardVal = sampleCreditCard
//        let updatedName = "Red Dragon"
//        let updatedMonth: Int64 = 12
//        let updatedYear: Int64 = 2048
//        let newUnencryptedCreditCard = UnencryptedCreditCardFields(ccName: updatedName,
//                                                                   ccNumber: sampleCreditCardVal.ccNumberEnc,
//                                                                   ccNumberLast4: sampleCreditCardVal.ccNumberLast4,
//                                                                   ccExpMonth: updatedMonth,
//                                                                   ccExpYear: updatedYear,
//                                                                   ccType: sampleCreditCardVal.ccType)
//        let value = viewModel.updateDecryptedCreditCard(from: sampleCreditCardVal,
//                                                        with: sampleCreditCardVal.ccNumberEnc,
//                                                        fieldValues: newUnencryptedCreditCard)
//        XCTAssertNotNil(value)
//        XCTAssertEqual(value!.ccName, updatedName)
//        XCTAssertEqual(value!.ccExpMonth, updatedMonth)
//        XCTAssertEqual(value!.ccExpYear, updatedYear)
//        XCTAssertEqual(value!.ccNumber, sampleCreditCardVal.ccNumberEnc)
//    }
//
//    func test_didTapMainButton_withSaveState_callsAddCreditCard() {
//        viewModel.state = .save
//        viewModel.decryptedCreditCard = samplePlainTextCard
//        let expectation = expectation(description: "wait for credit card fields to be saved")
//
//        viewModel.didTapMainButton { _ in
//            XCTAssertNotNil(self.viewModel)
//            XCTAssertNotNil(self.mockAutofill)
//            XCTAssertEqual(self.mockAutofill.addCreditCardCalledCount, 1)
//            expectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 5.0)
//    }
//
//    func test_didTapMainButton_withUpdateState_callsAddCreditCard() {
//        viewModel.state = .update
//        viewModel.decryptedCreditCard = samplePlainTextCard
//        let expectation = expectation(description: "wait for credit card fields to be updated")
//
//        viewModel.didTapMainButton { _ in
//            XCTAssertNotNil(self.viewModel)
//            XCTAssertNotNil(self.mockAutofill)
//            XCTAssertEqual(self.mockAutofill.updateCreditCardCalledCount, 1)
//            expectation.fulfill()
//        }
//
//        waitForExpectations(timeout: 5.0)
//    }
//
//    func test_updateCreditCardList_callsListCreditCards() {
//        let expectation = expectation(description: "wait for credit card to be added")
//        viewModel.creditCard = nil
//        viewModel.decryptedCreditCard = nil
//        viewModel.state = .selectSavedCard
//
//        viewModel.updateCreditCardList({ cards in
//            XCTAssertNotNil(self.viewModel)
//            XCTAssertNotNil(self.mockAutofill)
//            XCTAssertEqual(self.viewModel.creditCards, cards)
//            XCTAssertEqual(cards?.count, 1)
//            XCTAssertEqual(cards?.first?.guid, "1")
//            XCTAssertEqual(cards?.first?.ccName, "Allen Burges")
//            XCTAssertEqual(self.mockAutofill.listCreditCardsCalledCount, 1)
//            expectation.fulfill()
//        })
//        waitForExpectations(timeout: 5.0)
//    }
//
//    func test_updateCreditCardList_withoutSelectedSavedCardState_doesNotCallListCreditCards() {
//        let expectation = expectation(description: "wait for credit card to be added")
//        expectation.isInverted = true
//        viewModel.creditCard = nil
//        viewModel.decryptedCreditCard = nil
//
//        viewModel.updateCreditCardList({ cards in
//            expectation.fulfill()
//        })
//        waitForExpectations(timeout: 1.0)
//    }
// }
