// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import Client

final class TabGroupIconImageTests: XCTestCase {
    func testSystemImageName_withSymbolOutsidePicker_preservesName() {
        let icon = TabGroupIcon.sfSymbol("sun.max.fill")

        XCTAssertEqual(icon.systemImageName, "sun.max.fill")
        XCTAssertNotNil(UIImage(systemName: icon.systemImageName))
    }

    func testSystemImageName_withUnknownSymbol_usesDefaultSymbol() {
        let icon = TabGroupIcon.sfSymbol("unavailable-tab-group-symbol")

        XCTAssertEqual(icon.systemImageName, "square.stack.fill")
    }
}
