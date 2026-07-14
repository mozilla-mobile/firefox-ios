// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class FolderSectionHeaderViewTests: XCTestCase {
    private var subject: FolderSectionHeaderView!

    override func setUp() async throws {
        try await super.setUp()
        subject = FolderSectionHeaderView(reuseIdentifier: nil)
    }

    override func tearDown() async throws {
        subject = nil
        try await super.tearDown()
    }

    func testConfigure_captionOnly_showsCaptionAndHidesTitle() {
        subject.configure(title: nil, caption: "Location", showsChevron: false, titleColor: .black)

        XCTAssertEqual(subject.captionLabel.text, "Location")
        XCTAssertNil(subject.titleLabel.text)
        XCTAssertTrue(subject.chevronImageView.isHidden)
    }

    func testConfigure_captionOnly_disablesInteractionAndExpandAccessibility() {
        subject.configure(title: nil, caption: "Location", showsChevron: false, titleColor: .black)

        XCTAssertFalse(subject.isUserInteractionEnabled)
        XCTAssertFalse(subject.accessibilityTraits.contains(.button))
        XCTAssertNil(subject.accessibilityValue)
        XCTAssertEqual(subject.accessibilityLabel, "Location")
    }

    func testConfigure_captionAndTitleWithChevron_showsBoth() {
        subject.configure(title: "Mobile", caption: "All Folders", showsChevron: true, isExpanded: true, titleColor: .black)

        XCTAssertEqual(subject.captionLabel.text, "All Folders")
        XCTAssertEqual(subject.titleLabel.text, "Mobile")
        XCTAssertFalse(subject.chevronImageView.isHidden)
        XCTAssertEqual(subject.accessibilityLabel, "Mobile")
    }

    func testConfigure_withChevron_enablesInteractionAndButtonTrait() {
        subject.configure(title: "Mobile", showsChevron: true, isExpanded: true, titleColor: .black)

        XCTAssertTrue(subject.isUserInteractionEnabled)
        XCTAssertTrue(subject.accessibilityTraits.contains(.button))
    }

    func testConfigure_whenExpanded_setsExpandedAccessibilityValue() {
        subject.configure(title: "Mobile", showsChevron: true, isExpanded: true, titleColor: .black)
        XCTAssertEqual(subject.accessibilityValue, .Bookmarks.Menu.EditBookmarkGroupExpandedValue)
    }

    func testConfigure_whenCollapsed_setsCollapsedAccessibilityValue() {
        subject.configure(title: "Mobile", showsChevron: true, isExpanded: false, titleColor: .black)
        XCTAssertEqual(subject.accessibilityValue, .Bookmarks.Menu.EditBookmarkGroupCollapsedValue)
    }

    func testConfigure_titleWithChevronNoCaption_hidesCaption() {
        subject.configure(title: "Desktop", showsChevron: true, isExpanded: false, titleColor: .black)

        XCTAssertNil(subject.captionLabel.text)
        XCTAssertEqual(subject.titleLabel.text, "Desktop")
        XCTAssertFalse(subject.chevronImageView.isHidden)
    }

    func testConfigure_withEmptyCaption_treatedAsNoCaption() {
        subject.configure(title: "Desktop", caption: "", showsChevron: true, titleColor: .black)
        XCTAssertNil(subject.captionLabel.text)
    }

    func testConfigure_withEmptyTitle_treatedAsNoTitle() {
        subject.configure(title: "", caption: "Location", showsChevron: false, titleColor: .black)
        XCTAssertNil(subject.titleLabel.text)
    }

    func testSetExpanded_animatedAndNonAnimated_doesNotCrash() {
        subject.setExpanded(true, animated: false)
        subject.setExpanded(false, animated: false)
        subject.setExpanded(true, animated: true)
    }

    func testOnTap_firesWhenHandleTapIsInvoked() {
        let expectation = expectation(description: "onTap should be called")
        subject.onTap = {
            expectation.fulfill()
        }

        subject.handleTap()

        waitForExpectations(timeout: 0.1)
    }

    func testPrepareForReuse_resetsAllState() {
        subject.configure(title: "Mobile", caption: "All Folders", showsChevron: true, isExpanded: true, titleColor: .black)
        subject.onTap = {}

        subject.prepareForReuse()

        XCTAssertNil(subject.captionLabel.text)
        XCTAssertNil(subject.titleLabel.text)
        XCTAssertTrue(subject.chevronImageView.isHidden)
        XCTAssertFalse(subject.isUserInteractionEnabled)
        XCTAssertTrue(subject.accessibilityTraits.isEmpty)
        XCTAssertNil(subject.accessibilityValue)
        XCTAssertNil(subject.onTap)
    }
}
