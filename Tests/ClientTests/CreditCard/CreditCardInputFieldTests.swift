// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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

    func testCountNumbersIn() {
        let inputField = CreditCardInputField(inputType: .expiration,
                                              text: $testableString,
                                              showError: false,
                                              inputViewModel: viewModel)

        XCTAssertEqual(inputField.countNumbersIn(text: "12345"), 5)
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
}
