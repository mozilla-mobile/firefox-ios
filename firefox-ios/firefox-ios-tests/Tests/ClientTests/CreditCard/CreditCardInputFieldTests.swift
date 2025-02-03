// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Disabled: It will be updated in FXIOS-6128

import Foundation
import XCTest
import SwiftUI
import Common
@testable import Client

class CreditCardInputFieldTests: XCTestCase {
    var profile: MockProfile!
    var viewModel: CreditCardInputViewModel!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        viewModel = CreditCardInputViewModel(profile: profile)
    }

    override func tearDown() {
        profile = nil
        viewModel = nil
        super.tearDown()
    }

    func testInputFieldPropertiesOnName() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .name,
                                              showError: false,
                                              inputViewModel: viewModel)

        XCTAssertEqual(inputField.fieldHeadline, .CreditCard.EditCard.NameOnCardTitle)
        XCTAssertEqual(inputField.errorString, .CreditCard.ErrorState.NameOnCardSublabel)
        XCTAssertNil(inputField.delimiterCharacter)
        XCTAssertEqual(inputField.userInputLimit, 100)
        XCTAssertEqual(inputField.formattedTextLimit, 100)
        XCTAssertEqual(inputField.keyboardType, .alphabet)
    }

    func testInputFieldPropertiesOnCard() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .number,
                                              showError: false,
                                              inputViewModel: viewModel)

        XCTAssertEqual(inputField.fieldHeadline, .CreditCard.EditCard.CardNumberTitle)
        XCTAssertEqual(inputField.errorString, .CreditCard.ErrorState.CardNumberSublabel)
        XCTAssertEqual(inputField.delimiterCharacter, "-")
        XCTAssertEqual(inputField.userInputLimit, 19)
        XCTAssertEqual(inputField.formattedTextLimit, 23)
        XCTAssertEqual(inputField.keyboardType, .numberPad)
    }

    func testInputFieldPropertiesOnExpiration() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .expiration,
                                              showError: false,
                                              inputViewModel: viewModel)

        XCTAssertEqual(inputField.fieldHeadline, .CreditCard.EditCard.CardExpirationDateTitle)
        XCTAssertEqual(inputField.errorString, .CreditCard.ErrorState.CardExpirationDateSublabel)
        XCTAssertEqual(inputField.delimiterCharacter, " / ")
        XCTAssertEqual(inputField.userInputLimit, 4)
        XCTAssertEqual(inputField.formattedTextLimit, 7)
        XCTAssertEqual(inputField.keyboardType, .numberPad)
    }

    func testValidNameInput() {
        viewModel.nameOnCard = "Test User"
        let result = viewModel.nameIsValid
        XCTAssertTrue(result)
    }

    func testIsNameValid() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .name,
                                              showError: false,
                                              inputViewModel: viewModel)
        XCTAssertTrue(inputField.isNameValid(val: "Test Name"))
        XCTAssertFalse(inputField.isNameValid(val: ""))
    }

    func testIsNumberValid() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .name,
                                              showError: false,
                                              inputViewModel: viewModel)
        XCTAssertTrue(inputField.isNumberValid(val: "4242123412341234"))
        XCTAssertFalse(inputField.isNumberValid(val: "1234123412341234"))
        XCTAssertFalse(inputField.isNumberValid(val: "1234"))
        XCTAssertFalse(inputField.isNumberValid(val: "4242 1234 1234 1234"))
        XCTAssertFalse(inputField.isNumberValid(val: "4242x123412341234"))
        XCTAssertFalse(inputField.isNumberValid(val: "42421234123412341234"))
        XCTAssertFalse(inputField.isNumberValid(val: "4242"))
    }

    func testIsExpirationValid() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .name,
                                              showError: false,
                                              inputViewModel: viewModel)
        XCTAssertFalse(inputField.isExpirationValid(val: "123"))
        XCTAssertFalse(inputField.isExpirationValid(val: "3434"))
        XCTAssertTrue(inputField.isExpirationValid(val: "1234"))
    }

    func testBlankNameInput() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .name,
                                              showError: false,
                                              inputViewModel: viewModel)
        _ = inputField.updateInputValidity()
        XCTAssertFalse(inputField.isNameValid(val: ""))
    }

    func testValidCardInput() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .number,
                                              showError: false,
                                              inputViewModel: viewModel)

        inputField.handleTextInputWith("412240004000400", and: "4122400040004000")
        XCTAssert(viewModel.numberIsValid)
        XCTAssertEqual(viewModel.cardNumber, "4122400040004000")
    }

    func testInvalidShorterCardInput() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .number,
                                              showError: false,
                                              inputViewModel: viewModel)

        inputField.handleTextInputWith("4", and: "44")
        XCTAssertFalse(inputField.isNumberValid(val: "44"))
    }

    func testValidExpirationInput() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .expiration,
                                              showError: false,
                                              inputViewModel: viewModel)

        inputField.handleTextInputWith("125", and: "1250")
        XCTAssertTrue(inputField.isExpirationValid(val: "1250"))
        XCTAssertFalse(viewModel.showExpirationError)
    }

    func testInvalidShortenedExpirationInput() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .expiration,
                                              showError: false,
                                              inputViewModel: viewModel)

        inputField.handleTextInputWith("1255", and: "125")
        XCTAssertFalse(inputField.isExpirationValid(val: "125"))
    }

    func testConcealCardNum() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .number,
                                              showError: false,
                                              inputViewModel: viewModel)

        // 16 digit card number
        viewModel.cardNumber = "1234123412341234"

        let result = inputField.concealedCardNum()
        XCTAssertEqual(result, "••••••••••••1234")
    }

    func testConcealCardNumOnEmpty() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .number,
                                              showError: false,
                                              inputViewModel: viewModel)

        viewModel.cardNumber = ""

        let result = inputField.concealedCardNum()
        XCTAssertEqual(result, "")
    }

    func testRevealCardNumber() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .number,
                                              showError: false,
                                              inputViewModel: viewModel)

        // 16 digit unformatted card number
        viewModel.cardNumber = "4444444444444444"

        let result = inputField.revealCardNum()
        XCTAssertEqual(result, "4444-4444-4444-4444")
    }

    func testRevealCardNumberOnEmpty() {
        let inputField = CreditCardInputField(windowUUID: WindowUUID.XCTestDefaultUUID,
                                              inputType: .number,
                                              showError: false,
                                              inputViewModel: viewModel)

        // Empty card num
        viewModel.cardNumber = ""

        let result = inputField.revealCardNum()
        XCTAssertEqual(result, "")
    }
}
