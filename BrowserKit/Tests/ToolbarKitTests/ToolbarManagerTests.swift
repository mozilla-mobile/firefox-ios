// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit
import Common

final class ToolbarManagerTests: XCTestCase {
    // Address toolbar border
    func testDisplayAddressToolbarTopBorderWhenScrolledThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayAddressBorder(borderPosition: .top,
                                                          toolbarPosition: .top,
                                                          isPrivate: false,
                                                          scrollY: 10))
    }

    func testDisplayAddressToolbarTopBorderWhenBottomPlacementThenShouldDisplay() {
        let subject = createSubject()
        XCTAssertTrue(subject.shouldDisplayAddressBorder(borderPosition: .top,
                                                         toolbarPosition: .bottom,
                                                         isPrivate: false,
                                                         scrollY: 0))
    }

    func testDisplayAddressToolbarTopBorderWhenPrivateModeThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayAddressBorder(borderPosition: .top,
                                                          toolbarPosition: .top,
                                                          isPrivate: true,
                                                          scrollY: 0))
    }

    func testDisplayAddressToolbarTopBorderWhenNotScrolledNonPrivateModeWithTopPlacementThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayAddressBorder(borderPosition: .top,
                                                          toolbarPosition: .top,
                                                          isPrivate: false,
                                                          scrollY: 0))
    }

    func testDisplayAddressToolbarBottomBorderWhenBottomPlacementThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayAddressBorder(borderPosition: .bottom,
                                                          toolbarPosition: .bottom,
                                                          isPrivate: false,
                                                          scrollY: 0))
    }

    func testDisplayAddressToolbarBottomBorderWhenPrivateModeThenShouldDisplay() {
        let subject = createSubject()
        XCTAssertTrue(subject.shouldDisplayAddressBorder(borderPosition: .bottom,
                                                         toolbarPosition: .bottom,
                                                         isPrivate: true,
                                                         scrollY: 0))
    }

    func testDisplayAddressToolbarBottomBorderWhenNotScrolledNonPrivateModeWithTopPlacementThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayAddressBorder(borderPosition: .bottom,
                                                          toolbarPosition: .top,
                                                          isPrivate: false,
                                                          scrollY: 0))
    }

    // Navigation toolbar border
    func testDisplayNavigationToolbarBorderWhenTopPlacementThenShouldDisplay() {
        let subject = createSubject()
        XCTAssertTrue(subject.shouldDisplayNavigationBorder(toolbarPosition: .top))
    }
    func testDisplayNavigationToolbarBorderWhenBottomPlacementThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayNavigationBorder(toolbarPosition: .bottom))
    }

    // MARK: - Helpers
    func createSubject() -> ToolbarManager {
        return DefaultToolbarManager()
    }
}
