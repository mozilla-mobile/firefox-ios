// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class DynamicFontHelperTests: XCTestCase {
    func testPreferredFont_returnsExpectedFont() {
        let result = DefaultDynamicFontHelper.preferredFont(withTextStyle: .caption1, size: 11)

        XCTAssertEqual(result.pointSize, 11)
        XCTAssertEqual(result.fontName, ".SFUI-Regular")
    }

    func testPreferredBoldFont_returnsExpectedFont() {
        let result = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .body, size: 10)

        XCTAssertEqual(result.pointSize, 10)
        XCTAssertEqual(result.fontName, ".SFUI-Bold")
    }
}
