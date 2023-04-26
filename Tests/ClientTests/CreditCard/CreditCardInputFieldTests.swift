// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Disabled: It will be updated in FXIOS-6128

/*
import Foundation
import XCTest
import SwiftUI
@testable import Client


class CreditCardInputFieldTests: XCTestCase {
    @State var testableString: String = ""
    var profile: MockProfile!
    var viewModel: CreditCardInputViewModel!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        viewModel = CreditCardInputViewModel(profile: profile)
    }

    override func tearDown() {
        super.tearDown()

        profile = nil
        viewModel = nil
        testableString = ""
    }

    func testInputFieldPropertiesOnName() {
        let inputField = CreditCardInputField(inputType: .name,
                                              text: $testableString,
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
        let inputField = CreditCardInputField(inputType: .number,
                                              text: $testableString,
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
        let inputField = CreditCardInputField(inputType: .expiration,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        XCTAssertEqual(inputField.fieldHeadline, .CreditCard.EditCard.CardExpirationDateTitle)
        XCTAssertEqual(inputField.errorString, .CreditCard.ErrorState.CardExpirationDateSublabel)
        XCTAssertEqual(inputField.delimiterCharacter, " / ")
        XCTAssertEqual(inputField.userInputLimit, 4)
        XCTAssertEqual(inputField.formattedTextLimit, 7)
        XCTAssertEqual(inputField.keyboardType, .numberPad)
    }

    func testCountNumbersOnNumericInput() {
        let inputField = CreditCardInputField(inputType: .expiration,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        XCTAssertEqual(inputField.countNumbersIn(text: "12345"), 5)
    }

    func testCountNumbersOnAlphanumericAndSpecialCharcatersInput() {
        let inputField = CreditCardInputField(inputType: .expiration,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        XCTAssertEqual(inputField.countNumbersIn(text: "//123)*gsgki45}{}{:"), 5)
    }

    func testUserInputFormattingForExpiry() {
        let inputField = CreditCardInputField(inputType: .expiration,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        guard let testableString = inputField.separate(inputType: .expiration, for: "1236") else {
            XCTFail()
            return
        }
        XCTAssertEqual(testableString, "12 / 36")

        guard let testableString = inputField.separate(inputType: .expiration, for: "8888") else {
            XCTFail()
            return
        }
        XCTAssertEqual(testableString, "88 / 88")
    }

    func testValidNameInput() {
        let inputField = CreditCardInputField(inputType: .name,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        inputField.handleTextInputWith("", and: "H")
        XCTAssert(viewModel.nameIsValid)
        XCTAssertEqual(viewModel.nameOnCard, "H")
    }

    func testBlankNameInput() {
        let inputField = CreditCardInputField(inputType: .name,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        inputField.handleTextInputWith("H", and: "")
        XCTAssertFalse(viewModel.nameIsValid)
    }

    func testValidCardInput() {
        let inputField = CreditCardInputField(inputType: .number,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        inputField.handleTextInputWith("412240004000400", and: "4122400040004000")
        XCTAssert(viewModel.numberIsValid)
        XCTAssertEqual(viewModel.cardNumber, "4122400040004000")
    }

    func testInvalidShorterCardInput() {
        let inputField = CreditCardInputField(inputType: .number,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        inputField.handleTextInputWith("4", and: "44")
        XCTAssertFalse(viewModel.numberIsValid)
    }

    func testValidExpirationInput() {
        let inputField = CreditCardInputField(inputType: .expiration,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        inputField.handleTextInputWith("125", and: "1250")
        XCTAssertEqual(viewModel.expirationDate, "1250")
        XCTAssert(viewModel.expirationIsValid)
    }

    func testInvalidShortenedExpirationInput() {
        let inputField = CreditCardInputField(inputType: .expiration,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        inputField.handleTextInputWith("1255", and: "125")
        XCTAssertFalse(viewModel.expirationIsValid)
    }

    func testSanitizeGoodCardNumber() {
        let inputField = CreditCardInputField(inputType: .number,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        let result = inputField.sanitizeInputOn("4100100010001000")
        XCTAssertEqual(result, "4100100010001000")
    }

    func testSanitizeGarbledCardNumber() {
        let inputField = CreditCardInputField(inputType: .number,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        let result = inputField.sanitizeInputOn("4100^&*(*&^%10    00100:><>?><> 0  *&*(100))----!!!!!0")
        XCTAssertEqual(result, "4100100010001000")
    }

    func testSanitizeGoodExpiryInput() {
        let inputField = CreditCardInputField(inputType: .expiration,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        let result = inputField.sanitizeInputOn("1029")
        XCTAssertEqual(result, "1029")
    }

    func testSanitizeGarbledExpiryInput() {
        let inputField = CreditCardInputField(inputType: .expiration,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        let result = inputField.sanitizeInputOn(" 1  )(*&^0 ><>::?:  2!!!&**&*~~@@@9")
        XCTAssertEqual(result, "1029")
    }
}
*/
