// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest

@testable import ComponentLibrary

@MainActor
final class GlassCloseButtonTests: XCTestCase {
    func test_init_scalesLargeContentImage() {
        let subject = GlassCloseButton()

        XCTAssertTrue(subject.scalesLargeContentImage)
        XCTAssertNotNil(subject.configuration)
    }

    func test_configure_setsAccessibilityLabelAndIdentifier() {
        let subject = GlassCloseButton()

        subject.configure(viewModel: CloseButtonViewModel(a11yLabel: "Close", a11yIdentifier: "close.identifier"))

        XCTAssertEqual(subject.accessibilityLabel, "Close")
        XCTAssertEqual(subject.accessibilityIdentifier, "close.identifier")
    }
}
