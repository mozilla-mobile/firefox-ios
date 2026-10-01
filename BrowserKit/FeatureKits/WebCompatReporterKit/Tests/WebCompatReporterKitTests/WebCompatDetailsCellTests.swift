// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatDetailsCellTests: XCTestCase {
    private let placeholder = "Describe the issue in detail (optional)"

    func testConfigure_whileEditing_keepsInProgressTextAndPlaceholderHidden() throws {
        let subject = createSubject()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.addSubview(subject)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        configure(subject, text: "")

        let textView = try XCTUnwrap(firstSubview(ofType: UITextView.self, in: subject.contentView))
        XCTAssertTrue(textView.becomeFirstResponder())
        textView.text = "The recipe images never load"
        subject.textViewDidChange(textView)

        // The value only round-trips to Redux on editing-end, so any state change in the
        // meantime reconfigures this row with a stale empty value.
        configure(subject, text: "")

        XCTAssertEqual(textView.text, "The recipe images never load")
        XCTAssertTrue(try placeholderLabel(in: subject).isHidden)
    }

    func testConfigure_derivesPlaceholderVisibilityAndAccessibilityValueFromText() throws {
        let subject = createSubject()

        configure(subject, text: "")
        var textView = try XCTUnwrap(firstSubview(ofType: UITextView.self, in: subject.contentView))
        XCTAssertFalse(try placeholderLabel(in: subject).isHidden)
        XCTAssertNil(textView.accessibilityValue)

        configure(subject, text: "Buttons do nothing")
        textView = try XCTUnwrap(firstSubview(ofType: UITextView.self, in: subject.contentView))
        XCTAssertTrue(try placeholderLabel(in: subject).isHidden)
        XCTAssertEqual(textView.accessibilityValue, "Buttons do nothing")
    }

    // MARK: - Helpers

    private func createSubject() -> WebCompatDetailsCell {
        return WebCompatDetailsCell(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
    }

    private func configure(_ subject: WebCompatDetailsCell, text: String) {
        subject.configure(
            text: text,
            placeholder: placeholder,
            accessibilityLabel: "Describe the issue in detail",
            a11yIdentifier: "WebCompatReporter.AdditionalDetails",
            onEditingEnded: { _ in }
        )
    }

    /// Matched on text because the cell also holds a hidden label used only to carry the body line height.
    private func placeholderLabel(in subject: WebCompatDetailsCell) throws -> UILabel {
        let labels = subject.contentView.subviews.compactMap { $0 as? UILabel }
        return try XCTUnwrap(labels.first { $0.text == placeholder })
    }
}
