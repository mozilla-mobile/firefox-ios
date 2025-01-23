// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit
import Common

final class ToolbarManagerTests: XCTestCase {
    // Address toolbar border
    func testAddressToolbarBorderPositionWhenTopPlacementAndScrolledThenShouldDisplayBottomBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.bottom, subject.getAddressBorderPosition(
            for: .top,
            isPrivate: false,
            scrollY: 10))
    }

    func testAddressToolbarBorderPositionWhenTopPlacementAndNotScrolledThenShouldDisplayNoBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.none, subject.getAddressBorderPosition(
            for: .top,
            isPrivate: false,
            scrollY: 0))
    }

    func testAddressToolbarBorderPositionWhenBottomPlacementAndScrolledThenShouldDisplayTopBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.top, subject.getAddressBorderPosition(
            for: .bottom,
            isPrivate: false,
            scrollY: 10))
    }

    func testAddressToolbarBorderPositionWhenBottomPlacementAndNotScrolledThenShouldDisplayTopBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.top, subject.getAddressBorderPosition(
            for: .bottom,
            isPrivate: false,
            scrollY: 0))
    }

    func testAddressToolbarBorderPositionWhenTopPlacementAndPrivateAndScrolledThenShouldDisplayBottomBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.bottom, subject.getAddressBorderPosition(
            for: .top,
            isPrivate: true,
            scrollY: 10))
    }

    func testAddressToolbarBorderPositionWhenTopPlacementAndPrivateAndNotScrolledThenShouldDisplayBottomBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.bottom, subject.getAddressBorderPosition(
            for: .top,
            isPrivate: true,
            scrollY: 0))
    }

    func testAddressToolbarBorderPositionWhenBottomPlacementAndPrivateAndNotScrolledThenShouldDisplayTopBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.top, subject.getAddressBorderPosition(
            for: .bottom,
            isPrivate: true,
            scrollY: 0))
    }

    func testAddressToolbarBorderPositionWhenBottomPlacementAndPrivateAndScrolledThenShouldDisplayTopBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.top, subject.getAddressBorderPosition(
            for: .bottom,
            isPrivate: true,
            scrollY: 10))
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
