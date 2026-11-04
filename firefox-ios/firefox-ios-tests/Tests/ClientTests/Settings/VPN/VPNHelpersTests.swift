// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import XCTest

@testable import Client

final class VPNHelpersTests: XCTestCase {
    private let theme = LightTheme()

    // MARK: - progressColor
    func test_progressColor_changesWithUsage() {
        let colors = theme.colors.faviconLetterColorSet

        XCTAssertEqual(VPNHelpers.progressColor(usageFraction: 0.5, theme: theme), Color(colors.iconAccentGreen4))
        XCTAssertEqual(
            VPNHelpers.progressColor(usageFraction: VPNHelpers.UX.warningUsageThreshold, theme: theme),
            Color(colors.iconAccentOrange4)
        )
        XCTAssertEqual(
            VPNHelpers.progressColor(usageFraction: 1, theme: theme),
            Color(colors.iconAccentRed4).opacity(VPNHelpers.UX.fullUsageOpacity)
        )
    }

    // MARK: - formatted
    func test_formatted_wholeNumber_addsOneDecimalPlace() {
        XCTAssertEqual(VPNHelpers.formatted(gigabytes: 5), "5.0")
    }

    func test_formatted_roundsToOneDecimalPlace() {
        XCTAssertEqual(VPNHelpers.formatted(gigabytes: 2.36), "2.4")
    }
}
