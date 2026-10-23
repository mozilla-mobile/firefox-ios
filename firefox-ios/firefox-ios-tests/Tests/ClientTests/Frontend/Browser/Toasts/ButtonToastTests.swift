// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import TestKit
import XCTest

@testable import Client

@MainActor
final class ButtonToastTests: XCTestCase {
    func test_buttonToast_withDescriptionText_setsMinimumScaleFactorForTitleLabel() {
        let toast = createSubject(descriptionText: "https://example.com")

        XCTAssertGreaterThan(toast.titleLabel.minimumScaleFactor, 0)
    }

    private func createSubject(descriptionText: String?) -> ButtonToast {
        let viewModel = ButtonToastViewModel(
            labelText: "Test label",
            descriptionText: descriptionText,
            buttonText: "Undo"
        )
        let toast = ButtonToast(viewModel: viewModel, theme: DarkTheme())
        trackForMemoryLeaks(toast)
        return toast
    }
}
