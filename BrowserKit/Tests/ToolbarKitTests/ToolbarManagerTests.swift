// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit

final class ToolbarManagerTests: XCTestCase {
    // Address toolbar border
    func testAddressToolbarBorderPositionWhenTopPlacementAndScrolledThenShouldDisplayBottomBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.bottom, subject.getAddressBorderPosition(
            for: .top,
            isPrivate: false,
            isScrolled: true,
            isMicrosurveyShown: false))
    }

    func testAddressToolbarBorderPositionWhenTopPlacementAndNotScrolledThenShouldDisplayNoBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.none, subject.getAddressBorderPosition(
            for: .top,
            isPrivate: false,
            isScrolled: false,
            isMicrosurveyShown: false))
    }

    func testAddressToolbarBorderPositionWhenBottomPlacementAndScrolledThenShouldDisplayTopBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.top, subject.getAddressBorderPosition(
            for: .bottom,
            isPrivate: false,
            isScrolled: true,
            isMicrosurveyShown: false))
    }

    func testAddressToolbarBorderPositionWhenBottomPlacementAndNotScrolledThenShouldDisplayTopBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.top, subject.getAddressBorderPosition(
            for: .bottom,
            isPrivate: false,
            isScrolled: false,
            isMicrosurveyShown: false))
    }

    func testAddressToolbarBorderPositionWhenTopPlacementAndPrivateAndScrolledThenShouldDisplayBottomBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.bottom, subject.getAddressBorderPosition(
            for: .top,
            isPrivate: true,
            isScrolled: true,
            isMicrosurveyShown: false))
    }

    func testAddressToolbarBorderPositionWhenTopPlacementAndPrivateAndNotScrolledThenShouldDisplayBottomBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.bottom, subject.getAddressBorderPosition(
            for: .top,
            isPrivate: true,
            isScrolled: false,
            isMicrosurveyShown: false))
    }

    func testAddressToolbarBorderPositionWhenBottomPlacementAndPrivateAndNotScrolledThenShouldDisplayTopBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.top, subject.getAddressBorderPosition(
            for: .bottom,
            isPrivate: true,
            isScrolled: false,
            isMicrosurveyShown: false))
    }

    func testAddressToolbarBorderPositionWhenBottomPlacementAndPrivateAndScrolledThenShouldDisplayTopBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.top, subject.getAddressBorderPosition(
            for: .bottom,
            isPrivate: true,
            isScrolled: true,
            isMicrosurveyShown: false))
    }

    // Address toolbar border with a microsurvey
    func testAddressToolbarBorderPositionWhenBottomPlacementAndMicrosurveyShownThenShouldDisplayNoBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.none, subject.getAddressBorderPosition(
            for: .bottom,
            isPrivate: false,
            isScrolled: false,
            isMicrosurveyShown: true))
    }

    func testAddressToolbarBorderPositionWhenBottomPlacementAndMicrosurveyShownAndScrolledThenShouldDisplayNoBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.none, subject.getAddressBorderPosition(
            for: .bottom,
            isPrivate: true,
            isScrolled: true,
            isMicrosurveyShown: true))
    }

    func testAddressToolbarBorderPositionWhenTopPlacementAndMicrosurveyShownAndScrolledThenShouldDisplayBottomBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.bottom, subject.getAddressBorderPosition(
            for: .top,
            isPrivate: false,
            isScrolled: true,
            isMicrosurveyShown: true))
    }

    func testAddressToolbarBorderPositionWhenTopPlacementAndMicrosurveyShownAndNotScrolledThenShouldDisplayNoBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.none, subject.getAddressBorderPosition(
            for: .top,
            isPrivate: false,
            isScrolled: false,
            isMicrosurveyShown: true))
    }

    func testAddressToolbarBorderPositionWhenTopPlacementAndMicrosurveyShownAndPrivateThenShouldDisplayBottomBorder() {
        let subject = createSubject()
        XCTAssertEqual(AddressToolbarBorderPosition.bottom, subject.getAddressBorderPosition(
            for: .top,
            isPrivate: true,
            isScrolled: false,
            isMicrosurveyShown: true))
    }

    // Navigation toolbar border
    func testDisplayNavigationToolbarBorderWhenTopPlacementThenShouldDisplay() {
        let subject = createSubject()
        XCTAssertTrue(subject.shouldDisplayNavigationBorder(toolbarPosition: .top, isMicrosurveyShown: false))
    }

    func testDisplayNavigationToolbarBorderWhenBottomPlacementThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayNavigationBorder(toolbarPosition: .bottom, isMicrosurveyShown: false))
    }

    func testDisplayNavigationToolbarBorderWhenTopPlacementAndMicrosurveyShownThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayNavigationBorder(toolbarPosition: .top, isMicrosurveyShown: true))
    }

    func testDisplayNavigationToolbarBorderWhenBottomPlacementAndMicrosurveyShownThenShouldNotDisplay() {
        let subject = createSubject()
        XCTAssertFalse(subject.shouldDisplayNavigationBorder(toolbarPosition: .bottom, isMicrosurveyShown: true))
    }

    // MARK: - Helpers
    func createSubject() -> ToolbarManager {
        return DefaultToolbarManager()
    }
}
