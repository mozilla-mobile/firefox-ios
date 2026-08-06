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
