// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

@MainActor
final class LinkActionCellTests: XCTestCase {
    private var subject: LinkActionCell!

    override func setUp() async throws {
        try await super.setUp()
        subject = LinkActionCell(style: .default, reuseIdentifier: nil)
    }

    override func tearDown() async throws {
        subject = nil
        try await super.tearDown()
    }

    func testConfigure_setsTitle() {
        subject.configure(title: "Change Location...")
        XCTAssertEqual(subject.titleLabel.text, "Change Location...")
    }

    func testInit_setsButtonAccessibilityTrait() {
        XCTAssertTrue(subject.accessibilityTraits.contains(.button))
    }

    func testInit_setsDefaultSelectionStyle() {
        XCTAssertEqual(subject.selectionStyle, .default)
    }

    func testApplyTheme_setsTitleColorAndBackground() {
        let theme = LightTheme()
        subject.applyTheme(theme: theme)

        XCTAssertEqual(subject.backgroundColor, theme.colors.layer5)
        XCTAssertEqual(subject.titleLabel.textColor, theme.colors.actionPrimary)
    }

    func testPrepareForReuse_clearsTitle() {
        subject.configure(title: "Change Location...")
        subject.prepareForReuse()
        XCTAssertNil(subject.titleLabel.text)
    }
}
