// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Example test for updateConstraintsForKeyboard() method

import Shared
import XCTest

@testable import Client

@MainActor
final class BrowserViewControllerKeyboardConstraintTests: BrowserViewControllerConstraintTestsBase {
    // MARK: - keyboardWillShow Tests

    func test_keyboardWillShow_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject()
        selectTabWithFindInPage()
        let state = createKeyboardState()
        let keyboardHelper = createKeyboardHelper()
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 1)

        // BottomToolbar keyboard spacer is added as subview and over keyboard frame doesn't change
        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 2)
    }

    func test_keyboardWillShow_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isBottomSearchBar: false)
        selectTabWithFindInPage()
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()
        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)

        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)
    }

    // MARK: - keyboardDidShow Tests

    func test_keyboardDidShow_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject()
        selectTabWithFindInPage()
        let state = createKeyboardState()
        let keyboardHelper = createKeyboardHelper()
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 1)

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 2)
        subject.keyboardHelper(keyboardHelper, keyboardDidShowWithState: state)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 2)
    }

    func test_keyboardDidShow_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isBottomSearchBar: false)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        subject.keyboardHelper(keyboardHelper, keyboardDidShowWithState: state)
        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)
    }

    // MARK: - keyboardWillHide Tests

    func test_keyboardWillHide_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject()
        selectTabWithFindInPage()
        let keyboardHelper = createKeyboardHelper()

        // Show keyboard first
        let showState = createKeyboardState()
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 1)
        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: showState)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 2)

        // Hide keyboard
        let hideState = createKeyboardState(keyboardHeight: 0)
        subject.keyboardHelper(keyboardHelper, keyboardWillHideWithState: hideState)
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 1)
    }

    func test_keyboardWillHide_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isBottomSearchBar: false)
        let keyboardHelper = createKeyboardHelper()

        // Show keyboard first
        let showState = createKeyboardState()
        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: showState)

        // Hide keyboard
        let hideState = createKeyboardState(keyboardHeight: 0)
        subject.keyboardHelper(keyboardHelper, keyboardWillHideWithState: hideState)

        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)
    }

    // MARK: - keyboardWillChange Tests

    func test_keyboardWillChange_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject()
        selectTabWithFindInPage()
        let keyboardHelper = createKeyboardHelper()

        let initialFrame = subject.overKeyboardContainer.frame
        // Show keyboard first
        let showState = createKeyboardState(keyboardHeight: 300)
        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: showState)

        // Change keyboard size
        let changeState = createKeyboardState(keyboardHeight: 250)
        subject.keyboardHelper(keyboardHelper, keyboardWillChangeWithState: changeState)
        subject.view.layoutIfNeeded()
        let changedFrame = subject.overKeyboardContainer.frame

        // Container should still have non-zero height
        XCTAssertFalse(subject.overKeyboardContainer.frame.height.isZero)
        // Frame should have changed due to different keyboard size
        XCTAssertNotEqual(initialFrame, changedFrame)
    }

    func test_keyboardWillChange_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isBottomSearchBar: false)
        let keyboardHelper = createKeyboardHelper()

        // Show keyboard first
        let showState = createKeyboardState(keyboardHeight: 300)
        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: showState)

        // Change keyboard size
        let changeState = createKeyboardState(keyboardHeight: 250)
        subject.keyboardHelper(keyboardHelper, keyboardWillChangeWithState: changeState)

        // Top toolbar: container should remain zero height
        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)
    }

    func test_keyboardSequence_showThenHide_completesSuccessfully() {
        let subject = createSubject()
        let keyboardHelper = createKeyboardHelper()

        // Show keyboard
        let showState = createKeyboardState()
        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: showState)

        // Hide keyboard
        let hideState = createKeyboardState(keyboardHeight: 0)
        subject.keyboardHelper(keyboardHelper, keyboardWillHideWithState: hideState)
    }

    // MARK: - bottomContentStackView Position Tests

    func test_keyboardWillShow_TopToolbar_bottomContentNoUpdate() {
        let subject = createSubject(isBottomSearchBar: false)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()
        let initialPosition = subject.bottomContentStackView.frame.maxY

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        let showPosition = subject.bottomContentStackView.frame.maxY

        XCTAssertEqual(initialPosition, showPosition)
    }

    // MARK: - Rotation and keyboard race

    /// The keyboard spacer must track the nav toolbar's actual `isHidden` state, not a separately
    /// derived guess, and must be recomputed whenever that state changes.
    func test_rotationWhileKeyboardVisible_keyboardSpacerTracksNavToolbarVisibility() {
        let subject = createSubject()
        selectTabWithFindInPage()
        let keyboardHelper = createKeyboardHelper()
        let keyboardHeight: CGFloat = 300

        // Landscape: nav toolbar hidden, bottomContainer collapses.
        subject.updateToolbarStateForTraitCollection(landscapeTraitCollection())
        subject.view.layoutIfNeeded()
        XCTAssertTrue(subject.bottomContainer.frame.height.isZero)

        // Keyboard shows while the nav toolbar is still hidden — nothing should be subtracted from
        // the spacer since there's no nav toolbar behind the keyboard yet.
        subject.keyboardHelper(keyboardHelper,
                               keyboardWillShowWithState: createKeyboardState(keyboardHeight: keyboardHeight))
        subject.view.layoutIfNeeded()
        XCTAssertEqual(keyboardSpacerHeightConstant(in: subject.overKeyboardContainer) ?? -1,
                       keyboardHeight,
                       accuracy: 0.5)

        // Rotation settles and the nav toolbar unhides; nothing else fires.
        subject.updateToolbarStateForTraitCollection(portraitTraitCollection())
        subject.view.layoutIfNeeded()
        XCTAssertFalse(subject.bottomContainer.frame.height.isZero)

        // Spacer should shrink by the nav toolbar's height, to stay flush above the keyboard.
        XCTAssertEqual(keyboardSpacerHeightConstant(in: subject.overKeyboardContainer) ?? -1,
                       keyboardHeight - UIConstants.BottomToolbarHeight,
                       accuracy: 0.5)
    }

    /// Hiding the keyboard doesn't depend on the spacer's height, so it should clean up the spacer
    /// even after the race above has left it stale.
    func test_rotationWhileKeyboardVisible_keyboardSpacerIsRemovedOnHide() {
        let subject = createSubject()
        selectTabWithFindInPage()
        let keyboardHelper = createKeyboardHelper()

        subject.updateToolbarStateForTraitCollection(landscapeTraitCollection())
        subject.view.layoutIfNeeded()

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: createKeyboardState(keyboardHeight: 300))
        subject.view.layoutIfNeeded()

        subject.updateToolbarStateForTraitCollection(portraitTraitCollection())
        subject.view.layoutIfNeeded()
        XCTAssertNotNil(keyboardSpacerHeightConstant(in: subject.overKeyboardContainer))

        subject.keyboardHelper(keyboardHelper, keyboardWillHideWithState: createKeyboardState(keyboardHeight: 0))
        subject.view.layoutIfNeeded()

        XCTAssertNil(keyboardSpacerHeightConstant(in: subject.overKeyboardContainer))
        XCTAssertEqual(subject.overKeyboardContainer.subviews.count, 1)
    }

    /// Unlike the bottom-search-bar spacer, the top-search-bar keyboard constraint pins straight to
    /// `parentView.bottom - keyboardHeight` and never factors in the nav toolbar's height, so it
    /// shouldn't be affected by the same nav-toolbar-visibility race.
    func test_rotationWhileKeyboardVisible_topSearchBar_bottomContentStaysAboveKeyboard() {
        let subject = createSubject(isBottomSearchBar: false)
        let keyboardHelper = createKeyboardHelper()
        let keyboardHeight: CGFloat = 300

        subject.updateToolbarStateForTraitCollection(landscapeTraitCollection())
        subject.view.layoutIfNeeded()

        subject.keyboardHelper(keyboardHelper,
                               keyboardWillShowWithState: createKeyboardState(keyboardHeight: keyboardHeight))
        subject.view.layoutIfNeeded()

        subject.updateToolbarStateForTraitCollection(portraitTraitCollection())
        subject.view.layoutIfNeeded()

        let expectedMaxY = subject.view.frame.height - keyboardHeight
        XCTAssertEqual(subject.bottomContentStackView.frame.maxY, expectedMaxY, accuracy: 0.5)
    }

    /// A trait change that skips `willTransition` (Dark Mode, Stage Manager resize) only reaches
    /// `navigationToolbarContainer` via `traitCollectionDidChange`'s deferred `DispatchQueue.main.async`
    /// update. Confirms the keyboard spacer still ends up correct once that deferred update runs.
    func test_nonRotationTraitChangeWhileKeyboardVisible_keyboardSpacerRecomputesAfterDeferredUpdate() {
        let subject = createSubject()
        selectTabWithFindInPage()
        let keyboardHelper = createKeyboardHelper()
        let keyboardHeight: CGFloat = 300

        // Nav toolbar hidden, as if a prior `willTransition` already set this for landscape.
        subject.updateToolbarStateForTraitCollection(landscapeTraitCollection())
        subject.view.layoutIfNeeded()

        // Keyboard shows while the nav toolbar is still hidden.
        subject.keyboardHelper(keyboardHelper,
                               keyboardWillShowWithState: createKeyboardState(keyboardHeight: keyboardHeight))
        subject.view.layoutIfNeeded()

        // `self.traitCollection` flips to portrait without going through `willTransition`, nothing
        // has updated `navigationToolbarContainer` or the spacer yet.
        let container = UIViewController()
        container.addChild(subject)
        container.setOverrideTraitCollection(portraitTraitCollection(), forChild: subject)
        XCTAssertEqual(subject.traitCollection.verticalSizeClass, .regular)

        // Only `traitCollectionDidChange`'s deferred update is left to fix this.
        subject.traitCollectionDidChange(landscapeTraitCollection())
        let expectation = expectation(description: "deferred toolbar state update runs")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1)
        subject.view.layoutIfNeeded()

        XCTAssertFalse(subject.bottomContainer.frame.height.isZero)
        XCTAssertEqual(keyboardSpacerHeightConstant(in: subject.overKeyboardContainer) ?? -1,
                       keyboardHeight - UIConstants.BottomToolbarHeight,
                       accuracy: 0.5)
    }

    // MARK: Private helpers

    private func createKeyboardHelper() -> KeyboardHelper {
        return KeyboardHelper.defaultHelper
    }

    private func landscapeTraitCollection() -> UITraitCollection {
        return UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .compact),
            UITraitCollection(horizontalSizeClass: .compact)
        ])
    }

    private func portraitTraitCollection() -> UITraitCollection {
        return UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .regular),
            UITraitCollection(horizontalSizeClass: .compact)
        ])
    }

    /// Reads the spacer's height constraint constant instead of its frame, so this doesn't depend
    /// on a specific layout pass having fully resolved.
    private func keyboardSpacerHeightConstant(in stackView: BaseAlphaStackView) -> CGFloat? {
        let spacer = stackView.subviews.first {
            $0.accessibilityIdentifier == AccessibilityIdentifiers.Browser.keyboardSpacer
        }
        return spacer?.constraints.first { $0.firstAttribute == .height && $0.secondItem == nil }?.constant
    }

    private func createKeyboardState(keyboardHeight: CGFloat = 300) -> KeyboardState {
        // Create a realistic keyboard frame at the bottom of the screen
        let screenHeight: CGFloat = 844
        let screenWidth: CGFloat = 390
        let keyboardEndFrame = CGRect(
            x: 0,
            y: screenHeight - keyboardHeight,
            width: screenWidth,
            height: keyboardHeight
        )
        return KeyboardState(keyboardEndFrame: keyboardEndFrame,
                             keyboardAnimationDuration: 0,
                             keyboardAnimationCurveValue: 0)
    }
}
