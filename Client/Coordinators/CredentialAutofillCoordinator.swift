// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Storage
import Shared
import WebKit
import ComponentLibrary

class CredentialAutofillCoordinator: BaseCoordinator {
    // MARK: - Properties

    typealias BottomSheetCardParentCoordinator = BrowserNavigationHandler & ParentCoordinatorDelegate
    private let profile: Profile
    private let themeManager: ThemeManager
    private let tabManager: TabManager
    private weak var parentCoordinator: BottomSheetCardParentCoordinator?

    // MARK: - Inits

    init(
        profile: Profile,
        router: Router,
        parentCoordinator: BottomSheetCardParentCoordinator?,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        tabManager: TabManager = AppContainer.shared.resolve()
    ) {
        self.profile = profile
        self.themeManager = themeManager
        self.tabManager = tabManager
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    // MARK: - Methods

    func showCreditCardAutofill(creditCard: CreditCard?,
                                decryptedCard: UnencryptedCreditCardFields?,
                                viewType state: CreditCardBottomSheetState,
                                frame: WKFrameInfo?,
                                alertContainer: UIView) {
        let creditCardControllerViewModel = CreditCardBottomSheetViewModel(profile: profile,
                                                                           creditCard: creditCard,
                                                                           decryptedCreditCard: decryptedCard,
                                                                           state: state)
        let viewController = CreditCardBottomSheetViewController(viewModel: creditCardControllerViewModel)
        viewController.didTapYesClosure = { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                SimpleToast().showAlertWithText(error.localizedDescription,
                                                bottomContainer: alertContainer,
                                                theme: self.themeManager.currentTheme)
            } else {
                // Save a card telemetry
                if state == .save {
                    TelemetryWrapper.recordEvent(category: .action,
                                                 method: .tap,
                                                 object: .creditCardSavePromptCreate)
                }

                // Save or update a card toast message
                let saveSuccessMessage: String = .CreditCard.RememberCreditCard.CreditCardSaveSuccessToastMessage
                let updateSuccessMessage: String = .CreditCard.UpdateCreditCard.CreditCardUpdateSuccessToastMessage
                let toastMessage: String = state == .save ? saveSuccessMessage : updateSuccessMessage
                SimpleToast().showAlertWithText(toastMessage,
                                                bottomContainer: alertContainer,
                                                theme: self.themeManager.currentTheme)
                self.parentCoordinator?.didFinish(from: self)
            }
        }

        viewController.didTapManageCardsClosure = { [weak self] in
            guard let self = self else { return }
            self.parentCoordinator?.show(settings: .creditCard)
            self.parentCoordinator?.didFinish(from: self)
        }

        viewController.didSelectCreditCardToFill = { [weak self] plainTextCard in
            guard let self = self else { return }
            guard let currentTab = self.tabManager.selectedTab else {
                self.parentCoordinator?.didFinish(from: self)
                return
            }
            CreditCardHelper.injectCardInfo(logger: self.logger,
                                            card: plainTextCard,
                                            tab: currentTab,
                                            frame: frame) { error in
                guard let error = error else {
                    return
                }
                self.logger.log("Credit card bottom sheet injection \(error)",
                                level: .debug,
                                category: .webview)
                self.parentCoordinator?.didFinish(from: self)
            }
        }

        var bottomSheetViewModel = BottomSheetViewModel(closeButtonA11yLabel: .CloseButtonTitle)
        bottomSheetViewModel.shouldDismissForTapOutside = false

        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetViewModel,
            childViewController: viewController
        )
        router.present(bottomSheetVC)
    }

    func showPassCodeController() {
        let passwordController = DevicePasscodeRequiredViewController()
        passwordController.profile = profile
        router.present(passwordController)
    }
}
