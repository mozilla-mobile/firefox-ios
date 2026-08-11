// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

@MainActor
final class ButtonToastTests: XCTestCase {
    func test_buttonToast_withButtonText_tappingButtonInvokesCompletionHandlerWithTrue() {
        var completionResult: Bool?
        let toast = createSubject(buttonText: "Undo") { pressed in
            completionResult = pressed
        }

        toast.roundedButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(completionResult, true)
    }

    func test_buttonToast_withNoButtonText_doesNotAddButtonToView() {
        let toast = createSubject(buttonText: nil)

        XCTAssertNil(toast.roundedButton.superview)
    }

    func test_buttonToast_applyTheme_withStandardTheme_setsTextInvertedForegroundColor() {
        let toast = createSubject(buttonText: "Undo")
        let theme = DarkTheme()

        toast.applyTheme(theme: theme)

        XCTAssertEqual(toast.roundedButton.foregroundColorNormal, theme.colors.textInverted)
        XCTAssertEqual(toast.roundedButton.layer.borderColor, theme.colors.borderInverted.cgColor)
    }

    func test_buttonToast_applyTheme_withNovaTheme_setsTextToastForegroundColor() {
        let toast = createSubject(buttonText: "Undo")
        let theme = NovaDarkTheme()

        toast.applyTheme(theme: theme)

        XCTAssertEqual(toast.roundedButton.foregroundColorNormal, theme.colors.textToast)
    }

    private func createSubject(
        buttonText: String?,
        completion: (@MainActor (Bool) -> Void)? = nil
    ) -> ButtonToast {
        let viewModel = ButtonToastViewModel(labelText: "Test label", buttonText: buttonText)
        let toast = ButtonToast(viewModel: viewModel, theme: DarkTheme(), completion: completion)
        trackForMemoryLeaks(toast)
        return toast
    }
}
