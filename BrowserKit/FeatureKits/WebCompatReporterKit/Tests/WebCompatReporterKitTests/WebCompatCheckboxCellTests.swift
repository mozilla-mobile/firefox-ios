// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatCheckboxCellTests: XCTestCase {
    // The row is the accessibility element, so the checked state has to ride on it.
    func testConfigure_carriesTheLabelIdentifierAndSelectedTraitForBothStates() {
        let subject = createSubject()

        subject.configure(title: "Send blocked list", isChecked: true, a11yIdentifier: "blocklist")

        XCTAssertTrue(subject.isAccessibilityElement)
        XCTAssertEqual(subject.accessibilityLabel, "Send blocked list")
        XCTAssertEqual(subject.accessibilityIdentifier, "blocklist")
        XCTAssertTrue(subject.accessibilityTraits.contains(.selected))
        if #available(iOS 17.0, *) {
            XCTAssertTrue(subject.accessibilityTraits.contains(.toggleButton))
        } else {
            XCTAssertTrue(subject.accessibilityTraits.contains(.button))
        }

        // Reconfiguring in place must drop .selected, not leave it stuck on.
        subject.configure(title: "Send blocked list", isChecked: false, a11yIdentifier: "blocklist")

        XCTAssertFalse(subject.accessibilityTraits.contains(.selected))
    }

    // A reconfigure that rebuilt the accessory would animate as remove+insert and flicker.
    func testReconfigure_keepsExactlyOneCheckboxAccessory() {
        let subject = createSubject()
        subject.configure(title: "Send blocked list", isChecked: false, a11yIdentifier: "blocklist")
        subject.applyTheme(theme: LightTheme())

        subject.configure(title: "Send blocked list", isChecked: true, a11yIdentifier: "blocklist")
        subject.applyTheme(theme: LightTheme())

        XCTAssertEqual(subject.accessories.count, 1)
    }

    // MARK: - Helpers

    private func createSubject() -> WebCompatCheckboxCell {
        return WebCompatCheckboxCell(frame: CGRect(x: 0, y: 0, width: 320, height: 60))
    }
}
