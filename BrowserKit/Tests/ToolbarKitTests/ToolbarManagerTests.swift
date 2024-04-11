// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit
import Common

final class ToolbarManagerTests: XCTestCase {
    func testDisplayToolbarWhenScrolledThenShouldDisplay() {
        let subject = createSubject()
        XCTAssertTrue(subject.shouldDisplayBorder(hasTopPlacement: true,
                                                  isPrivate: false,
                                                  scrollY: 10))
    }

    func testDisplayToolbarWhenBottomPlacementThenShouldDisplay() {
        let subject = createSubject()
        XCTAssertTrue(subject.shouldDisplayBorder(hasTopPlacement: false,
                                                  isPrivate: false,
                                                  scrollY: 0))
    }

    func testDisplayToolbarWhenPrivateModeThenShouldDisplay() {
        let subject = createSubject()
        XCTAssertTrue(subject.shouldDisplayBorder(hasTopPlacement: false,
                                                  isPrivate: true,
                                                  scrollY: 0))
    }

    func testDisplayToolbarWhenNotScrolledNonPrivateModeWithTopPlacementThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayBorder(hasTopPlacement: true,
                                                  isPrivate: false,
                                                   scrollY: 0))
    }

    // MARK: - Helpers
    func createSubject() -> ToolbarManager {
        return DefaultToolbarManager()
    }
}
