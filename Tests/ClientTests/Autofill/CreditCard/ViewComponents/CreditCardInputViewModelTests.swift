// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
@testable import Client

class CreditCardInputViewModelTests: XCTestCase {
    override class func setUp() {
        super.setUp()
    }

    override class func tearDown() {
        super.tearDown()
    }

    func testIsNameValidForWellFormedName() {
        let viewModel = CreditCardInputViewModel(fieldType: .name)

        viewModel.updateNameValidity(userInputtedText: "Tim Apple")
        XCTAssert(viewModel.isValid)
    }

    func testNameIsInvalidForBlankName() {
        let viewModel = CreditCardInputViewModel(fieldType: .name)

        viewModel.updateNameValidity(userInputtedText: "")
        XCTAssertFalse(viewModel.isValid)
    }

    func testNameIsInvalidForNonAlphabeticInput() {
        _ = XCTSkip()
        // These tests will be uncommented when these cases are addressed.
        // Currently, we have only basic checks but will update as the tasks are
        // created.
//        viewModel.updateNameValidity(userInputtedText: "1022992")
//        XCTAssertFalse(viewModel.isValid)
//
//        viewModel.updateNameValidity(userInputtedText: ")(*&^%$#@")
//        XCTAssertFalse(viewModel.isValid)
    }

    func testCardNumberFor16DigitsIsValid() {
        let viewModel = CreditCardInputViewModel(fieldType: .number)

        // Testing for 16 digits
        viewModel.updateCardNumberValidity(userInputtedText: "1234123412341234")
        XCTAssert(viewModel.isValid)
    }

    func testCardNumberFor15DigitsIsValid() {
        let viewModel = CreditCardInputViewModel(fieldType: .number)

        // Testing for 15 digits
        viewModel.updateCardNumberValidity(userInputtedText: "123412341234123")
        XCTAssert(viewModel.isValid)
    }

    func testCardNumberIsInvalidForAlphabeticInput() {
        let viewModel = CreditCardInputViewModel(fieldType: .number)

        viewModel.updateCardNumberValidity(userInputtedText: "this should not work")
        XCTAssertFalse(viewModel.isValid)
    }

    func testCardNumberIsInvalidForBlankInput() {
        let viewModel = CreditCardInputViewModel(fieldType: .number)

        viewModel.updateCardNumberValidity(userInputtedText: "")
        XCTAssertFalse(viewModel.isValid)
    }

    func testCardNumberIsInvalidForBad16CharcterInput() {
        _ = XCTSkip()
        // When card validation is done, this test can be included.
//        viewModel.updateCardNumberValidity(userInputtedText: "2023            ")
//        XCTAssertFalse(viewModel.isValid)
    }

    func testExpirationIsValidOnWellFormedInput() {
        let viewModel = CreditCardInputViewModel(fieldType: .expiration)

        viewModel.updateExpirationValidity(userInputtedText: "1230")
        XCTAssert(viewModel.isValid)

        viewModel.updateExpirationValidity(userInputtedText: "0926")
        XCTAssert(viewModel.isValid)
    }

    func testExpirationIsInValidOnIncorrectInput() {
        let viewModel = CreditCardInputViewModel(fieldType: .expiration)

        viewModel.updateExpirationValidity(userInputtedText: "0000")
        XCTAssertFalse(viewModel.isValid)

        viewModel.updateExpirationValidity(userInputtedText: "1525")
        XCTAssertFalse(viewModel.isValid)
    }

    func tetsExpirationIsInvalidOnBlankInput() {
        let viewModel = CreditCardInputViewModel(fieldType: .expiration)

        viewModel.updateExpirationValidity(userInputtedText: "")
        XCTAssertFalse(viewModel.isValid)
    }

    func testExpirationIsInvalidOnNonNumericInput() {
        let viewModel = CreditCardInputViewModel(fieldType: .expiration)

        viewModel.updateExpirationValidity(userInputtedText: "Firefox da best")
        XCTAssertFalse(viewModel.isValid)
    }

    func testUserInputFormattingForExpiry() {
        let viewModel = CreditCardInputViewModel(fieldType: .expiration)

        guard let testableString = viewModel.separate(inputType: .expiration, for: "1236") else {
            XCTFail()
            return
        }
        XCTAssertEqual(testableString, "12 / 36")

        guard let testableString = viewModel.separate(inputType: .expiration, for: "8888") else {
            XCTFail()
            return
        }
        XCTAssertEqual(testableString, "88 / 88")
    }

    func testCountNumbersIn() {
        let viewModel = CreditCardInputViewModel(fieldType: .name)

        XCTAssertEqual(viewModel.countNumbersIn(text: "12345"), 5)
    }
}
