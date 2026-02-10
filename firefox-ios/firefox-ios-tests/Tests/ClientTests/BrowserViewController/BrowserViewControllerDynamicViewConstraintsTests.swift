// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

@MainActor
final class BrowserViewControllerDynamicViewConstraintsTests: XCTestCase {
    var profile: MockProfile!
    var tabManager: MockTabManager!

    override func setUp() async throws {
        try await super.setUp()
        tabManager = MockTabManager()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: tabManager)
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() async throws {
        profile.shutdown()
        profile = nil
        tabManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Reader Mode Bar Tests

    func test_readerModeBar_bottomToolbar_withNativeConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        subject.isBottomSearchBar = true
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 0)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 1)

        // Remove reader mode bar
        subject.hideReaderModeBar(animated: false)
    }

    func test_readerModeBar_bottomToolbar_withSnapkitConstraints() {
        let subject = createSubject()
        subject.isBottomSearchBar = true
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 0)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 1)

        // Remove reader mode bar
        subject.hideReaderModeBar(animated: false)
    }

    func test_readerModeBar_topToolbar_withNativeConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        subject.isBottomSearchBar = false
        XCTAssertEqual(subject.header.subviews.count, 1)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.header.subviews.count, 2)

        // Remove reader mode bar
        subject.hideReaderModeBar(animated: false)
    }

    func test_readerModeBar_topToolbar_withSnapkitConstraints() {
        let subject = createSubject()
        subject.isBottomSearchBar = false
        XCTAssertEqual(subject.header.subviews.count, 1)

        subject.showReaderModeBar(animated: false)
        XCTAssertNotNil(subject.readerModeBar)
        XCTAssertEqual(subject.header.subviews.count, 2)

        // Remove reader mode bar
        subject.hideReaderModeBar(animated: false)
    }

    func test_showReaderModeBar_hasHeightConstraint_withNativeConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: true)

        subject.showReaderModeBar(animated: false)
        subject.view.layoutIfNeeded()

        guard let readerModeBar = subject.readerModeBar else {
            XCTFail("Reader mode bar should exist")
            return
        }

        // Check that height constraint exists
        let hasHeightConstraint = readerModeBar.constraints.contains { constraint in
            constraint.firstAttribute == .height &&
            constraint.constant == UIConstants.ToolbarHeight
        }

        XCTAssertTrue(hasHeightConstraint)
    }

    func test_showReaderModeBar_hasHeightConstraint_withSnapkitConstraints() {
        let subject = createSubject()

        subject.showReaderModeBar(animated: false)
        subject.view.layoutIfNeeded()

        guard let readerModeBar = subject.readerModeBar else {
            XCTFail("Reader mode bar should exist")
            return
        }

        // Check that height constraint exists
        let hasHeightConstraint = readerModeBar.constraints.contains { constraint in
            constraint.firstAttribute == .height &&
            constraint.constant == UIConstants.ToolbarHeight
        }

        XCTAssertTrue(hasHeightConstraint)
    }

    func test_readerModeBar_doesNotAccumulateConstraints_withNativeConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        let initialConstraintCount = subject.view.constraints.count

        for _ in 0..<3 {
            subject.showReaderModeBar(animated: false)
            subject.view.layoutIfNeeded()
            subject.hideReaderModeBar(animated: false)
            subject.view.layoutIfNeeded()
        }

        let finalConstraintCount = subject.view.constraints.count
        XCTAssertEqual(finalConstraintCount, initialConstraintCount)
    }

    func test_readerModeBar_doesNotAccumulateConstraints_withSnapkitConstraints() {
        let subject = createSubject()
        let initialConstraintCount = subject.view.constraints.count

        for _ in 0..<3 {
            subject.showReaderModeBar(animated: false)
            subject.view.layoutIfNeeded()
            subject.hideReaderModeBar(animated: false)
            subject.view.layoutIfNeeded()
        }

        let finalConstraintCount = subject.view.constraints.count
        XCTAssertEqual(finalConstraintCount, initialConstraintCount)
    }

    func test_readerModeBar_snapKitVsNative_produceSimilarLayout() {
        // Test with SnapKit
        let subjectSnapKit = createSubject()
        subjectSnapKit.showReaderModeBar(animated: false)
        subjectSnapKit.view.layoutIfNeeded()
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

    func test_zoomPageBar_topToolbarHeight_withNativeConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        subject.isBottomSearchBar = false

        // Get initial overKeyboardContainer state
        let initialEqualHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .equal
        }
        // Only height constraint is expected and set to equal
        XCTAssertTrue(initialEqualHeightConstraint)
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 1)

        subject.updateZoomPageBarVisibility(visible: true)
        subject.view.layoutIfNeeded()

        let afterAddHasHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .greaterThanOrEqual
        }
        // Height constraint should change to greaterThanOrEqual
        // plus horizontal and vertical constraints for a total of 5
        XCTAssertTrue(afterAddHasHeightConstraint)
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 5)

        // Remove zoom bar
        subject.updateZoomPageBarVisibility(visible: false)
        let afterRemoveHasHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .equal
        }

        // After removal constraint should be back to initial constraint
        XCTAssertTrue(afterRemoveHasHeightConstraint)
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 1)
    }

    func test_zoomPageBar_topToolbarHeight_withSnapkitConstraints() {
        let subject = createSubject()
        subject.isBottomSearchBar = false

        // Get initial overKeyboardContainer state
        let initialEqualHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .equal
        }
        // Only height constraint is expected and set to equal
        XCTAssertTrue(initialEqualHeightConstraint)
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 1)

        subject.updateZoomPageBarVisibility(visible: true)
        subject.view.layoutIfNeeded()

        let afterAddHasHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .greaterThanOrEqual
        }
        // Height constraint should change to greaterThanOrEqual
        // plus horizontal and vertical constraints for a total of 5
        XCTAssertTrue(afterAddHasHeightConstraint)
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 5)

        // Remove zoom bar
        subject.updateZoomPageBarVisibility(visible: false)
        let afterRemoveHasHeightConstraint = subject.overKeyboardContainer.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .equal
        }

        // After removal constraint should be back to initial constraint
        XCTAssertTrue(afterRemoveHasHeightConstraint)
        XCTAssertEqual(subject.overKeyboardContainer.constraints.count, 1)
    }

    func test_zoomPageBar_multipleCycles_maintainsLayout_withNativeConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        subject.isBottomSearchBar = false
        subject.view.layoutIfNeeded()

        let initialFrame = subject.overKeyboardContainer.frame

        for _ in 0..<3 {
            subject.updateZoomPageBarVisibility(visible: true)
            subject.view.layoutIfNeeded()
            subject.updateZoomPageBarVisibility(visible: false)
            subject.view.layoutIfNeeded()
        }

        let finalFrame = subject.overKeyboardContainer.frame
        XCTAssertEqual(initialFrame, finalFrame)
    }

    func test_zoomPageBar_multipleCycles_maintainsLayout_withSnapkitConstraints() {
        let subject = createSubject()
        subject.isBottomSearchBar = false
        subject.view.layoutIfNeeded()

        let initialFrame = subject.overKeyboardContainer.frame

        for _ in 0..<3 {
            subject.updateZoomPageBarVisibility(visible: true)
            subject.view.layoutIfNeeded()
            subject.updateZoomPageBarVisibility(visible: false)
            subject.view.layoutIfNeeded()
        }

        let finalFrame = subject.overKeyboardContainer.frame
        XCTAssertEqual(initialFrame, finalFrame)
    }

    // MARK: - Helper Methods

    private func createSubject(isFeatureFlagEnabled: Bool = false) -> BrowserViewController {
        // Setup feature flag to disabled by default and override only in the test that need it
        setupNimbusSnapKitRemovalTesting(isEnabled: isFeatureFlagEnabled)
        let subject = BrowserViewController(profile: profile,
                                            tabManager: tabManager)
        trackForMemoryLeaks(subject)

        // Trigger view loading and constraint setup
        // SnapKit constraints are created in updateViewConstraints(), so we need to explicitly trigger it
        subject.loadViewIfNeeded()
        subject.view.setNeedsUpdateConstraints()
        subject.view.updateConstraintsIfNeeded()
        subject.view.layoutIfNeeded()

        return subject
    }

    private func setupNimbusSnapKitRemovalTesting(isEnabled: Bool) {
        FxNimbus.shared.features.snapkitRemovalRefactor.with { _, _ in
            return SnapkitRemovalRefactor(enabled: isEnabled)
        }
    }
}
