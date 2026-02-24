// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

@MainActor
final class BrowserViewControllerDynamicViewConstraintsTests: BrowserViewControllerConstraintTestsBase {
    // MARK: - Reader Mode Bar Tests

    func test_readerModeBar_bottomToolbar_withNativeConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 1)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 2)

        // Remove reader mode bar
        subject.hideReaderModeBar(animated: false)
    }

    func test_readerModeBar_TopToolbar_withNativeConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: true, isBottomSearchBar: false)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 0)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 0)

        // Remove reader mode bar
        subject.hideReaderModeBar(animated: false)
    }

    func test_readerModeBar_bottomToolbar_withSnapkitConstraints() {
        let subject = createSubject()
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 1)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 2)
    }

    func test_readerModeBar_topToolbar_withNativeConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: true, isBottomSearchBar: false)
        subject.isBottomSearchBar = false
        XCTAssertEqual(subject.header.subviews.count, 1)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.header.subviews.count, 2)
    }

    func test_readerModeBar_topToolbar_withSnapkitConstraints() {
        let subject = createSubject()
        subject.isBottomSearchBar = false
        XCTAssertEqual(subject.header.subviews.count, 0)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.header.subviews.count, 1)
    }

    func test_showReaderModeBar_hasHeightConstraint_withSnapkit() {
        checkReaderModeHeightConstraint(isFeatureFlagEnabled: false)
    }

    func test_showReaderModeBar_hasHeightConstraint_withNative() {
        checkReaderModeHeightConstraint(isFeatureFlagEnabled: true)
    }

    func test_readerModeBar_doesNotAccumulateConstraints_withNativeConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        let initialConstraintCount = subject.view.constraints.count

        subject.showReaderModeBar(animated: false)
        subject.hideReaderModeBar(animated: false)

        let finalConstraintCount = subject.view.constraints.count
        XCTAssertEqual(finalConstraintCount, initialConstraintCount)
    }

    func test_readerModeBar_doesNotAccumulateConstraints_withSnapkitConstraints() {
        let subject = createSubject(isBottomSearchBar: false)
        let initialConstraintCount = subject.view.constraints.count

        subject.showReaderModeBar(animated: false)
        subject.hideReaderModeBar(animated: false)

        let finalConstraintCount = subject.view.constraints.count
        XCTAssertEqual(finalConstraintCount, initialConstraintCount)
    }

    func test_readerModeBar_snapKitVsNative_produceSimilarLayout() {
        // Test with SnapKit
        let subjectSnapKit = createSubject()
        subjectSnapKit.showReaderModeBar(animated: false)
        let snapKitFrame = subjectSnapKit.readerModeBar?.frame

        // Test with Native
        let subjectNative = createSubject(isFeatureFlagEnabled: true)
        subjectNative.showReaderModeBar(animated: false)
        subjectNative.view.layoutIfNeeded()
        let nativeFrame = subjectNative.readerModeBar?.frame

        // Heights should match
        XCTAssertEqual(snapKitFrame?.size.height ?? 0, nativeFrame?.size.height ?? 0)
    }

    // MARK: - Zoom Page Bar Tests

    func test_zoomPageBar_topToolbarHeight_withSnapkit() {
        checkZoomPageBarHeightConstraint(isFeatureFlagEnabled: false)
    }

    func test_zoomPageBar_topToolbarHeight_withNative() {
        checkZoomPageBarHeightConstraint(isFeatureFlagEnabled: true)
    }

    func test_zoomPageBar_multipleCycles_maintainsLayout_withNativeConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: true, isBottomSearchBar: false)

        let initialFrame = subject.overKeyboardContainer.frame

        subject.updateZoomPageBarVisibility(visible: true)
        subject.updateZoomPageBarVisibility(visible: false)

        let finalFrame = subject.overKeyboardContainer.frame
        XCTAssertEqual(initialFrame, finalFrame)
    }

    func test_zoomPageBar_multipleCycles_maintainsLayout_withSnapkitConstraints() {
        let subject = createSubject(isBottomSearchBar: false)

        let initialFrame = subject.overKeyboardContainer.frame

        subject.updateZoomPageBarVisibility(visible: true)
        subject.updateZoomPageBarVisibility(visible: false)

        let finalFrame = subject.overKeyboardContainer.frame
        XCTAssertEqual(initialFrame, finalFrame)
    }

    // MARK: - Private

    private func checkReaderModeHeightConstraint(isFeatureFlagEnabled: Bool) {
        let subject = createSubject(isFeatureFlagEnabled: isFeatureFlagEnabled)

        subject.showReaderModeBar(animated: false)

        guard let readerModeBar = subject.readerModeBar else {
            XCTFail("Reader mode bar should exist")
            return
        }

        let hasHeightConstraint = readerModeBar.constraints.contains { constraint in
            constraint.firstAttribute == .height &&
            constraint.constant == UIConstants.ToolbarHeight
        }
        XCTAssertTrue(hasHeightConstraint, "Failed for isFeatureFlagEnabled: \(isFeatureFlagEnabled)")
    }

    private func checkZoomPageBarHeightConstraint(isFeatureFlagEnabled: Bool) {
        let subject = createSubject(isFeatureFlagEnabled: isFeatureFlagEnabled, isBottomSearchBar: false)

        // Only height constraint is expected and set to equal
        let initialEqualHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .equal
        }
        XCTAssertTrue(initialEqualHeightConstraint, "Failed for isFeatureFlagEnabled: \(isFeatureFlagEnabled)")
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 1)

        subject.updateZoomPageBarVisibility(visible: true)
        subject.view.layoutIfNeeded()

        // Height constraint should change to greaterThanOrEqual
        // plus horizontal and vertical constraints for a total of 5
        let afterAddHasHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .greaterThanOrEqual
        }
        XCTAssertTrue(afterAddHasHeightConstraint, "Failed for isFeatureFlagEnabled: \(isFeatureFlagEnabled)")
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 5)

        // After removal constraint should be back to initial constraint
        subject.updateZoomPageBarVisibility(visible: false)
        let afterRemoveHasHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .equal
        }
        XCTAssertTrue(afterRemoveHasHeightConstraint, "Failed for isFeatureFlagEnabled: \(isFeatureFlagEnabled)")
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 1)
    }
}
