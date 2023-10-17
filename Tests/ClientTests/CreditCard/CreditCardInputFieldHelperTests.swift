// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class CreditCardInputFieldHelperTests: XCTestCase {
    var helper: CreditCardInputFieldHelper!

    func configureForTestsWith(_ inputType: CreditCardInputType) {
        helper = CreditCardInputFieldHelper(inputType: inputType)
    }

    func testSanitizeGarbledForExpiryInputOn() {
        let helper = CreditCardInputFieldHelper(inputType: .expiration)

        let result = helper.sanitizeInputOn(" 1  )(*&^0 ><>::?:  2!!!&**&*~~@@@9")
        XCTAssertEqual(result, "1029")
    }

    func testSanitizeValidExpiryInput() {
        let helper = CreditCardInputFieldHelper(inputType: .expiration)

        let result = helper.sanitizeInputOn("1029")
        XCTAssertEqual(result, "1029")
    }

    func testSanitizeGarbledCardNumber() {
        let helper = CreditCardInputFieldHelper(inputType: .number)

        let result = helper.sanitizeInputOn("4100^&*(*&^%10    00100:><>?><> 0  *&*(100))----!!!!!0")
        XCTAssertEqual(result, "4100100010001000")
    }

    func testSanitizeValidCardNumber() {
        let helper = CreditCardInputFieldHelper(inputType: .number)

        let result = helper.sanitizeInputOn("4100100010001000")
        XCTAssertEqual(result, "4100100010001000")
    }

    func testCountNumbersOnNumericInput() {
        let helper = CreditCardInputFieldHelper(inputType: .expiration)

        XCTAssertEqual(helper.countNumbersIn(text: "12345"), 5)
    }

    func testCountNumbersOnAlphanumericAndSpecialCharcatersInput() {
        let helper = CreditCardInputFieldHelper(inputType: .expiration)

        XCTAssertEqual(helper.countNumbersIn(text: "//123)*gsgki45}{}{:"), 5)
    }

    func testFormatExpiration() {
        let helper = CreditCardInputFieldHelper(inputType: .expiration)

        let result = helper.formatExpiration(for: "1223")
        XCTAssertEqual(result, "12 / 23")
    }

    func testFormatCardNumber() {
        let helper = CreditCardInputFieldHelper(inputType: .number)

        let result = helper.addCreditCardDelimiter(sanitizedCCNum: "4122412241224122")
        XCTAssertEqual(result, "4122-4122-4122-4122")
    }
}
