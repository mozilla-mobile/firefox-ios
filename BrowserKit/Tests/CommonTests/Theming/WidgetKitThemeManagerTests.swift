// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

@MainActor
final class WidgetKitThemeManagerTests: XCTestCase {
    func testWindowNonspecificTheme_isNovaTheme() {
        let subject = WidgetKitThemeManager()

        XCTAssertTrue(subject.windowNonspecificTheme().isNova)
    }

    func testGetCurrentTheme_isNovaTheme() {
        let subject = WidgetKitThemeManager()

        XCTAssertTrue(subject.getCurrentTheme(for: nil).isNova)
    }

    func testResolvedTheme_withPrivateShown_returnsNovaPrivateTheme() {
        let subject = WidgetKitThemeManager()

        let theme = subject.resolvedTheme(with: true)

        XCTAssertTrue(theme.isNova)
        XCTAssertNotEqual(theme.type, .privateMode)
    }

    func testResolvedTheme_withPrivateNotShown_returnsNovaTheme() {
        let subject = WidgetKitThemeManager()

        let theme = subject.resolvedTheme(with: false)

        XCTAssertTrue(theme.isNova)
        XCTAssertNotEqual(theme.type, .privateMode)
    }

    func testSetters_areNoOp() {
        let subject = WidgetKitThemeManager()

        subject.setSystemTheme(isOn: false)
        subject.setManualTheme(to: .dark)
        subject.setAutomaticBrightness(isOn: true)
        subject.setAutomaticBrightnessValue(0.5)
        subject.setPrivateTheme(isOn: true, for: .XCTestDefaultUUID)

        XCTAssertFalse(subject.getPrivateThemeIsOn(for: .XCTestDefaultUUID))
        XCTAssertTrue(subject.systemThemeIsOn)
        XCTAssertFalse(subject.automaticBrightnessIsOn)
    }
}
