// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import Common

class NovaMissingTokenTests: XCTestCase {
    override func tearDown() {
        NovaMissingToken.reportMisuse = { assertionFailure($0) }
        super.tearDown()
    }

    func testColor_returnsTheExpectedColor() {
        NovaMissingToken.reportMisuse = { _ in }

        #if DEBUG
        XCTAssertEqual(NovaMissingToken.color("gradient"), FXColors.Red60)
        #else
        XCTAssertEqual(NovaMissingToken.color("gradient"), .clear)
        #endif
    }

    func testGradient_returnsTheExpectedGradient() {
        NovaMissingToken.reportMisuse = { _ in }

        #if DEBUG
        XCTAssertEqual(NovaMissingToken.gradient("gradient").colors, [FXColors.Red60])
        #else
        XCTAssertEqual(NovaMissingToken.gradient("gradient").colors, [.clear])
        #endif
    }

    func testColor_flagsAWrongUse_withTheTokenName() {
        var flaggedMessage: String?
        NovaMissingToken.reportMisuse = { flaggedMessage = $0 }

        _ = NovaMissingToken.color("textToast")

        #if DEBUG
        XCTAssertEqual(flaggedMessage, "Nova only token 'textToast' was used from a classic theme")
        #else
        XCTAssertNil(flaggedMessage)
        #endif
    }

    /// Using a Nova only token in a classic theme should be flagged as a misuse.
    func testEachNovaOnlyToken_onEachClassicTheme_isFlagged() {
        let classicThemes: [(name: String, theme: Theme)] = [
            ("LightTheme", LightTheme()),
            ("DarkTheme", DarkTheme()),
            ("PrivateModeTheme", PrivateModeTheme())
        ]

        let novaOnlyTokenReads: [(name: String, read: (ThemeColourPalette) -> Void)] = [
            ("layerAccentSubtle", { _ = $0.layerAccentSubtle }),
            ("layerInverse", { _ = $0.layerInverse }),
            ("layerGlassTintNova", { _ = $0.layerGlassTintNova }),
            ("textToast", { _ = $0.textToast }),
            ("iconInverted", { _ = $0.iconInverted }),
            ("iconOnColorDisabled", { _ = $0.iconOnColorDisabled }),
            ("iconPrivate", { _ = $0.iconPrivate }),
            ("borderStrong", { _ = $0.borderStrong }),
            ("borderRadioButtonDefault", { _ = $0.borderRadioButtonDefault }),
            ("gradient", { _ = $0.gradient }),
            ("gradientAccent", { _ = $0.gradientAccent }),
            ("gradientAccentSubtle", { _ = $0.gradientAccentSubtle }),
            ("gradientAIStrong", { _ = $0.gradientAIStrong }),
            ("gradientBorder", { _ = $0.gradientBorder }),
            ("gradientPrivacy", { _ = $0.gradientPrivacy }),
            ("gradientPrivacyMask", { _ = $0.gradientPrivacyMask })
        ]

        for classicTheme in classicThemes {
            for token in novaOnlyTokenReads {
                var flagged = false
                NovaMissingToken.reportMisuse = { _ in flagged = true }

                token.read(classicTheme.theme.colors)

                #if DEBUG
                XCTAssertTrue(flagged, "\(token.name) on \(classicTheme.name) should be flagged as a Nova-only misuse")
                #else
                XCTAssertFalse(flagged, "\(token.name) on \(classicTheme.name) should not report outside DEBUG")
                #endif
            }
        }
    }
}
