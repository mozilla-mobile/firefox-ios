// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Storage
import XCTest

@testable import Client

class CreditCardInputViewModelTests: XCTestCase {
    private var profile: MockProfile!
    private var viewModel: CreditCardInputViewModel!
    private var files: FileAccessor!
    private var autofill: MockCreditCardProvider!
    private var encryptionKey: String!
    private var samplePlainTextCard = UnencryptedCreditCardFields(ccName: "Allen Burges",
                                                                  ccNumber: "4539185806954013",
                                                                  ccNumberLast4: "4013",
                                                                  ccExpMonth: 08,
                                                                  ccExpYear: 2055,
                                                                  ccType: "VISA")
    override func setUp() {
        super.setUp()
        files = MockFiles()
        autofill = MockCreditCardProvider()
        profile = MockProfile()
        viewModel = CreditCardInputViewModel(profile: profile, creditCardProvider: autofill)
    }

    override func tearDown() {
        viewModel = nil
        profile = nil
        autofill = nil
        super.tearDown()
    }

    func testEditViewModel_SavingCard() {
        viewModel.nameOnCard = samplePlainTextCard.ccName
        viewModel.cardNumber = samplePlainTextCard.ccNumber
        viewModel.expirationDate = "1288"
        let expectation = expectation(description: "wait for credit card fields to be saved")
        viewModel.saveCreditCard { [autofill] creditCard, error in
            XCTAssertNotNil(creditCard)
            XCTAssertNil(error)
            XCTAssertEqual(creditCard?.ccName, "Allen Burges")
            XCTAssertEqual(autofill?.addCreditCardCalledCount, 1)
            // Note: the number for credit card is encrypted so that part
            // will get added later and for now we will check the name only
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testEditState_setup() {
        // Setup edit state
        viewModel.state = .edit
        XCTAssertEqual(viewModel.state.leftBarBtn, .cancel)
        XCTAssertEqual(viewModel.state.rightBarBtn, .save)
        XCTAssertEqual(viewModel.state.title, .CreditCard.EditCard.EditCreditCardTitle)
        XCTAssertEqual(viewModel.state.rightBarBtn.title, .CreditCard.EditCard.SaveNavBarButtonLabel)
    }

    func testAddState_setup() {
        // Setup add state
        viewModel.state = .add
        XCTAssertEqual(viewModel.state.leftBarBtn, .close)
        XCTAssertEqual(viewModel.state.rightBarBtn, .save)
        XCTAssertEqual(viewModel.state.title, .CreditCard.EditCard.AddCreditCardTitle)
        XCTAssertEqual(viewModel.state.rightBarBtn.title, .CreditCard.EditCard.SaveNavBarButtonLabel)
    }

    func testViewState_setup() {
        // Setup view state
        viewModel.state = .view
        XCTAssertEqual(viewModel.state.leftBarBtn, .close)
        XCTAssertEqual(viewModel.state.rightBarBtn, .edit)
        XCTAssertEqual(viewModel.state.title, .CreditCard.EditCard.ViewCreditCardTitle)
        XCTAssertEqual(viewModel.state.rightBarBtn.title, .CreditCard.EditCard.EditNavBarButtonLabel)
    }

    func testRightBarButtonEnabledView() {
        viewModel.state = .view
        viewModel.nameOnCard = "Kenny Champion"
        viewModel.expirationDate = "123"
        viewModel.cardNumber = "41110000"
        viewModel.updateRightButtonState()
        XCTAssertTrue(viewModel.isRightBarButtonEnabled)
    }

    func testRightBarButtonNotEnabledEdit() {
        viewModel.state = .edit
        viewModel.nameOnCard = "Kenny Champion"
        viewModel.expirationDate = "123"
        viewModel.cardNumber = "4871007782167426"
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
    }

    func testRightBarButtonEnabledEdit() {
        viewModel.state = .edit
        viewModel.nameOnCard = "Kenny Champion"
        viewModel.expirationDate = "1239"
        viewModel.cardNumber = "4871007782167426"
        // Original State
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
        // Mimic the behaviour of onChange
        // in credit card input field, as the
        // state changes based on validity of the input variables
        viewModel.updateRightButtonState()
        XCTAssertTrue(viewModel.isRightBarButtonEnabled)
    }

    func testRightBarButtonNotEnabledAdd() {
        viewModel.state = .add
        viewModel.nameOnCard = "Jakyla Labarge"
        viewModel.expirationDate = "123"
        viewModel.cardNumber = "4717219604213696"
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
    }

    func testRightBarButtonEnabledAdd() {
        viewModel.state = .add
        viewModel.nameOnCard = "Jakyla Labarge"
        viewModel.expirationDate = "1239"
        viewModel.cardNumber = "4717219604213696"
        // Original State
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
        // Mimic the behaviour of onChange
        // in credit card input field, as the
        // state changes based on validity of the input variables
        viewModel.updateRightButtonState()
        XCTAssertTrue(viewModel.isRightBarButtonEnabled)
    }

    func testRightBarButtonDisabled_AddState() {
        rightBarButtonDisabled_Empty_CardName(state: .add)
        rightBarButtonDisabled_Empty_CardName_Expiration(state: .add)
        rightBarButtonDisabled_Empty_CardName_Expiration_Number(state: .add)
    }

    func testRightBarButtonDisabled_EditState() {
        rightBarButtonDisabled_Empty_CardName(state: .edit)
        rightBarButtonDisabled_Empty_CardName_Expiration(state: .edit)
        rightBarButtonDisabled_Empty_CardName_Expiration_Number(state: .edit)
    }

    func testGetCopyValueForNumber() {
        viewModel.nameOnCard = "Jakyla Labarge"
        viewModel.expirationDate = "12 / 39"
        viewModel.cardNumber = "4717219604213696"

        let result = viewModel.getCopyValueFor(.number)
        XCTAssertEqual(result, "4717219604213696")
    }

    func testGetCopyValueForName() {
        viewModel.nameOnCard = "Jakyla Labarge"
        viewModel.expirationDate = "12 / 39"
        viewModel.cardNumber = "4717219604213696"

        let result = viewModel.getCopyValueFor(.name)
        XCTAssertEqual(result, "Jakyla Labarge")
    }

    func testGetCopyValueForExpiration() {
        viewModel.nameOnCard = "Jakyla Labarge"
        viewModel.expirationDate = "12 / 39"
        viewModel.cardNumber = "4717219604213696"

        let result = viewModel.getCopyValueFor(.expiration)
        XCTAssertEqual(result, "1239")
    }

    func testClearValues() {
        viewModel.nameOnCard = "Jakyla Labarge"
        viewModel.expirationDate = "12 / 39"
        viewModel.cardNumber = "4717219604213696"
        viewModel.nameIsValid = false
        viewModel.showExpirationError = true
        viewModel.numberIsValid = false
        viewModel.creditCard = CreditCard(guid: "1",
                                          ccName: "Allen Burges",
                                          ccNumberEnc: "1234567891234567",
                                          ccNumberLast4: "4567",
                                          ccExpMonth: 1234567,
                                          ccExpYear: 2023,
                                          ccType: "VISA",
                                          timeCreated: 1234678,
                                          timeLastUsed: nil,
                                          timeLastModified: 123123,
                                          timesUsed: 123123)

        viewModel.clearValues()

        XCTAssert(viewModel.nameOnCard.isEmpty)
        XCTAssert(viewModel.cardNumber.isEmpty)
        XCTAssert(viewModel.expirationDate.isEmpty)
        XCTAssert(viewModel.nameIsValid)
        XCTAssertFalse(viewModel.showExpirationError)
        XCTAssert(viewModel.numberIsValid)
        XCTAssertNil(viewModel.creditCard)
    }

    func test_removeCreditCard_returnsStatusRemovedCardSuccessfully() {
        let exampleCreditCard = autofill.exampleCreditCard
        let expectation = expectation(description: "wait for credit card to be removed")

        viewModel.removeCreditCard(creditCard: exampleCreditCard) { status, success in
            XCTAssertEqual(status, .removedCard)
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_removeCreditCard_returnsStatusNone() {
        let exampleCreditCard = autofill.exampleCreditCard
        let expectation = expectation(description: "wait for credit card to be removed")
        enum TestError: Error { case example }

        autofill.deleteResult = (true, TestError.example)

        viewModel.removeCreditCard(creditCard: exampleCreditCard) { [autofill] status, success in
            XCTAssertEqual(status, .none)
            XCTAssertFalse(success)
            XCTAssertEqual(autofill?.deleteCreditCardsCalledCount, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_removeCreditCard_withNoCreditCard_returnsStatusNone() {
        let expectation = expectation(description: "wait for credit card to be removed")

        viewModel.removeCreditCard(creditCard: nil) { [autofill] status, success in
            XCTAssertEqual(status, .none)
            XCTAssertFalse(success)
            XCTAssertEqual(autofill?.deleteCreditCardsCalledCount, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_updateCreditCard_returnsSuccess() {
        viewModel.creditCard = autofill.exampleCreditCard
        viewModel.nameOnCard = samplePlainTextCard.ccName
        viewModel.cardNumber = samplePlainTextCard.ccNumber
        viewModel.expirationDate = "1288"
        autofill.updateResult = (true, nil)

        let expectation = expectation(description: "wait for credit card to be updated")

        viewModel.updateCreditCard { [autofill] status, error in
            XCTAssertNil(error)
            XCTAssertEqual(status, true)
            XCTAssertEqual(autofill?.updateCreditCardCalledCount, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_updateCreditCard_returnsError() {
        viewModel.creditCard = autofill.exampleCreditCard
        viewModel.nameOnCard = samplePlainTextCard.ccName
        viewModel.cardNumber = samplePlainTextCard.ccNumber
        viewModel.expirationDate = "1288"

        let expectation = expectation(description: "wait for credit card to be updated")
        enum TestError: Error { case example }
        autofill.updateResult = (true, TestError.example)

        viewModel.updateCreditCard { [autofill] status, error in
            XCTAssertNotNil(error)
            XCTAssertEqual(status, true)
            XCTAssertEqual(autofill?.updateCreditCardCalledCount, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_updateCreditCard_withoutValidCrediCard_ReturnsError() {
        let expectation = expectation(description: "wait for credit card to be updated")

        viewModel.updateCreditCard { [autofill] status, error in
            XCTAssertNotNil(error)
            XCTAssertEqual(status, true)
            XCTAssertEqual(autofill?.updateCreditCardCalledCount, 0)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: Helpers

    func rightBarButtonDisabled_Empty_CardName(
        state: CreditCardEditState) {
        guard state == .edit || state == .add else { return }
        viewModel.state = state
        viewModel.nameOnCard = ""
        viewModel.expirationDate = "123"
        viewModel.cardNumber = "4717219604213696"
        XCTAssertTrue(!viewModel.isRightBarButtonEnabled)
    }

    func rightBarButtonDisabled_Empty_CardName_Expiration(
        state: CreditCardEditState) {
        guard state == .edit || state == .add else { return }
        viewModel.state = state
        viewModel.nameOnCard = ""
        viewModel.expirationDate = ""
        viewModel.cardNumber = "4717219604213696"
        XCTAssertTrue(!viewModel.isRightBarButtonEnabled)
    }

    func rightBarButtonDisabled_Empty_CardName_Expiration_Number(
        state: CreditCardEditState) {
        guard state == .edit || state == .add else { return }
        viewModel.state = state
        viewModel.nameOnCard = ""
        viewModel.expirationDate = ""
        viewModel.cardNumber = ""
        XCTAssertTrue(!viewModel.isRightBarButtonEnabled)
    }
}
