// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Storage
import Shared
import WebKit
import ComponentLibrary

import struct MozillaAppServices.CreditCard

class CredentialAutofillCoordinator: BaseCoordinator {
    // MARK: - Properties

    typealias BottomSheetCardParentCoordinator = BrowserNavigationHandler & ParentCoordinatorDelegate
    private let profile: Profile
    private let themeManager: ThemeManager
    private let tabManager: TabManager
    private weak var parentCoordinator: BottomSheetCardParentCoordinator?
    private var windowUUID: WindowUUID { return tabManager.windowUUID }

    // MARK: - Inits

    init(
        profile: Profile,
        router: Router,
        parentCoordinator: BottomSheetCardParentCoordinator?,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        tabManager: TabManager
    ) {
        self.profile = profile
        self.themeManager = themeManager
        self.tabManager = tabManager
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    // MARK: - Methods

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }

    func showCreditCardAutofill(creditCard: CreditCard?,
                                decryptedCard: UnencryptedCreditCardFields?,
                                viewType state: CreditCardBottomSheetState,
                                frame: WKFrameInfo?,
                                alertContainer: UIView) {
        let creditCardControllerViewModel = CreditCardBottomSheetViewModel(creditCardProvider: profile.autofill,
                                                                           creditCard: creditCard,
                                                                           decryptedCreditCard: decryptedCard,
                                                                           state: state)
        let viewController = CreditCardBottomSheetViewController(viewModel: creditCardControllerViewModel,
                                                                 windowUUID: windowUUID)
        viewController.didTapYesClosure = { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                SimpleToast().showAlertWithText(error.localizedDescription,
                                                bottomContainer: alertContainer,
                                                theme: self.currentTheme())
            } else {
                // send telemetry
                if state == .save {
                    sendCreditCardSavePromptCreateTelemetry()
                } else if state == .update {
                    sendCreditCardSavePromptUpdateTelemetry()
                }

                // Save or update a card toast message
                let saveSuccessMessage: String = .CreditCard.RememberCreditCard.CreditCardSaveSuccessToastMessage
                let updateSuccessMessage: String = .CreditCard.UpdateCreditCard.CreditCardUpdateSuccessToastMessage
                let toastMessage: String = state == .save ? saveSuccessMessage : updateSuccessMessage
                SimpleToast().showAlertWithText(toastMessage,
                                                bottomContainer: alertContainer,
                                                theme: self.currentTheme())
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
            FormAutofillHelper.injectCardInfo(logger: self.logger,
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

        var bottomSheetViewModel = BottomSheetViewModel(
            closeButtonA11yLabel: .CloseButtonTitle,
            closeButtonA11yIdentifier: AccessibilityIdentifiers.Autofill.creditCardCloseButton
        )
        bottomSheetViewModel.shouldDismissForTapOutside = false

        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetViewModel,
            childViewController: viewController,
            windowUUID: windowUUID
        )
        router.present(bottomSheetVC)
        if state == .save {
            sendCreditCardSavePromptShownTelemetry()
        } else if state == .selectSavedCard {
            sendCreditCardAutofillPromptExpandedTelemetry()
        }
    }

    @MainActor
    func showSavedLoginAutofill(tabURL: URL, currentRequestId: String, field: FocusFieldType) {
        let viewModel = LoginListViewModel(
            tabURL: tabURL,
            field: field,
            loginStorage: profile.logins,
            logger: logger,
            onLoginCellTap: { [weak self] login in
                guard let self else { return }
                let rustLoginsEncryption = RustLoginEncryptionKeys()

                guard let currentTab = self.tabManager.selectedTab,
                      let decryptLogin = rustLoginsEncryption.decryptSecureFields(login: login)
                else {
                    router.dismiss(animated: true)
                    parentCoordinator?.didFinish(from: self)
                    return
                }

                LoginsHelper.fillLoginDetails(
                    with: currentTab,
                    loginData: LoginInjectionData(
                        requestId: currentRequestId,
                        logins: [LoginItem(
                            username: decryptLogin.secFields.username,
                            password: decryptLogin.secFields.password,
                            hostname: decryptLogin.fields.origin
                        )]
                    )
                )

                LoginsHelper.yieldFocusBackToField(with: currentTab)
                router.dismiss(animated: true)
                parentCoordinator?.didFinish(from: self)
            },
            manageLoginInfoAction: { [weak self] in
                guard let self else { return }
                parentCoordinator?.show(settings: .password, onDismiss: {
                    guard let currentTab = self.tabManager.selectedTab else { return }
                    LoginsHelper.yieldFocusBackToField(with: currentTab)
                })
                parentCoordinator?.didFinish(from: self)
            }
        )
        let loginAutofillView = LoginAutofillView(windowUUID: windowUUID, viewModel: viewModel)

        let viewController = SelfSizingHostingController(rootView: loginAutofillView)

        viewController.controllerWillDismiss = { [weak self] in
            guard let currentTab = self?.tabManager.selectedTab else { return }
            LoginsHelper.yieldFocusBackToField(with: currentTab)
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .close,
                object: .loginsAutofillPromptDismissed
            )
        }

        var bottomSheetViewModel = BottomSheetViewModel(
            closeButtonA11yLabel: .CloseButtonTitle,
            closeButtonA11yIdentifier: AccessibilityIdentifiers.Autofill.loginCloseButton
        )
        bottomSheetViewModel.shouldDismissForTapOutside = false

        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetViewModel,
            childViewController: viewController,
            windowUUID: windowUUID
        )
        router.present(bottomSheetVC)
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .loginsAutofillPromptExpanded
        )
    }

    func showPassCodeController() {
        let passwordController = DevicePasscodeRequiredViewController(windowUUID: windowUUID)
        passwordController.profile = profile
        passwordController.parentType = .paymentMethods
        router.present(passwordController)
    }

    // MARK: Telemetry
    fileprivate func sendCreditCardSavePromptShownTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .creditCardSavePromptShown)
    }

    fileprivate func sendCreditCardSavePromptCreateTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .creditCardSavePromptCreate)
    }

    fileprivate func sendCreditCardSavePromptUpdateTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .creditCardSavePromptUpdate)
    }

    fileprivate func sendCreditCardAutofillPromptExpandedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .creditCardAutofillPromptExpanded)
    }
}
