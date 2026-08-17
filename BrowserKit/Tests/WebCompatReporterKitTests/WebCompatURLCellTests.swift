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
            errorMessage: nil,
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
        subject.configure(title: "URL", text: "", errorMessage: nil, a11yIdentifier: "url", onEditingEnded: { _ in })
        let stack = try fieldStackView(in: subject)

        subject.applyStackLayout(isAccessibilityCategory: false)
        XCTAssertEqual(stack.axis, .horizontal)
        XCTAssertEqual(stack.alignment, .center)

        subject.applyStackLayout(isAccessibilityCategory: true)
        XCTAssertEqual(stack.axis, .vertical)
        XCTAssertEqual(stack.alignment, .fill)
    }

    func testConfigure_clearedFieldShowsNoPlaceholderAndReadsFromTheLeadingEdge() throws {
        let subject = createSubject()

        subject.configure(title: "URL", text: "ebay.com", errorMessage: nil, a11yIdentifier: "url", onEditingEnded: { _ in })
        subject.applyTheme(theme: LightTheme())

        let field = try XCTUnwrap(firstSubview(ofType: UITextField.self, in: subject.contentView))
        XCTAssertNil(field.placeholder)
        XCTAssertNil(field.attributedPlaceholder)
        XCTAssertEqual(field.textAlignment, .natural)
    }

    func testConfigure_showsTheErrorWithTheTypedTextThenHidesItOnRecovery() throws {
        let subject = createSubject()

        subject.configure(
            title: "URL",
            text: " .com",
            errorMessage: "Enter a valid URL",
            a11yIdentifier: "url",
            onEditingEnded: { _ in }
        )

        let field = try XCTUnwrap(firstSubview(ofType: UITextField.self, in: subject.contentView))
        XCTAssertEqual(field.text, " .com")
        XCTAssertEqual(try errorLabel(in: subject).text, "Enter a valid URL")
        XCTAssertFalse(try errorStackView(in: subject).isHidden)

        subject.configure(
            title: "URL",
            text: "https://example.com",
            errorMessage: nil,
            a11yIdentifier: "url",
            onEditingEnded: { _ in }
        )

        XCTAssertTrue(try errorStackView(in: subject).isHidden)
    }

    // MARK: - Helpers

    private func fieldStackView(in subject: WebCompatURLCell) throws -> UIStackView {
        let container = try XCTUnwrap(firstSubview(ofType: UIStackView.self, in: subject.contentView))
        return try XCTUnwrap(container.arrangedSubviews.compactMap { $0 as? UIStackView }.first)
    }

    private func errorLabel(in subject: WebCompatURLCell) throws -> UILabel {
        return try XCTUnwrap(errorStackView(in: subject).arrangedSubviews.compactMap { $0 as? UILabel }.first)
    }

    private func errorStackView(in subject: WebCompatURLCell) throws -> UIStackView {
        let container = try XCTUnwrap(firstSubview(ofType: UIStackView.self, in: subject.contentView))
        return try XCTUnwrap(container.arrangedSubviews.compactMap { $0 as? UIStackView }.last)
    }

    private func createSubject() -> WebCompatURLCell {
        return WebCompatURLCell(frame: CGRect(x: 0, y: 0, width: 320, height: 60))
    }
}
