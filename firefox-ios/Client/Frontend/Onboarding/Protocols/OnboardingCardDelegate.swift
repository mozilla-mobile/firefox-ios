// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import OnboardingKit
import Foundation

/// The ``OnboardingCardDelegate`` is responsible for handling a variety of
/// functions relating to onboarding actions taken by the user that are
/// shared by both ``IntroViewController`` and ``UpdateViewController``.
///
/// The function has default implementations for all these actions, with the
/// exception of ``OnboardingCardDelegate/handleButtonPress(for:from:)``. This
/// function is implemented uniquely in its respective view controller, to account
/// for the difference in flows that the two onboarding paths represent.
protocol OnboardingCardDelegate: AnyObject {
    // These methods must be implemented by the object
    @MainActor
    func handleBottomButtonActions(for action: OnboardingActions,
                                   from cardName: String,
                                   isPrimaryButton: Bool)
    @MainActor
    func handleMultipleChoiceButtonActions(for action: OnboardingMultipleChoiceAction,
                                           from cardName: String)
    @MainActor
    func sendCardViewTelemetry(from cardName: String)

    // Implemented by default for code sharing
    @MainActor
    func presentPrivacyPolicy(windowUUID: WindowUUID,
                              from cardName: String,
                              selector: Selector?,
                              completion: (() -> Void)?,
                              referringPage: ReferringPage)
    @MainActor
    func presentDefaultBrowserPopup(windowUUID: WindowUUID,
                                    from name: String,
                                    completionIfLastCard: (() -> Void)?)

    @MainActor
    func presentSignToSync(
        windowUUID: WindowUUID,
        with fxaOptions: FxALaunchParams,
        selector: Selector?,
        completion: @escaping () -> Void,
        flowType: FxAPageType,
        referringPage: ReferringPage,
        qrCodeNavigationHandler: QRCodeNavigationHandler?
    )

    @MainActor
    func advance(
        numberOfPages: Int,
        from cardName: String,
        completionIfLastCard completion: (() -> Void)?
    )
    @MainActor
    func pageChanged(from cardName: String)
}

extension OnboardingCardDelegate where Self: OnboardingViewControllerProtocol,
                                       Self: UIViewController,
                                       Self: Themeable {
    // MARK: - Privacy Policy
    @MainActor
    func presentPrivacyPolicy(
        windowUUID: WindowUUID,
        from cardName: String,
        selector: Selector?,
        completion: (() -> Void)? = nil,
        referringPage: ReferringPage = .onboarding
    ) {
        guard let infoModel = viewModel.availableCards
            .first(where: { $0.viewModel.name == cardName })?
            .viewModel,
              let url = infoModel.link?.url
        else { return }

        let privacyPolicyVC = PrivacyPolicyViewController(url: url, windowUUID: windowUUID)
        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: selector)

        privacyPolicyVC.navigationItem.rightBarButtonItem = buttonItem
        let controller = DismissableNavigationViewController(rootViewController: privacyPolicyVC)
        controller.onViewDismissed = completion

        present(controller, animated: true)
    }

    // MARK: - Default Browser Popup
    @MainActor
    func presentDefaultBrowserPopup(
        windowUUID: WindowUUID,
        from name: String,
        completionIfLastCard: (() -> Void)?
    ) {
        guard let popupViewModel = viewModel
            .availableCards
            .first(where: { $0.viewModel.name == name })?
            .viewModel
            .instructionsPopup
        else { return }

        let instructionsVC = OnboardingInstructionPopupViewController(
            viewModel: popupViewModel,
            windowUUID: windowUUID,
            buttonTappedFinishFlow: { [weak self] in
                self?.viewModel.telemetryUtility.sendGoToSettingsButtonTappedTelemetry()
                self?.advance(
                    numberOfPages: 1,
                    from: name,
                    completionIfLastCard: completionIfLastCard
                )
            }
        )

        let bottomSheetVC = OnboardingBottomSheetViewController(windowUUID: windowUUID)
        bottomSheetVC.onDismiss = { [weak self] in
            self?.viewModel.telemetryUtility.sendDismissButtonTappedTelemetry()
        }
        bottomSheetVC.configure(
            closeButtonModel: CloseButtonViewModel(
                a11yLabel: .CloseButtonTitle,
                a11yIdentifier: AccessibilityIdentifiers.Onboarding.bottomSheetCloseButton
            ),
            child: instructionsVC
        )
        present(bottomSheetVC, animated: true)
    }

    // MARK: - Sync sign in
    @MainActor
    func presentSignToSync(
        windowUUID: WindowUUID,
        with fxaOptions: FxALaunchParams,
        selector: Selector?,
        completion: @escaping () -> Void,
        flowType: FxAPageType = .emailLoginFlow,
        referringPage: ReferringPage = .onboarding,
        qrCodeNavigationHandler: QRCodeNavigationHandler?
    ) {
        let singInSyncVC = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(
            fxaOptions,
            flowType: flowType,
            referringPage: referringPage,
            profile: viewModel.profile,
            windowUUID: windowUUID)
        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: selector)
        if #available(iOS 26.0, *) {
            buttonItem.tintColor = themeManager.getCurrentTheme(for: windowUUID).colors.textPrimary
        }
        singInSyncVC.navigationItem.rightBarButtonItem = buttonItem
        (singInSyncVC as? FirefoxAccountSignInViewController)?.qrCodeNavigationHandler = qrCodeNavigationHandler

        let controller = DismissableNavigationViewController(rootViewController: singInSyncVC)
        controller.onViewDismissed = completion

        self.present(controller, animated: true)
    }

    // MARK: - Page helpers
    @MainActor
    func advance(
        numberOfPages: Int,
        from cardName: String,
        completionIfLastCard completion: (() -> Void)?
    ) {
        guard cardName != viewModel.availableCards.last?.viewModel.name else {
            completion?()
            return
        }

        moveForward(numberOfPages: numberOfPages, from: cardName)
    }

    // Extra step to make sure pageControl.currentPage is the right index card
    // because UIPageViewControllerDataSource call fails
    @MainActor
    func pageChanged(from cardName: String) {
        guard let cardIndex = viewModel.availableCards
            .firstIndex(where: { $0.viewModel.name == cardName }),
              cardIndex != pageControl.currentPage
        else { return }

        pageControl.currentPage = cardIndex
    }
}
