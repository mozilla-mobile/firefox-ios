// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

@MainActor
final class BrowserViewControllerDynamicViewConstraintsTests: BrowserViewControllerConstraintTestsBase {
    // MARK: - Reader Mode Bar Tests

    func test_readerModeBar_bottomToolbar() {
        let subject = createSubject()
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 1)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 2)

        // Remove reader mode bar
        subject.hideReaderModeBar(animated: false)
    }

    func test_readerModeBar_TopToolbar() {
        let subject = createSubject(isBottomSearchBar: false)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 0)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 0)

        // Remove reader mode bar
        subject.hideReaderModeBar(animated: false)
    }

    func test_readerModeBar_topToolbar() {
        let subject = createSubject(isBottomSearchBar: false)
        subject.isBottomSearchBar = false
        XCTAssertEqual(subject.header.subviews.count, 1)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.header.subviews.count, 2)
    }

    func test_showReaderModeBar_hasHeightConstraint() {
        checkReaderModeHeightConstraint()
    }

    func test_readerModeBar_doesNotAccumulateConstraints() {
        let subject = createSubject()
        let initialConstraintCount = subject.view.constraints.count

        subject.showReaderModeBar(animated: false)
        subject.hideReaderModeBar(animated: false)

        let finalConstraintCount = subject.view.constraints.count
        XCTAssertEqual(finalConstraintCount, initialConstraintCount)
    }

    // MARK: - Zoom Page Bar Tests

    func test_zoomPageBar_topToolbarHeight() {
        checkZoomPageBarHeightConstraint()
    }

    func test_zoomPageBar_multipleCycles_maintainsLayout() {
        let subject = createSubject(isBottomSearchBar: false)

        let initialFrame = subject.overKeyboardContainer.frame

        subject.updateZoomPageBarVisibility(visible: true)
        subject.updateZoomPageBarVisibility(visible: false)

        let finalFrame = subject.overKeyboardContainer.frame
        XCTAssertEqual(initialFrame, finalFrame)
    }

    // MARK: - Private

    private func checkReaderModeHeightConstraint() {
        let subject = createSubject()

        subject.showReaderModeBar(animated: false)

        guard let readerModeBar = subject.readerModeBar else {
            XCTFail("Reader mode bar should exist")
            return
        }

        let hasHeightConstraint = readerModeBar.constraints.contains { constraint in
            constraint.firstAttribute == .height &&
            constraint.constant == UIConstants.ToolbarHeight
        }
        XCTAssertTrue(hasHeightConstraint)
    }

    private func checkZoomPageBarHeightConstraint() {
        let subject = createSubject(isBottomSearchBar: false)

        // Only height constraint is expected and set to equal
        let initialEqualHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .equal
        }
        XCTAssertTrue(initialEqualHeightConstraint)
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 1)

        subject.updateZoomPageBarVisibility(visible: true)
        subject.view.layoutIfNeeded()

        // Height constraint should change to greaterThanOrEqual
        // plus horizontal and vertical constraints for a total of 5
        let afterAddHasHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .greaterThanOrEqual
        }
        XCTAssertTrue(afterAddHasHeightConstraint)
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 5)

        // After removal constraint should be back to initial constraint
        subject.updateZoomPageBarVisibility(visible: false)
        let afterRemoveHasHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .equal
        }
        XCTAssertTrue(afterRemoveHasHeightConstraint)
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 1)
    }
}
