// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import TestKit
import XCTest

@testable import Client

@available(iOS 16.0, *)
@MainActor
final class PasteControlToastTests: XCTestCase {
    func test_pasteControlToast_pasteControlResistsCompressionMoreThanLabelStack() {
        let toast = createSubject()

        let pasteControlPriority = toast.pasteControl.contentCompressionResistancePriority(for: .horizontal)
        let labelStackPriority = toast.labelStackView.contentCompressionResistancePriority(for: .horizontal)

        XCTAssertGreaterThan(pasteControlPriority.rawValue, labelStackPriority.rawValue)
    }

    func test_pasteControlToast_pasteControlHugsMoreThanLabelStack() {
        let toast = createSubject()

        let pasteControlPriority = toast.pasteControl.contentHuggingPriority(for: .horizontal)
        let labelStackPriority = toast.labelStackView.contentHuggingPriority(for: .horizontal)

        XCTAssertGreaterThan(pasteControlPriority.rawValue, labelStackPriority.rawValue)
    }

    private func createSubject() -> PasteControlToast {
        let viewModel = ButtonToastViewModel(labelText: "Test label")
        let toast = PasteControlToast(viewModel: viewModel, theme: DarkTheme(), target: nil)
        trackForMemoryLeaks(toast)
        return toast
    }
}
