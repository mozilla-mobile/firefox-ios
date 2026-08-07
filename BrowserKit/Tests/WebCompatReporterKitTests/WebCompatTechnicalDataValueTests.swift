// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebCompatReporterKit

final class WebCompatTechnicalDataValueTests: XCTestCase {
    func testString_isQuoted() {
        XCTAssertEqual(
            WebCompatTechnicalDataViewModel.PreviewValue.string("https://example.com").displayText,
            "\"https://example.com\""
        )
    }

    func testList_isBracketedAndQuoted() {
        XCTAssertEqual(
            WebCompatTechnicalDataViewModel.PreviewValue.list(["en-US", "fr-FR"]).displayText,
            "[\"en-US\", \"fr-FR\"]"
        )
    }

    func testEmptyList_isEmptyBrackets() {
        XCTAssertEqual(WebCompatTechnicalDataViewModel.PreviewValue.list([]).displayText, "[]")
    }

    func testBool_isLowercaseLiteral() {
        XCTAssertEqual(WebCompatTechnicalDataViewModel.PreviewValue.bool(true).displayText, "true")
        XCTAssertEqual(WebCompatTechnicalDataViewModel.PreviewValue.bool(false).displayText, "false")
    }

    func testQuantity_isBareNumber() {
        XCTAssertEqual(WebCompatTechnicalDataViewModel.PreviewValue.quantity(4096).displayText, "4096")
    }

    func testNull_isNullLiteral() {
        XCTAssertEqual(WebCompatTechnicalDataViewModel.PreviewValue.null.displayText, "null")
    }
}
