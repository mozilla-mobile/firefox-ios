// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import Client

@MainActor
final class ButtonToastTests: XCTestCase {
    private var toast: ButtonToast!

    override func setUp() async throws {
        try await super.setUp()
        let viewModel = ButtonToastViewModel(labelText: "file.pdf",
                                             imageName: StandardImageIdentifiers.Large.checkmark,
                                             buttonText: "Downloads")
        toast = ButtonToast(viewModel: viewModel, theme: LightTheme())
    }

    override func tearDown() async throws {
        toast = nil
        try await super.tearDown()
    }

    func testUsesAccessibilityLayout_onlyForAccessibilitySizesOnCompactWidth() {
        XCTAssertTrue(ButtonToast.usesAccessibilityLayout(contentSizeCategory: .accessibilityMedium,
                                                          horizontalSizeClass: .compact))
        XCTAssertFalse(ButtonToast.usesAccessibilityLayout(contentSizeCategory: .accessibilityMedium,
                                                           horizontalSizeClass: .regular))
        XCTAssertFalse(ButtonToast.usesAccessibilityLayout(contentSizeCategory: .large,
                                                           horizontalSizeClass: .compact))
        XCTAssertFalse(ButtonToast.usesAccessibilityLayout(contentSizeCategory: .large,
                                                           horizontalSizeClass: .regular))
    }

    // Regression test for FXIOS-11656: the toast button must use target-action so taps keep
    // working on iPad, instead of a tap gesture recognizer that can be intercepted by the
    // toast's own dismiss gesture.
    func testButton_usesTargetActionNotGestureRecognizer() throws {
        let button = try XCTUnwrap(toast.actionView as? UIButton)
        let actions = button.actions(forTarget: toast, forControlEvent: .touchUpInside)
        XCTAssertEqual(actions, ["buttonPressed"])
    }

    func testButtonPress_invokesCompletionAndDismisses() {
        var completionResult: Bool?
        let viewModel = ButtonToastViewModel(labelText: "file.pdf",
                                             imageName: StandardImageIdentifiers.Large.checkmark,
                                             buttonText: "Downloads")
        let toast = ButtonToast(viewModel: viewModel, theme: LightTheme()) { buttonPressed in
            completionResult = buttonPressed
        }

        toast.buttonPressed()

        XCTAssertEqual(completionResult, true)
        XCTAssertTrue(toast.dismissed)
    }

    // Regression test: re-applying the layout after the toast is already built must not
    // crash. The button's insertion index is computed before it is removed from the stack,
    // so without clamping, inserting it back into the same stack goes out of bounds.
    func testAdjustLayout_reappliedAfterAttach_doesNotCrash() {
        let hostView = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 200))
        hostView.addSubview(toast)

        toast.adjustLayoutForA11ySizeCategory()
        toast.adjustLayoutForA11ySizeCategory()

        toast.removeFromSuperview()
    }
}
