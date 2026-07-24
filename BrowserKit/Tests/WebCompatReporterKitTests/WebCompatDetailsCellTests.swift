// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatDetailsCellTests: XCTestCase {
    func testConfigure_carriesLabelAndIdentifierOntoTextViewAndSetsText() throws {
        let subject = createSubject()

        subject.configure(
            text: "The images never load",
            placeholder: "Describe the issue",
            accessibilityLabel: "Additional details",
            a11yIdentifier: "WebCompatReporter.AdditionalDetails",
            onEditingEnded: { _ in }
        )

        let textView = try XCTUnwrap(firstSubview(ofType: UITextView.self, in: subject.contentView))
        XCTAssertEqual(textView.text, "The images never load")
        XCTAssertEqual(textView.accessibilityLabel, "Additional details")
        XCTAssertEqual(textView.accessibilityIdentifier, "WebCompatReporter.AdditionalDetails")
    }

    func testScaledMinimumHeight_growsAtAccessibilityContentSize() {
        let subject = createSubject()

        let standard = subject.scaledMinimumHeight(
            compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)
        )
        let accessibility = subject.scaledMinimumHeight(
            compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        )

        XCTAssertGreaterThan(accessibility, standard)
    }

    // MARK: - Helpers

    private func createSubject() -> WebCompatDetailsCell {
        return WebCompatDetailsCell(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
    }

    private func firstSubview<T: UIView>(ofType type: T.Type, in view: UIView?) -> T? {
        guard let view else { return nil }
        for subview in view.subviews {
            if let match = subview as? T { return match }
            if let match = firstSubview(ofType: type, in: subview) { return match }
        }
        return nil
    }
}
