// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatDetailsCellTests: XCTestCase {
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
}
