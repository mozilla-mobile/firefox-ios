// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

final class ToolbarHelperTests: XCTestCase {
    private func traitCollection(
        vertical: UIUserInterfaceSizeClass,
        horizontal: UIUserInterfaceSizeClass
    ) -> UITraitCollection {
        UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: vertical),
            UITraitCollection(horizontalSizeClass: horizontal)
        ])
    }

    func test_isSwipingTabsEnabled_onPad_returnsFalse() async {
        let subject = await ToolbarHelper(userInterfaceIdiom: .pad)
        XCTAssertFalse(subject.isSwipingTabsEnabled)
    }

    func test_isSwipingTabsEnabled_onPhone_returnsTrue() async {
        let subject = await ToolbarHelper(userInterfaceIdiom: .phone)
        XCTAssertTrue(subject.isSwipingTabsEnabled)
    }

    func test_shouldShowNavigationToolbar_regularVerticalCompactHorizontal_returnsTrue() async {
        let subject = await ToolbarHelper(userInterfaceIdiom: .phone)
        let traits = traitCollection(vertical: .regular, horizontal: .compact)
        XCTAssertTrue(subject.shouldShowNavigationToolbar(for: traits))
    }

    func test_shouldShowNavigationToolbar_regularVerticalRegularHorizontal_returnsFalse() async {
        let subject = await ToolbarHelper(userInterfaceIdiom: .pad)
        let traits = traitCollection(vertical: .regular, horizontal: .regular)
        XCTAssertFalse(subject.shouldShowNavigationToolbar(for: traits))
    }

    func test_shouldShowNavigationToolbar_compactVerticalRegularHorizontal_returnsFalse() async {
        let subject = await ToolbarHelper(userInterfaceIdiom: .phone)
        let traits = traitCollection(vertical: .compact, horizontal: .regular)
        XCTAssertFalse(subject.shouldShowNavigationToolbar(for: traits))
    }

    func test_shouldShowTopTabs_regularVerticalRegularHorizontal_returnsTrue() async {
        let subject = await ToolbarHelper(userInterfaceIdiom: .pad)
        let traits = traitCollection(vertical: .regular, horizontal: .regular)
        XCTAssertTrue(subject.shouldShowTopTabs(for: traits))
    }

    func test_shouldShowTopTabs_nonRegularSizeClasses_returnsFalse() async {
        let subject = await ToolbarHelper(userInterfaceIdiom: .phone)
        let traits = traitCollection(vertical: .regular, horizontal: .compact)
        XCTAssertFalse(subject.shouldShowTopTabs(for: traits))
    }

    func test_shouldBlur_whenReduceTransparencyEnabled_returnsFalse() async {
        let subject = await ToolbarHelper(
            userInterfaceIdiom: .phone,
            reduceTransparencyProvider: { true }
        )
        let shouldBlur = await subject.shouldBlur()
        XCTAssertFalse(shouldBlur)
        let alpha = await subject.glassEffectAlpha
        XCTAssertEqual(alpha, 1)
    }

    func test_shouldBlur_whenReduceTransparencyDisabled_returnsTrue() async {
        let subject = await ToolbarHelper(
            userInterfaceIdiom: .phone,
            reduceTransparencyProvider: { false }
        )
        let shouldBlur = await subject.shouldBlur()
        XCTAssertTrue(shouldBlur)
        let alpha = await subject.glassEffectAlpha
        XCTAssertTrue([0, 0.85].contains(alpha))
    }

    func test_getLockIconState_secureWebsiteMode_returnsExpectedValues() async {
        let subject = await ToolbarHelper(userInterfaceIdiom: .phone)
        let state = subject.getLockIconState(hasOnlySecureContent: true, isWebsiteMode: true)

        XCTAssertEqual(state.imageName, StandardImageIdentifiers.Small.shieldCheckmarkFill)
        XCTAssertEqual(state.a11yId, AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon)
        XCTAssertTrue(state.needsTheming)
    }

    func test_getLockIconState_insecureWebsiteMode_returnsExpectedValues() async {
        let subject = await ToolbarHelper(userInterfaceIdiom: .phone)
        let state = subject.getLockIconState(hasOnlySecureContent: false, isWebsiteMode: true)

        XCTAssertEqual(state.imageName, StandardImageIdentifiers.Small.shieldSlashFillMulticolor)
        XCTAssertEqual(state.a11yId, AccessibilityIdentifiers.Browser.AddressToolbar.lockIconOff)
        XCTAssertFalse(state.needsTheming)
    }

    func test_getLockIconState_notWebsiteMode_hidesIconButKeepsA11yId() async {
        let subject = await ToolbarHelper(userInterfaceIdiom: .phone)
        let state = subject.getLockIconState(hasOnlySecureContent: true, isWebsiteMode: false)

        XCTAssertNil(state.imageName)
        XCTAssertEqual(state.a11yId, AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon)
        XCTAssertTrue(state.needsTheming)
    }
}

