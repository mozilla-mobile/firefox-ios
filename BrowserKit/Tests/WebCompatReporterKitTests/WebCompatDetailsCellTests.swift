// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatDetailsCellTests: XCTestCase {
    func testTextViewHeight_matchesVisibleLineCount() throws {
        let subject = createSubject()
        subject.layoutIfNeeded()

        let textView = try XCTUnwrap(textView(in: subject))
        let lineHeight = try XCTUnwrap(textView.font).lineHeight
        let expected = lineHeight * WebCompatReporterUX.DetailsField.visibleLineCount

        XCTAssertEqual(textView.frame.height, expected, accuracy: 1)
    }

    func testTextViewHeight_growsAtAccessibilityContentSize() throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("Overriding the content size category on a view requires iOS 17")
        }
        let subject = createSubject()
        subject.layoutIfNeeded()
        let standardHeight = try XCTUnwrap(textView(in: subject)).frame.height

        subject.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        subject.layoutIfNeeded()

        let accessibilityHeight = try XCTUnwrap(textView(in: subject)).frame.height
        XCTAssertGreaterThan(accessibilityHeight, standardHeight)
    }

    // MARK: - Helpers

    private func createSubject() -> WebCompatDetailsCell {
        let cell = WebCompatDetailsCell(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
        cell.configure(
            text: "",
            placeholder: "Additional details",
            accessibilityLabel: "Additional details",
            a11yIdentifier: "details",
            onEditingEnded: { _ in }
        )
        return cell
    }

    private func textView(in cell: WebCompatDetailsCell) -> UITextView? {
        return cell.contentView.subviews.compactMap { $0 as? UITextView }.first
    }
}
