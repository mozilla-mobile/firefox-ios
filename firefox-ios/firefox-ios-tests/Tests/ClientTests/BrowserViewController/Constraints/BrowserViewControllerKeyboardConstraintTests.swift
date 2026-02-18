// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Example test for updateConstraintsForKeyboard() method
// This tests the native constraint path vs SnapKit path

import Shared
import XCTest

@testable import Client

@MainActor
final class BrowserViewControllerKeyboardConstraintTests: BrowserViewControllerConstraintTestsBase {
    // MARK: - keyboardWillShow Tests

    func test_keyboardWillShow_withSnapKit_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject()
        subject.isBottomSearchBar = true
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()
        let initialFrame = subject.overKeyboardContainer.frame

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        let showFrame = subject.overKeyboardContainer.frame

        XCTAssertNotEqual(initialFrame, showFrame)
    }

    func test_keyboardWillShow_withNative_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        subject.isBottomSearchBar = true
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()
        let initialFrame = subject.overKeyboardContainer.frame

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        let showFrame = subject.overKeyboardContainer.frame

        XCTAssertNotEqual(initialFrame, showFrame)
    }

    func test_keyboardWillShow_withSnapKit_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isBottomSearchBar: false)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()
        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)
    }

    func test_keyboardWillShow_withNative_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isFeatureFlagEnabled: true, isBottomSearchBar: false)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()
        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)

        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)
    }

    // MARK: - keyboardDidShow Tests

    func test_keyboardDidShow_withSnapkit_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject()
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        let initialFrame = subject.overKeyboardContainer.frame

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        let willShowFrame = subject.overKeyboardContainer.frame
        subject.keyboardHelper(keyboardHelper, keyboardDidShowWithState: state)
        let didShowFrame = subject.overKeyboardContainer.frame

        XCTAssertNotEqual(initialFrame, didShowFrame)
        XCTAssertNotEqual(initialFrame, willShowFrame)
    }

    func test_keyboardDidShow_withNative_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        let initialFrame = subject.overKeyboardContainer.frame

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        let willShowFrame = subject.overKeyboardContainer.frame
        subject.keyboardHelper(keyboardHelper, keyboardDidShowWithState: state)
        let didShowFrame = subject.overKeyboardContainer.frame

        XCTAssertNotEqual(initialFrame, didShowFrame)
        XCTAssertNotEqual(initialFrame, willShowFrame)
        XCTAssertEqual(willShowFrame, didShowFrame)
    }

    func test_keyboardDidShow_withSnapKit_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isBottomSearchBar: false)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        subject.keyboardHelper(keyboardHelper, keyboardDidShowWithState: state)
        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)
    }

    func test_keyboardDidShow_withNative_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isFeatureFlagEnabled: true, isBottomSearchBar: false)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        subject.keyboardHelper(keyboardHelper, keyboardDidShowWithState: state)
        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)
    }

    // MARK: - keyboardWillHide Tests

    func test_keyboardWillHide_withSnapKit_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject()
        let keyboardHelper = createKeyboardHelper()

        let initialHeight = subject.overKeyboardContainer.frame.height

        // Show keyboard first
        let showState = createKeyboardState()
        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: showState)
        let showHeight = subject.overKeyboardContainer.frame.height
        XCTAssertNotEqual(initialHeight, showHeight)

        // Hide keyboard
        let hideState = createKeyboardState(keyboardHeight: 0)
        subject.keyboardHelper(keyboardHelper, keyboardWillHideWithState: hideState)
        let hideHeight = subject.overKeyboardContainer.frame.height

        XCTAssertNotEqual(hideHeight, showHeight)
    }

    func test_keyboardWillHide_withNative_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        let keyboardHelper = createKeyboardHelper()
        subject.view.layoutSubviews()

        let initialPosition = subject.overKeyboardContainer.frame.minY

        // Show keyboard first
        let showState = createKeyboardState()
        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: showState)
        let showPosition = subject.overKeyboardContainer.frame.minY
        XCTAssertNotEqual(initialPosition, showPosition)

        // Hide keyboard
        let hideState = createKeyboardState(keyboardHeight: 0)
        subject.keyboardHelper(keyboardHelper, keyboardWillHideWithState: hideState)
        let hidePosition = subject.overKeyboardContainer.frame.minY

        XCTAssertNotEqual(hidePosition, showPosition)
    }

    func test_keyboardWillHide_withSnapKit_TopToolbar_viewsHaveRightHeight() {
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

    func test_keyboardWillHide_withNative_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isFeatureFlagEnabled: true, isBottomSearchBar: false)
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

    func test_keyboardWillChange_withSnapKit_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject()
        let keyboardHelper = createKeyboardHelper()

        // Show keyboard first
        let showState = createKeyboardState(keyboardHeight: 300)
        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: showState)
        let initialFrame = subject.overKeyboardContainer.frame

        // Change keyboard size
        let changeState = createKeyboardState(keyboardHeight: 250)
        subject.keyboardHelper(keyboardHelper, keyboardWillChangeWithState: changeState)
        let changedFrame = subject.overKeyboardContainer.frame

        // Container should still have non-zero height
        XCTAssertFalse(subject.overKeyboardContainer.frame.height.isZero)
        // Frame should have changed due to different keyboard size
        XCTAssertNotEqual(initialFrame, changedFrame)
    }

    func test_keyboardWillChange_withNative_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        let keyboardHelper = createKeyboardHelper()

        let initialFrame = subject.overKeyboardContainer.frame
        // Show keyboard first
        let showState = createKeyboardState(keyboardHeight: 300)
        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: showState)

        // Change keyboard size
        let changeState = createKeyboardState(keyboardHeight: 250)
        subject.keyboardHelper(keyboardHelper, keyboardWillChangeWithState: changeState)
        let changedFrame = subject.overKeyboardContainer.frame

        // Container should still have non-zero height
        XCTAssertFalse(subject.overKeyboardContainer.frame.height.isZero)
        // Frame should have changed due to different keyboard size
        XCTAssertNotEqual(initialFrame, changedFrame)
    }

    func test_keyboardWillChange_withSnapKit_TopToolbar_viewsHaveRightHeight() {
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

    func test_keyboardWillChange_withNative_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isFeatureFlagEnabled: true, isBottomSearchBar: false)
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
        let subject = createSubject(isFeatureFlagEnabled: true)
        let keyboardHelper = createKeyboardHelper()

        // Show keyboard
        let showState = createKeyboardState()
        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: showState)

        // Hide keyboard
        let hideState = createKeyboardState(keyboardHeight: 0)
        subject.keyboardHelper(keyboardHelper, keyboardWillHideWithState: hideState)
    }

    // MARK: - Feature Flag Comparison Tests

    func test_constraintBehavior_snapKitVsNative_produceSimilarLayout() {
        // This test compares both paths produce similar results
        let subjectSnapKit = createSubject()
        let snapKitFrame = subjectSnapKit.bottomContentStackView.frame

        // Test with Native
        let subjectNative = createSubject(isFeatureFlagEnabled: true)
        let nativeFrame = subjectNative.bottomContentStackView.frame

        XCTAssertEqual(snapKitFrame.origin.x, nativeFrame.origin.x, accuracy: 1.0)
        XCTAssertEqual(snapKitFrame.origin.y, nativeFrame.origin.y, accuracy: 1.0)
        XCTAssertEqual(snapKitFrame.size.width, nativeFrame.size.width, accuracy: 1.0)
        XCTAssertEqual(snapKitFrame.size.height, nativeFrame.size.height, accuracy: 1.0)
    }

    // MARK: Private helpers

    private func createKeyboardHelper() -> KeyboardHelper {
        return KeyboardHelper.defaultHelper
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
