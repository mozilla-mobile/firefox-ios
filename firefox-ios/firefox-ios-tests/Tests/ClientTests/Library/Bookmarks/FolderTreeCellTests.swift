// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class FolderTreeCellTests: XCTestCase {
    private var subject: FolderTreeCell!

    override func setUp() async throws {
        try await super.setUp()
        subject = FolderTreeCell(style: .default, reuseIdentifier: nil)
    }

    override func tearDown() async throws {
        subject = nil
        try await super.tearDown()
    }

    func testConfigure_setsTitle() {
        subject.configure(title: "Bookmarks", breadcrumb: nil, image: nil, isSelected: false)
        XCTAssertEqual(subject.titleLabel.text, "Bookmarks")
    }

    func testConfigure_withBreadcrumb_showsBreadcrumbLabel() {
        subject.configure(title: "Level 1", breadcrumb: "↳ Root Folder", image: nil, isSelected: false)

        XCTAssertFalse(subject.breadcrumbLabel.isHidden)
        XCTAssertEqual(subject.breadcrumbLabel.text, "↳ Root Folder")
    }

    func testConfigure_withoutBreadcrumb_hidesBreadcrumbLabel() {
        subject.configure(title: "Bookmarks", breadcrumb: nil, image: nil, isSelected: false)
        XCTAssertTrue(subject.breadcrumbLabel.isHidden)
    }

    func testConfigure_withEmptyBreadcrumb_hidesBreadcrumbLabel() {
        subject.configure(title: "Bookmarks", breadcrumb: "", image: nil, isSelected: false)
        XCTAssertTrue(subject.breadcrumbLabel.isHidden)
    }

    func testConfigure_whenSelected_setsCheckmarkAccessory() {
        subject.configure(title: "Bookmarks", breadcrumb: nil, image: nil, isSelected: true)
        XCTAssertEqual(subject.accessoryType, .checkmark)
    }

    func testConfigure_whenNotSelected_setsNoneAccessory() {
        subject.configure(title: "Bookmarks", breadcrumb: nil, image: nil, isSelected: false)
        XCTAssertEqual(subject.accessoryType, .none)
    }

    func testConfigure_setsLeftImageView() {
        let image = UIImage()
        subject.configure(title: "Bookmarks", breadcrumb: nil, image: image, isSelected: false)
        XCTAssertNotNil(subject.leftImageView.image)
    }

    func testConfigure_withNilImage_clearsLeftImageView() {
        subject.configure(title: "Bookmarks", breadcrumb: nil, image: UIImage(), isSelected: false)
        subject.configure(title: "Bookmarks", breadcrumb: nil, image: nil, isSelected: false)
        XCTAssertNil(subject.leftImageView.image)
    }

    func testConfigure_setsAccessibilityButtonTrait() {
        subject.configure(title: "Bookmarks", breadcrumb: nil, image: nil, isSelected: false)
        XCTAssertTrue(subject.accessibilityTraits.contains(.button))
    }

    func testIndentationLevel_zeroAndNonZero_doesNotCrash() {
        subject.indentationLevel = 0
        subject.indentationLevel = 1
        subject.indentationLevel = 3
    }

    func testPrepareForReuse_resetsAllState() {
        subject.configure(title: "Bookmarks", breadcrumb: "↳ Root Folder", image: UIImage(), isSelected: true)
        subject.indentationLevel = 2

        subject.prepareForReuse()

        XCTAssertNil(subject.titleLabel.text)
        XCTAssertNil(subject.breadcrumbLabel.text)
        XCTAssertNil(subject.leftImageView.image)
        XCTAssertEqual(subject.accessoryType, .none)
        XCTAssertEqual(subject.selectionStyle, .default)
        XCTAssertEqual(subject.indentationLevel, 0)
    }
}
