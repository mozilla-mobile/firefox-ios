// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class OneLineTableViewCellTests: XCTestCase {
    // MARK: - layoutSubviews

    func testLayoutSubviews_nonEditingMode_accessoryViewPositionedAtTrailingEdge() {
        let subject = createSubject()
        subject.frame = CGRect(x: 0, y: 0, width: 375, height: 44)
        subject.configure(viewModel: createViewModel(isAccessoryEnabled: true))

        subject.layoutSubviews()

        guard let accessoryView = subject.accessoryView else {
            XCTFail("Expected accessoryView to be set")
            return
        }
        let expectedX = subject.frame.width
            - accessoryView.frame.width
            - OneLineTableViewCell.UX.accessoryViewTrailingPadding
            - subject.safeAreaInsets.right
        XCTAssertEqual(
            accessoryView.frame.origin.x,
            expectedX,
            "In non-editing mode the accessory view should be positioned at the trailing edge"
        )
    }

    func testLayoutSubviews_editingMode_accessoryViewNotRepositioned() {
        let subject = createSubject()
        subject.frame = CGRect(x: 0, y: 0, width: 375, height: 44)
        subject.configure(viewModel: createViewModel(isAccessoryEnabled: true))

        let manualX = subject.frame.width
            - (subject.accessoryView?.frame.width ?? 0)
            - OneLineTableViewCell.UX.accessoryViewTrailingPadding
            - subject.safeAreaInsets.right

        subject.isEditing = true
        subject.layoutSubviews()

        guard let accessoryView = subject.accessoryView else {
            XCTFail("Expected accessoryView to be set")
            return
        }
        XCTAssertNotEqual(
            accessoryView.frame.origin.x,
            manualX,
            "In editing mode the accessory view should NOT be manually repositioned"
        )
    }

    func testLayoutSubviews_noAccessoryView_noOp() {
        let subject = createSubject()
        subject.frame = CGRect(x: 0, y: 0, width: 375, height: 44)
        subject.configure(viewModel: createViewModel(isAccessoryEnabled: false))

        subject.layoutSubviews()

        XCTAssertNil(subject.accessoryView)
    }

    // MARK: - configure

    func testConfigure_setsAccessoryAndEditingAccessory() {
        let subject = createSubject()
        subject.configure(viewModel: createViewModel(isAccessoryEnabled: true, isEditingAccessoryEnabled: true))

        XCTAssertNotNil(subject.accessoryView, "accessoryView should be set after configure")
        XCTAssertNotNil(subject.editingAccessoryView, "editingAccessoryView should be set after configure")
    }

    // MARK: - indentationLevel

    func testIndentationLevel_zero_usesBaseMargin() {
        let subject = createSubject()

        subject.indentationLevel = 0
        subject.layoutIfNeeded()

        XCTAssertEqual(subject.leftImageView.frame.origin.x, OneLineTableViewCell.UX.borderViewMargin)
    }

    func testIndentationLevel_withinCap_scalesLinearlyPerLevel() {
        let subject = createSubject()

        subject.indentationLevel = 2
        subject.layoutIfNeeded()

        XCTAssertEqual(subject.leftImageView.frame.origin.x, expectedLeadingMargin(forLevel: 2))
    }

    func testIndentationLevel_atCap_matchesCappedMargin() {
        let subject = createSubject()

        subject.indentationLevel = OneLineTableViewCell.UX.maxIndentationLevel
        subject.layoutIfNeeded()

        XCTAssertEqual(
            subject.leftImageView.frame.origin.x,
            expectedLeadingMargin(forLevel: OneLineTableViewCell.UX.maxIndentationLevel)
        )
    }

    func testIndentationLevel_beyondCap_doesNotExceedCappedMargin() {
        let subject = createSubject()
        let cappedMargin = expectedLeadingMargin(forLevel: OneLineTableViewCell.UX.maxIndentationLevel)

        subject.indentationLevel = 20
        subject.layoutIfNeeded()

        XCTAssertEqual(
            subject.leftImageView.frame.origin.x,
            cappedMargin,
            "Deeply nested rows (e.g. bookmark folders 9+ levels deep) must stay within the capped margin"
        )
    }

    // MARK: - Helpers

    private func createSubject() -> OneLineTableViewCell {
        let subject = OneLineTableViewCell(style: .default, reuseIdentifier: OneLineTableViewCell.cellIdentifier)
        subject.frame = CGRect(x: 0, y: 0, width: 375, height: 44)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func expectedLeadingMargin(forLevel level: Int) -> CGFloat {
        let base = OneLineTableViewCell.UX.borderViewMargin
            + OneLineTableViewCell.UX.imageSize
            + OneLineTableViewCell.UX.longLeadingMargin
        let perLevel = OneLineTableViewCell.UX.imageSize + OneLineTableViewCell.UX.longLeadingMargin
        return base + perLevel * CGFloat(level - 1)
    }

    private func createViewModel(
        isAccessoryEnabled: Bool,
        isEditingAccessoryEnabled: Bool = false
    ) -> OneLineTableViewCellViewModel {
        let accessoryView: UIView? = isAccessoryEnabled
            ? UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            : nil
        let editingAccessoryView: UIImageView? = isEditingAccessoryEnabled
            ? UIImageView(image: UIImage(systemName: "chevron.right"))
            : nil

        return OneLineTableViewCellViewModel(
            title: "Test Bookmark",
            leftImageView: nil,
            accessoryView: accessoryView,
            accessoryType: .none,
            editingAccessoryView: editingAccessoryView
        )
    }
}
