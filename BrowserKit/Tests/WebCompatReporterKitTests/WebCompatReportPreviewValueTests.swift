// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebCompatReporterKit

final class WebCompatReportPreviewValueTests: XCTestCase {
    func testString_isQuoted() {
        XCTAssertEqual(WebCompatReportPreviewViewModel.PreviewValue.string("https://example.com").displayText,
                       "\"https://example.com\"")
    }

    func testList_isBracketedAndQuoted() {
        XCTAssertEqual(WebCompatReportPreviewViewModel.PreviewValue.list(["en-US", "fr-FR"]).displayText,
                       "[\"en-US\", \"fr-FR\"]")
    }

    func testEmptyList_isEmptyBrackets() {
        XCTAssertEqual(WebCompatReportPreviewViewModel.PreviewValue.list([]).displayText, "[]")
    }

    func testBool_isLowercaseLiteral() {
        XCTAssertEqual(WebCompatReportPreviewViewModel.PreviewValue.bool(true).displayText, "true")
        XCTAssertEqual(WebCompatReportPreviewViewModel.PreviewValue.bool(false).displayText, "false")
    }

    func testQuantity_isBareNumber() {
        XCTAssertEqual(WebCompatReportPreviewViewModel.PreviewValue.quantity(4096).displayText, "4096")
    }

    func testNull_isNullLiteral() {
        XCTAssertEqual(WebCompatReportPreviewViewModel.PreviewValue.null.displayText, "null")
    }
}
