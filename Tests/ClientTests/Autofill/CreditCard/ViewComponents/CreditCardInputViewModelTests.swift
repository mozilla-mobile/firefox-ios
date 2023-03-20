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

    func testIsNameValid() {
        let viewModel = CreditCardInputViewModel(fieldType: .name)

        viewModel.updateNameValidity(userInputtedText: "Tim Apple")
        XCTAssert(viewModel.isValid)

        viewModel.updateNameValidity(userInputtedText: "")
        XCTAssertFalse(viewModel.isValid)

        // These tests will be uncommented when these cases are addressed.
        // Currently, we have only basic checks but will update as the tasks are
        // created.
//        viewModel.updateNameValidity(userInputtedText: "1022992")
//        XCTAssertFalse(viewModel.isValid)
//
//        viewModel.updateNameValidity(userInputtedText: ")(*&^%$#@")
//        XCTAssertFalse(viewModel.isValid)
    }

    func testIsCardNumberValid() {
        let viewModel = CreditCardInputViewModel(fieldType: .number)

        viewModel.updateCardNumberValidity(userInputtedText: "1234123412341234")
        XCTAssert(viewModel.isValid)

        viewModel.updateCardNumberValidity(userInputtedText: "123412341234123")
        XCTAssert(viewModel.isValid)

        viewModel.updateCardNumberValidity(userInputtedText: "")
        XCTAssertFalse(viewModel.isValid)
    }

    func testIsExpirationValid() {
        let viewModel = CreditCardInputViewModel(fieldType: .expiration)

        viewModel.updateExpirationValidity(userInputtedText: "1224")
        XCTAssert(viewModel.isValid)

        viewModel.updateExpirationValidity(userInputtedText: "0000")
        XCTAssertFalse(viewModel.isValid)

        viewModel.updateExpirationValidity(userInputtedText: "1525")
        XCTAssertFalse(viewModel.isValid)

        viewModel.updateExpirationValidity(userInputtedText: "")
        XCTAssertFalse(viewModel.isValid)
    }

    func testIsSecurityCodeValid() {
        let viewModel = CreditCardInputViewModel(fieldType: .securityCode)

        viewModel.updateSecurityCodeValidity(userInputtedText: "000")
        XCTAssert(viewModel.isValid)

        viewModel.updateSecurityCodeValidity(userInputtedText: "")
        XCTAssertFalse(viewModel.isValid)
    }
}
