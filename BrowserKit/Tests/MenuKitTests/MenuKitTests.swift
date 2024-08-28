// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import MenuKit

final class MenuKitTests: XCTestCase {
    func testMenuElement_initializesCorrectly() {
        let subject = MenuElement(
            iconName: "test",
            isEnabled: true,
            isActive: true,
            hasSubmenu: false,
            a11yLabel: "test",
            a11yHint: nil,
            a11yId: "test"
        )
        let expectedResult = MenuElement(
            iconName: "test",
            isEnabled: true,
            isActive: true,
            hasSubmenu: false,
            a11yLabel: "test",
            a11yHint: nil,
            a11yId: "test"
        )

        XCTAssertEqual(subject, expectedResult)
    }
}
