// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

@MainActor
final class LinkActionCellTests: XCTestCase {
    func testConfigure_setsTitle() {
        let subject = createSubject()
        subject.configure(title: "Change Location...")
        XCTAssertEqual(subject.titleLabel.text, "Change Location...")
    }

    func testInit_setsButtonAccessibilityTrait() {
        let subject = createSubject()
        XCTAssertTrue(subject.accessibilityTraits.contains(.button))
    }

    func testInit_setsDefaultSelectionStyle() {
        let subject = createSubject()
        XCTAssertEqual(subject.selectionStyle, .default)
    }

    func testApplyTheme_setsTitleColorAndBackground() {
        let subject = createSubject()
        let theme = LightTheme()
        subject.applyTheme(theme: theme)

        XCTAssertEqual(subject.backgroundColor, theme.colors.layer5)
        XCTAssertEqual(subject.titleLabel.textColor, theme.colors.actionPrimary)
    }

    func testPrepareForReuse_clearsTitle() {
        let subject = createSubject()
        subject.configure(title: "Change Location...")
        subject.prepareForReuse()
        XCTAssertNil(subject.titleLabel.text)
    }

    private func createSubject() -> LinkActionCell {
        let cell = LinkActionCell(style: .default, reuseIdentifier: nil)
        trackForMemoryLeaks(cell)
        return cell
    }
}
