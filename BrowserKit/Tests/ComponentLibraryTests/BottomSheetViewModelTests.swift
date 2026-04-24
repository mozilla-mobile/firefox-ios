// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ComponentLibrary

final class BottomSheetViewModelTests: XCTestCase {
    func testInit_withDefaultValues_animatesPresentation() {
        let subject = BottomSheetViewModel(
            closeButtonA11yLabel: "Close",
            closeButtonA11yIdentifier: "closeButton"
        )

        XCTAssertTrue(subject.animatesPresentation)
    }

    func testInit_withAnimatesPresentationFalse_disablesPresentationAnimation() {
        let subject = BottomSheetViewModel(
            animatesPresentation: false,
            closeButtonA11yLabel: "Close",
            closeButtonA11yIdentifier: "closeButton"
        )

        XCTAssertFalse(subject.animatesPresentation)
    }
}
