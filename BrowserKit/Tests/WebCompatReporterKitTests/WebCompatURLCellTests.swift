// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatURLCellTests: XCTestCase {
    func testConfigure_carriesTitleAndIdentifierOntoFieldAndSetsText() throws {
        let subject = createSubject()

        subject.configure(
            title: "URL",
            text: "https://example.com",
            placeholder: "Website address",
            a11yIdentifier: "WebCompatReporter.URLField",
            onEditingEnded: { _ in }
        )

        let field = try XCTUnwrap(firstSubview(ofType: UITextField.self, in: subject.contentView))
        XCTAssertEqual(field.accessibilityLabel, "URL")
        XCTAssertEqual(field.accessibilityIdentifier, "WebCompatReporter.URLField")
        XCTAssertEqual(field.text, "https://example.com")
    }

    func testApplyStackLayout_switchesAxisAndAlignmentBetweenStandardAndAccessibilitySizes() throws {
        let subject = createSubject()
        subject.configure(title: "URL", text: "", placeholder: "", a11yIdentifier: "url", onEditingEnded: { _ in })
        let stack = try XCTUnwrap(firstSubview(ofType: UIStackView.self, in: subject.contentView))
        let field = try XCTUnwrap(firstSubview(ofType: UITextField.self, in: subject.contentView))

        subject.applyStackLayout(isAccessibilityCategory: false)
        XCTAssertEqual(stack.axis, .horizontal)
        XCTAssertEqual(stack.alignment, .center)
        XCTAssertEqual(field.textAlignment, .right)

        subject.applyStackLayout(isAccessibilityCategory: true)
        XCTAssertEqual(stack.axis, .vertical)
        XCTAssertEqual(stack.alignment, .fill)
        XCTAssertEqual(field.textAlignment, .natural)
    }

    // MARK: - Helpers

    private func createSubject() -> WebCompatURLCell {
        return WebCompatURLCell(frame: CGRect(x: 0, y: 0, width: 320, height: 60))
    }
}
