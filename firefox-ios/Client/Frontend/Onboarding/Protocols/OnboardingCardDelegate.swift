// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import Shared

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
    func handleBottomButtonActions(for action: OnboardingActions,
                                   from cardName: String,
                                   isPrimaryButton: Bool)
    func handleMultipleChoiceButtonActions(for action: OnboardingMultipleChoiceAction,
                                           from cardName: String)
    func sendCardViewTelemetry(from cardName: String)

    // Implemented by default for code sharing
    func presentPrivacyPolicy(windowUUID: WindowUUID,
                              from cardName: String,
                              selector: Selector?,
                              completion: (() -> Void)?,
                              referringPage: ReferringPage)
    func presentDefaultBrowserPopup(windowUUID: WindowUUID,
                                    from name: String,
                                    completionIfLastCard: (() -> Void)?)

    func presentSignToSync(
        windowUUID: WindowUUID,
        with fxaOptions: FxALaunchParams,
        selector: Selector?,
        completion: @escaping () -> Void,
        flowType: FxAPageType,
        referringPage: ReferringPage,
        qrCodeNavigationHandler: QRCodeNavigationHandler?
    )

    func advance(
        numberOfPages: Int,
        from cardName: String,
        completionIfLastCard completion: (() -> Void)?
    )
    func pageChanged(from cardName: String)
}

extension OnboardingCardDelegate where Self: OnboardingViewControllerProtocol,
                                       Self: UIViewController,
                                       Self: Themeable {
    // MARK: - Privacy Policy
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
            buttonTappedFinishFlow: {
                self.advance(
                    numberOfPages: 1,
                    from: name,
                    completionIfLastCard: completionIfLastCard
                )
            }
        )
        var bottomSheetViewModel = BottomSheetViewModel(
            closeButtonA11yLabel: .CloseButtonTitle,
            closeButtonA11yIdentifier:
                AccessibilityIdentifiers.Onboarding.bottomSheetCloseButton
        )
        bottomSheetViewModel.shouldDismissForTapOutside = true
        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetViewModel,
            childViewController: instructionsVC,
            usingDimmedBackground: true,
            windowUUID: windowUUID)

        instructionsVC.dismissDelegate = bottomSheetVC

        self.present(bottomSheetVC, animated: false, completion: nil)
    }

    // MARK: - Sync sign in
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
        buttonItem.tintColor = themeManager.getCurrentTheme(for: windowUUID).colors.actionPrimary
        singInSyncVC.navigationItem.rightBarButtonItem = buttonItem
        (singInSyncVC as? FirefoxAccountSignInViewController)?.qrCodeNavigationHandler = qrCodeNavigationHandler

        let controller = DismissableNavigationViewController(rootViewController: singInSyncVC)
        controller.onViewDismissed = completion

        self.present(controller, animated: true)
    }

    // MARK: - Page helpers
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
    func pageChanged(from cardName: String) {
        guard let cardIndex = viewModel.availableCards
            .firstIndex(where: { $0.viewModel.name == cardName }),
              cardIndex != pageControl.currentPage
        else { return }

        pageControl.currentPage = cardIndex
    }
}
