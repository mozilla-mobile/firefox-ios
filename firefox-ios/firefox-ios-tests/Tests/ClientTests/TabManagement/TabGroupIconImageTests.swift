// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import Client

final class TabGroupIconImageTests: XCTestCase {
    private let symbolFallbacks = [
        (preferred: "sparkles.2", fallback: "sparkles"),
        (preferred: "headphones.over.ear", fallback: "headphones"),
        (preferred: "wallet.bifold.fill", fallback: "wallet.pass.fill")
    ]

    func testSystemImageName_withSymbolOutsidePicker_preservesName() {
        let icon = TabGroupIcon.sfSymbol("sun.max.fill")

        XCTAssertEqual(icon.systemImageName, "sun.max.fill")
        XCTAssertNotNil(UIImage(systemName: icon.systemImageName))
    }

    func testSystemImageName_withUnknownSymbol_usesDefaultSymbol() {
        let icon = TabGroupIcon.sfSymbol("unavailable-tab-group-symbol")

        XCTAssertEqual(icon.systemImageName, "square.stack.fill")
    }

    func testSystemImageName_withPreferredSymbolAvailable_preservesPreferredName() {
        for symbols in symbolFallbacks {
            let icon = TabGroupIcon.sfSymbol(symbols.preferred)

            let name = icon.systemImageName(isAvailable: { [symbols.preferred, symbols.fallback].contains($0) })

            XCTAssertEqual(name, symbols.preferred)
        }
    }

    func testSystemImageName_withOnlyFallbackSymbolAvailable_preservesStoredIcon() {
        for symbols in symbolFallbacks {
            let icon = TabGroupIcon.sfSymbol(symbols.preferred)

            let name = icon.systemImageName(isAvailable: { $0 == symbols.fallback })

            XCTAssertEqual(name, symbols.fallback)
            XCTAssertEqual(icon, .sfSymbol(symbols.preferred))
        }
    }

    func testSystemImageName_withNoSymbolAvailable_usesDefaultSymbol() {
        for symbols in symbolFallbacks {
            let icon = TabGroupIcon.sfSymbol(symbols.preferred)

            let name = icon.systemImageName(isAvailable: { _ in false })

            XCTAssertEqual(name, "square.stack.fill")
        }
    }
}
