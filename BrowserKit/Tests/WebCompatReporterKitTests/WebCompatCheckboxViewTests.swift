// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatCheckboxViewTests: XCTestCase {
    func testUpdate_whenChecked_fillsTheCircleAndShowsTheCheckmark() throws {
        let subject = WebCompatCheckboxView()

        subject.update(isChecked: true, theme: LightTheme())

        let checkmark = try XCTUnwrap(firstSubview(ofType: UIImageView.self, in: subject))
        XCTAssertFalse(checkmark.isHidden)
        XCTAssertEqual(checkmark.tintColor, LightTheme().colors.textInverted)
        XCTAssertEqual(subject.backgroundColor, LightTheme().colors.actionPrimary)
        XCTAssertEqual(subject.layer.borderWidth, 0)
    }

    func testUpdate_whenUnchecked_ringsTheCircleAndHidesTheCheckmark() throws {
        let subject = WebCompatCheckboxView()

        subject.update(isChecked: false, theme: LightTheme())

        let checkmark = try XCTUnwrap(firstSubview(ofType: UIImageView.self, in: subject))
        XCTAssertTrue(checkmark.isHidden)
        XCTAssertEqual(subject.backgroundColor, .clear)
        XCTAssertEqual(subject.layer.borderWidth, WebCompatReporterUX.Checkbox.borderWidth)
    }

    // The acorn checkmark asset is itself 24pt, so pinning it with insets rather than sizing it
    // inflates the circle to 36. Guards that regression at the source.
    func testIntrinsicContentSize_matchesTheCheckboxSizeSoTheGlyphCannotInflateIt() {
        let subject = WebCompatCheckboxView()

        XCTAssertEqual(subject.intrinsicContentSize.width, WebCompatReporterUX.Checkbox.size)
        XCTAssertEqual(subject.intrinsicContentSize.height, WebCompatReporterUX.Checkbox.size)
    }

    func testCornerRadius_isHalfTheSizeSoTheCircleStaysRound() {
        let subject = WebCompatCheckboxView()

        XCTAssertEqual(subject.layer.cornerRadius, WebCompatReporterUX.Checkbox.size / 2)
    }
}
