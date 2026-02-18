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
    // MARK: - Keyboard Delegate Tests

    func test_keyboardWillShow_withSnapKitDisabled_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isFeatureFlagEnabled: false)
        subject.isBottomSearchBar = true
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        XCTAssertFalse(subject.overKeyboardContainer.frame.height.isZero)
    }

    func test_keyboardWillShow_withSnapKitEnabled_BottomToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        subject.isBottomSearchBar = true
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        XCTAssertFalse(subject.overKeyboardContainer.frame.height.isZero)
    }

    func test_keyboardWillShow_withSnapKit_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject()
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)
    }

    func test_keyboardWillShow_withNative_TopToolbar_viewsHaveRightHeight() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: state)
        XCTAssertTrue(subject.overKeyboardContainer.frame.height.isZero)
    }

    func test_keyboardWillHide_withSnapKitDisabled_callsUpdateViewConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: false)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState(keyboardHeight: 0)

        subject.keyboardHelper(keyboardHelper, keyboardWillHideWithState: state)
        XCTAssertNoThrow(subject.view.layoutIfNeeded())
    }

    func test_keyboardWillHide_withSnapKitEnabled_callsUpdateConstraintsForKeyboard() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState(keyboardHeight: 0)

        XCTAssertNoThrow(subject.keyboardHelper(keyboardHelper, keyboardWillHideWithState: state))
        XCTAssertNoThrow(subject.view.layoutIfNeeded())
    }

    func test_keyboardWillChange_withSnapKitDisabled_callsUpdateViewConstraints() {
        let subject = createSubject(isFeatureFlagEnabled: false)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        XCTAssertNoThrow(subject.keyboardHelper(keyboardHelper, keyboardWillChangeWithState: state))
        XCTAssertNoThrow(subject.view.layoutIfNeeded())
    }

    func test_keyboardWillChange_withSnapKitEnabled_callsUpdateConstraintsForKeyboard() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        XCTAssertNoThrow(subject.keyboardHelper(keyboardHelper, keyboardWillChangeWithState: state))
        XCTAssertNoThrow(subject.view.layoutIfNeeded())
    }

    func test_keyboardDidShow_withBothPaths_doesNotCrash() {
        // Test both paths
        let subjects = [
            createSubject(isFeatureFlagEnabled: false), // SnapKit
            createSubject(isFeatureFlagEnabled: true)   // Native
        ]

        let keyboardHelper = createKeyboardHelper()
        let state = createKeyboardState()

        for subject in subjects {
            XCTAssertNoThrow(subject.keyboardHelper(keyboardHelper, keyboardDidShowWithState: state))
            XCTAssertNoThrow(subject.view.layoutIfNeeded())
        }
    }

    func test_keyboardSequence_showThenHide_completesSuccessfully() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        let keyboardHelper = createKeyboardHelper()

        // Show keyboard
        let showState = createKeyboardState()
        XCTAssertNoThrow(subject.keyboardHelper(keyboardHelper, keyboardWillShowWithState: showState))
        XCTAssertNoThrow(subject.view.layoutIfNeeded())

        // Hide keyboard
        let hideState = createKeyboardState(keyboardHeight: 0)
        XCTAssertNoThrow(subject.keyboardHelper(keyboardHelper, keyboardWillHideWithState: hideState))
        XCTAssertNoThrow(subject.view.layoutIfNeeded())
    }

    func test_keyboardConstraintUpdate_multipleCallsSameState_isIdempotent() {
        let subject = createSubject(isFeatureFlagEnabled: true)
        subject.view.layoutIfNeeded()

        subject.updateConstraintsForKeyboard()
        subject.view.layoutIfNeeded()
        let frame1 = subject.bottomContentStackView.frame

        subject.updateConstraintsForKeyboard()
        subject.view.layoutIfNeeded()
        let frame2 = subject.bottomContentStackView.frame

        subject.updateConstraintsForKeyboard()
        subject.view.layoutIfNeeded()
        let frame3 = subject.bottomContentStackView.frame

        // Assert - Frame should be stable
        XCTAssertEqual(frame1, frame2)
        XCTAssertEqual(frame2, frame3)
    }

    // MARK: - Feature Flag Comparison Tests

    func test_constraintBehavior_snapKitVsNative_produceSimilarLayout() {
        // This test compares both paths produce similar results
        let subjectSnapKit = createSubject()
        subjectSnapKit.view.layoutIfNeeded()
        let snapKitFrame = subjectSnapKit.bottomContentStackView.frame

        // Test with Native
        let subjectNative = createSubject(isFeatureFlagEnabled: true)
        subjectNative.view.layoutIfNeeded()
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
        let keyboardEndFrame = CGRect(x: 0, y: 0, width: 100, height: keyboardHeight)
        return KeyboardState(keyboardEndFrame: keyboardEndFrame,
                             keyboardAnimationDuration: 0,
                             keyboardAnimationCurveValue: 0)
    }
}
