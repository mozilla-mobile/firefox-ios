// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Storage
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
                                viewController: UIViewController,
                                alertContainer: UIView) {
        let creditCardControllerViewModel = CreditCardBottomSheetViewModel(creditCardProvider: profile.autofill,
                                                                           creditCard: creditCard,
                                                                           decryptedCreditCard: decryptedCard,
                                                                           state: state)
        let bottomSheetViewController = CreditCardBottomSheetViewController(viewModel: creditCardControllerViewModel,
                                                                            windowUUID: windowUUID)
        bottomSheetViewController.didTapYesClosure = { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                logger.log("Error fetching credit cards",
                           level: .warning,
                           category: .autofill,
                           description: "Error fetching credit card: \(error.localizedDescription)")
            } else {
                // send telemetry
                if state == .save {
                    sendCreditCardSavePromptCreateTelemetry()
                    showToast(with: .CreditCard.RememberCreditCard.CreditCardSaveSuccessToastMessage,
                              viewController: viewController,
                              alertContainer: alertContainer)
                } else if state == .update {
                    sendCreditCardSavePromptUpdateTelemetry()
                    showToast(with: .CreditCard.UpdateCreditCard.CreditCardUpdateSuccessToastMessage,
                              viewController: viewController,
                              alertContainer: alertContainer)
                }

                self.parentCoordinator?.didFinish(from: self)
            }
        }

        bottomSheetViewController.didTapManageCardsClosure = { [weak self] in
            guard let self = self else { return }
            self.parentCoordinator?.show(settings: .creditCard)
            self.parentCoordinator?.didFinish(from: self)
        }

        bottomSheetViewController.didSelectCreditCardToFill = { [weak self] plainTextCard in
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

        let bottomSheetViewModel = BottomSheetViewModel(
            shouldDismissForTapOutside: false,
            closeButtonA11yLabel: .CloseButtonTitle,
            closeButtonA11yIdentifier: AccessibilityIdentifiers.Autofill.creditCardCloseButton
        )

        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetViewModel,
            childViewController: bottomSheetViewController,
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
                guard let currentTab = self.tabManager.selectedTab else {
                    router.dismiss(animated: true)
                    parentCoordinator?.didFinish(from: self)
                    return
                }

                LoginsHelper.fillLoginDetails(
                    with: currentTab,
                    loginData: LoginInjectionData(
                        requestId: currentRequestId,
                        logins: [LoginItem(
                            username: login.username,
                            password: login.password,
                            hostname: login.origin
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

        let bottomSheetViewModel = BottomSheetViewModel(
            shouldDismissForTapOutside: false,
            closeButtonA11yLabel: .CloseButtonTitle,
            closeButtonA11yIdentifier: AccessibilityIdentifiers.Autofill.loginCloseButton
        )

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
    private func sendCreditCardSavePromptShownTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .creditCardSavePromptShown)
    }

    private func sendCreditCardSavePromptCreateTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .creditCardSavePromptCreate)
    }

    private func sendCreditCardSavePromptUpdateTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .creditCardSavePromptUpdate)
    }

    private func sendCreditCardAutofillPromptExpandedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .creditCardAutofillPromptExpanded)
    }

    private func showToast(with message: String,
                           viewController: UIViewController,
                           alertContainer: UIView) {
        let viewModel = PlainToastViewModel(labelText: message)
        let toast = PlainToast(viewModel: viewModel, theme: currentTheme())
        toast.showToast(viewController: viewController,
                        delay: Toast.UX.toastDelayBefore,
                        duration: Toast.UX.toastDismissAfter) { toast in
            [
                toast.leadingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.leadingAnchor,
                                               constant: Toast.UX.toastSidePadding),
                toast.trailingAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.trailingAnchor,
                                                constant: -Toast.UX.toastSidePadding),
                toast.bottomAnchor.constraint(equalTo: alertContainer.bottomAnchor)
            ]
        }
    }
}
