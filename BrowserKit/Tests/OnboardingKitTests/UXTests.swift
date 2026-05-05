// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import XCTest
@testable import Common
@testable import OnboardingKit

final class UXTests: XCTestCase {
    // MARK: - Tests for cardSecondaryContainerPadding(for:)

    func testCardSecondaryContainerPadding_accessibilityExtraExtraExtraLarge_returnsZero() {
        let sut = UX.CardView.cardSecondaryContainerPadding(for: .accessibilityExtraExtraExtraLarge)
        XCTAssertEqual(sut, 0)
    }

    func testCardSecondaryContainerPadding_accessibilityExtraExtraLarge_returnsZero() {
        let sut = UX.CardView.cardSecondaryContainerPadding(for: .accessibilityExtraExtraLarge)
        XCTAssertEqual(sut, 0)
    }

    func testCardSecondaryContainerPadding_accessibilityExtraLarge_returnsZero() {
        let sut = UX.CardView.cardSecondaryContainerPadding(for: .accessibilityExtraLarge)
        XCTAssertEqual(sut, 0)
    }

    func testCardSecondaryContainerPadding_large_returnsDefault() {
        let sut = UX.CardView.cardSecondaryContainerPadding(for: .large)
        XCTAssertEqual(sut, 32)
    }

    func testCardSecondaryContainerPadding_extraSmall_returnsDefault() {
        let sut = UX.CardView.cardSecondaryContainerPadding(for: .extraSmall)
        XCTAssertEqual(sut, 32)
    }

    // MARK: - Tests for locale-dependent methods — Japanese

    func testTitleFont_japanese_returnsRegularWeight() {
        let sut = UX.CardView.titleFont(forLanguageCode: "ja")
        XCTAssertEqual(sut.weight, .regular)
    }

    func testTextAlignment_japanese_returnsLeading() {
        let sut = UX.CardView.textAlignment(forLanguageCode: "ja")
        XCTAssertEqual(sut, .leading)
    }

    func testHorizontalAlignment_japanese_returnsLeading() {
        let sut = UX.CardView.horizontalAlignment(forLanguageCode: "ja")
        XCTAssertEqual(sut, .leading)
    }

    func testFrameAlignment_japanese_returnsLeading() {
        let sut = UX.CardView.frameAlignment(forLanguageCode: "ja")
        XCTAssertEqual(sut, .leading)
    }

    // MARK: - Tests for locale-dependent methods — non-Japanese

    func testTitleFont_english_returnsBoldWeight() {
        let sut = UX.CardView.titleFont(forLanguageCode: "en")
        XCTAssertEqual(sut.weight, .bold)
    }

    func testTextAlignment_english_returnsCenter() {
        let sut = UX.CardView.textAlignment(forLanguageCode: "en")
        XCTAssertEqual(sut, .center)
    }

    func testHorizontalAlignment_english_returnsCenter() {
        let sut = UX.CardView.horizontalAlignment(forLanguageCode: "en")
        XCTAssertEqual(sut, .center)
    }

    func testFrameAlignment_english_returnsCenter() {
        let sut = UX.CardView.frameAlignment(forLanguageCode: "en")
        XCTAssertEqual(sut, .center)
    }

    // MARK: - Tests for locale-dependent methods — nil languageCode

    func testTitleFont_nilLanguageCode_returnsBoldWeight() {
        let sut = UX.CardView.titleFont(forLanguageCode: nil)
        XCTAssertEqual(sut.weight, .bold)
    }

    func testTextAlignment_nilLanguageCode_returnsCenter() {
        let sut = UX.CardView.textAlignment(forLanguageCode: nil)
        XCTAssertEqual(sut, .center)
    }

    func testHorizontalAlignment_nilLanguageCode_returnsCenter() {
        let sut = UX.CardView.horizontalAlignment(forLanguageCode: nil)
        XCTAssertEqual(sut, .center)
    }

    func testFrameAlignment_nilLanguageCode_returnsCenter() {
        let sut = UX.CardView.frameAlignment(forLanguageCode: nil)
        XCTAssertEqual(sut, .center)
    }
}
