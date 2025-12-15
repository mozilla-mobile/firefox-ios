// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import SwiftUI
import Common
@testable import Client

final class CreditCardSettingsViewControllerTests: XCTestCase {
    var profile: MockProfile!
    var viewModel: CreditCardInputViewModel!

    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        viewModel = CreditCardInputViewModel(profile: profile, creditCardProvider: MockCreditCardProvider())
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
        viewModel = nil
        try await super.tearDown()
    }

    @MainActor
    func testInputViewFormValuesClearedOnDismiss() {
        let subject = createSubject()
        subject.viewModel.cardInputViewModel.nameOnCard = "Ashton Mealy"
        subject.viewModel.cardInputViewModel.cardNumber = "4268811063712243"
        subject.viewModel.cardInputViewModel.expirationDate = "1288"
        let creditCardInputView = CreditCardInputView(
            viewModel: viewModel,
            windowUUID: WindowUUID.XCTestDefaultUUID,
            themeManager: MockThemeManager()
        )
        let hostingController = UIHostingController(rootView: creditCardInputView)
        subject.present(hostingController, animated: true)
        let presentationController = UIPresentationController(
            presentedViewController: hostingController,
            presenting: subject
        )

        // Dismissing CreditCardInputView should clear form values
        subject.presentationControllerDidDismiss(presentationController)

        XCTAssertTrue(subject.viewModel.cardInputViewModel.nameOnCard.isEmpty)
        XCTAssertTrue(subject.viewModel.cardInputViewModel.cardNumber.isEmpty)
        XCTAssertTrue(subject.viewModel.cardInputViewModel.expirationDate.isEmpty)
    }

    @MainActor
    private func createSubject() -> CreditCardSettingsViewController {
        let creditCardSettingsViewModel = CreditCardSettingsViewModel(
            profile: profile,
            windowUUID: WindowUUID.XCTestDefaultUUID
        )
        creditCardSettingsViewModel.toggleModel = ToggleModel(isEnabled: false)
        let subject = CreditCardSettingsViewController(creditCardViewModel: creditCardSettingsViewModel)
        return subject
    }
}
