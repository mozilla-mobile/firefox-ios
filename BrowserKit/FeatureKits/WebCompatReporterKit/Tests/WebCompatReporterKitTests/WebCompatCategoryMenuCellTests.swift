// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import TestKit
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatCategoryMenuCellTests: XCTestCase {
    /// A title on the button would animate away as the menu opens, and a title-less button has no
    /// accessibility label of its own.
    func testConfigure_keepsTheTitleOffTheButtonAndCarriesItForVoiceOver() throws {
        let subject = WebCompatCategoryMenuCell(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        trackForMemoryLeaks(subject)

        subject.configure(
            title: "Site is not usable",
            isPlaceholder: false,
            options: [],
            theme: LightTheme(),
            a11yIdentifier: "WebCompatReporter.CategoryMenu",
            onSelect: { _ in }
        )

        let button = try XCTUnwrap(
            subject.contentView.subviews.compactMap { $0 as? WebCompatTrailingMenuButton }.first
        )
        XCTAssertNil(button.currentTitle)
        XCTAssertEqual(button.accessibilityLabel, "Site is not usable")

        let label = try XCTUnwrap(subject.contentView.subviews.compactMap { $0 as? UILabel }.first)
        XCTAssertEqual(label.text, "Site is not usable")
        XCTAssertFalse(label.isAccessibilityElement)
    }
}
