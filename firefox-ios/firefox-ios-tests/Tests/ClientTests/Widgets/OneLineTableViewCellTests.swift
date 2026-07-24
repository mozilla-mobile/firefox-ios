// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class OneLineTableViewCellTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - layoutSubviews

    func testLayoutSubviews_nonEditingMode_accessoryViewPositionedAtTrailingEdge() {
        let subject = createSubject()
        subject.frame = CGRect(x: 0, y: 0, width: 375, height: 44)
        subject.configure(viewModel: createViewModel(withAccessory: true))

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
            accuracy: 0.5,
            "In non-editing mode the accessory view should be positioned at the trailing edge"
        )
    }

    func testLayoutSubviews_editingMode_accessoryViewNotRepositioned() {
        let subject = createSubject()
        subject.frame = CGRect(x: 0, y: 0, width: 375, height: 44)
        subject.configure(viewModel: createViewModel(withAccessory: true))

        let manualX = subject.frame.width
            - (subject.accessoryView?.frame.width ?? 0)
            - OneLineTableViewCell.UX.accessoryViewTrailingPadding
            - subject.safeAreaInsets.right

        subject.isEditing = true
        subject.layoutSubviews()

        if let accessoryView = subject.accessoryView {
            XCTAssertNotEqual(
                accessoryView.frame.origin.x,
                manualX,
                "In editing mode the accessory view should NOT be manually repositioned"
            )
        }
    }

    func testLayoutSubviews_noAccessoryView_noOp() {
        let subject = createSubject()
        subject.frame = CGRect(x: 0, y: 0, width: 375, height: 44)
        subject.configure(viewModel: createViewModel(withAccessory: false))

        subject.layoutSubviews()

        XCTAssertNil(subject.accessoryView)
    }

    // MARK: - configure

    func testConfigure_setsAccessoryAndEditingAccessory() {
        let subject = createSubject()
        subject.configure(viewModel: createViewModel(withAccessory: true, withEditingAccessory: true))

        XCTAssertNotNil(subject.accessoryView, "accessoryView should be set after configure")
        XCTAssertNotNil(subject.editingAccessoryView, "editingAccessoryView should be set after configure")
    }

    // MARK: - Helpers

    private func createSubject() -> OneLineTableViewCell {
        let subject = OneLineTableViewCell(style: .default, reuseIdentifier: OneLineTableViewCell.cellIdentifier)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func createViewModel(
        withAccessory: Bool,
        withEditingAccessory: Bool = false
    ) -> OneLineTableViewCellViewModel {
        let accessoryView: UIView? = withAccessory ? UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24)) : nil
        let editingAccessoryView: UIImageView? = withEditingAccessory
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
