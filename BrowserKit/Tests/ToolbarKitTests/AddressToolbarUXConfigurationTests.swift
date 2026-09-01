// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import ToolbarKit

final class AddressToolbarUXConfigurationTests: XCTestCase {
    private let theme = LightTheme()

    func testAddressToolbarBackgroundColorIsClearWhenMinimized() {
        let subject = AddressToolbarUXConfiguration.default(isAddressBarMinimized: true)

        XCTAssertEqual(subject.addressToolbarBackgroundColor(theme: theme), .clear)
    }

    func testAddressToolbarBackgroundColorIsClearWhenMinimizedAndBlurring() {
        let subject = AddressToolbarUXConfiguration.default(backgroundAlpha: 0,
                                                            isAddressBarMinimized: true,
                                                            shouldBlur: true)

        XCTAssertEqual(subject.addressToolbarBackgroundColor(theme: theme), .clear)
    }

    func testAddressToolbarBackgroundColorPaintsChromeWhenExpanded() {
        let subject = AddressToolbarUXConfiguration.default(isAddressBarMinimized: false)

        XCTAssertEqual(subject.addressToolbarBackgroundColor(theme: theme), theme.colors.layer1)
    }

    func testAddressToolbarBackgroundColorAppliesBackgroundAlphaWhenExpandedAndBlurring() {
        let subject = AddressToolbarUXConfiguration.default(backgroundAlpha: 0.5,
                                                            isAddressBarMinimized: false,
                                                            shouldBlur: true)

        XCTAssertEqual(subject.addressToolbarBackgroundColor(theme: theme),
                       theme.colors.layer1.withAlphaComponent(0.5))
    }
}
