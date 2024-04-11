// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit
import Common

final class ToolbarManagerTests: XCTestCase {
    func testDisplayToolbarTopBorderWhenScrolledThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayBorder(borderPosition: .top,
                                                   toolbarPosition: .top,
                                                   isPrivate: false,
                                                   scrollY: 10))
    }

    func testDisplayToolbarTopBorderWhenBottomPlacementThenShouldDisplay() {
        let subject = createSubject()
        XCTAssertTrue(subject.shouldDisplayBorder(borderPosition: .top,
                                                  toolbarPosition: .bottom,
                                                  isPrivate: false,
                                                  scrollY: 0))
    }

    func testDisplayToolbarTopBorderWhenPrivateModeThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayBorder(borderPosition: .top,
                                                   toolbarPosition: .top,
                                                   isPrivate: true,
                                                   scrollY: 0))
    }

    func testDisplayToolbarTopBorderWhenNotScrolledNonPrivateModeWithTopPlacementThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayBorder(borderPosition: .top,
                                                   toolbarPosition: .top,
                                                   isPrivate: false,
                                                   scrollY: 0))
    }

    func testDisplayToolbarBottomBorderWhenBottomPlacementThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayBorder(borderPosition: .bottom,
                                                   toolbarPosition: .bottom,
                                                   isPrivate: false,
                                                   scrollY: 0))
    }

    func testDisplayToolbarBottomBorderWhenPrivateModeThenShouldDisplay() {
        let subject = createSubject()
        XCTAssertTrue(subject.shouldDisplayBorder(borderPosition: .bottom,
                                                  toolbarPosition: .bottom,
                                                  isPrivate: true,
                                                  scrollY: 0))
    }

    func testDisplayToolbarBottomBorderWhenNotScrolledNonPrivateModeWithTopPlacementThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayBorder(borderPosition: .bottom,
                                                   toolbarPosition: .top,
                                                   isPrivate: false,
                                                   scrollY: 0))
    }

    // MARK: - Helpers
    func createSubject() -> ToolbarManager {
        return DefaultToolbarManager()
    }
}
