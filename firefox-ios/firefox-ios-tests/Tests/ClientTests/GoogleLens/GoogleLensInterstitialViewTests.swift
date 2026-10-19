// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client

@MainActor
final class GoogleLensInterstitialViewTests: XCTestCase {
    func testDefaultBackdrop_usesMaterialAndBlocksInteractionWithCoveredContent() throws {
        let subject = GoogleLensInterstitialView(reduceTransparencyProvider: { false })
        subject.applyTheme(theme: LightTheme())
        let material = try XCTUnwrap(subject.subviews.first as? UIVisualEffectView)

        XCTAssertNotNil(material.effect)
        XCTAssertFalse(material.isHidden)
        XCTAssertEqual(subject.backgroundColor, .clear)
        XCTAssertTrue(subject.isUserInteractionEnabled)
        XCTAssertTrue(subject.accessibilityViewIsModal)
    }

    func testReduceTransparency_usesOpaqueThemedBackdrop() throws {
        let subject = GoogleLensInterstitialView(reduceTransparencyProvider: { true })
        subject.applyTheme(theme: LightTheme())
        let material = try XCTUnwrap(subject.subviews.first as? UIVisualEffectView)

        XCTAssertTrue(material.isHidden)
        XCTAssertEqual(subject.backgroundColor, LightTheme().colors.layerScrim.withAlphaComponent(1))
    }

    func testApplyTheme_updatesOpaqueBackdropForActiveTheme() {
        let subject = GoogleLensInterstitialView(reduceTransparencyProvider: { true })
        subject.applyTheme(theme: LightTheme())
        subject.applyTheme(theme: DarkTheme())

        XCTAssertEqual(subject.backgroundColor, DarkTheme().colors.layerScrim.withAlphaComponent(1))
    }
}
