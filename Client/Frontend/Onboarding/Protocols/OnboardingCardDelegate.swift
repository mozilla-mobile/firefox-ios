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
    func handleButtonPress(for action: OnboardingActions,
                           from cardName: String,
                           isPrimaryButton: Bool)
    func sendCardViewTelemetry(from cardName: String)

    // Implemented by default for code sharing
    func presentPrivacyPolicy(from cardName: String,
                              selector: Selector?,
                              completion: (() -> Void)?,
                              referringPage: ReferringPage)
    func presentDefaultBrowserPopup(from name: String,
                                    completionIfLastCard: (() -> Void)?)

    func presentSignToSync(
        with fxaOptions: FxALaunchParams,
        selector: Selector?,
        completion: @escaping () -> Void,
        flowType: FxAPageType,
        referringPage: ReferringPage)

    func showNextPage(from cardNamed: String, completionIfLastCard completion: (() -> Void)?)
    func pageChanged(from cardName: String)
}

extension OnboardingCardDelegate where Self: OnboardingViewControllerProtocol,
                                       Self: UIViewController,
                                       Self: Themeable {
    // MARK: - Privacy Policy
    func presentPrivacyPolicy(
        from cardName: String,
        selector: Selector?,
        completion: (() -> Void)? = nil,
        referringPage: ReferringPage = .onboarding
    ) {
        guard let infoModel = viewModel.availableCards
            .first(where: { $0.viewModel.name == cardName})?
            .viewModel,
              let url = infoModel.link?.url
        else { return }

        let privacyPolicyVC = PrivacyPolicyViewController(url: url)
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
            buttonTappedFinishFlow: {
                self.showNextPage(
                    from: name,
                    completionIfLastCard: completionIfLastCard)
            }
        )
        var bottomSheetViewModel = BottomSheetViewModel(closeButtonA11yLabel: .CloseButtonTitle)
        bottomSheetViewModel.shouldDismissForTapOutside = true
        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetViewModel,
            childViewController: instructionsVC,
            usingDimmedBackground: true)

        instructionsVC.dismissDelegate = bottomSheetVC

        self.present(bottomSheetVC, animated: false, completion: nil)
    }

    // MARK: - Sync sign in
    func presentSignToSync(
        with fxaOptions: FxALaunchParams,
        selector: Selector?,
        completion: @escaping () -> Void,
        flowType: FxAPageType = .emailLoginFlow,
        referringPage: ReferringPage = .onboarding
    ) {
        let singInSyncVC = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(
            fxaOptions,
            flowType: flowType,
            referringPage: referringPage,
            profile: viewModel.profile)
        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: selector)
        buttonItem.tintColor = themeManager.currentTheme.colors.actionPrimary
        singInSyncVC.navigationItem.rightBarButtonItem = buttonItem

        let controller = DismissableNavigationViewController(rootViewController: singInSyncVC)
        controller.onViewDismissed = completion

        self.present(controller, animated: true)
    }

    // MARK: - Page helpers
    func showNextPage(
        from cardName: String,
        completionIfLastCard completion: (() -> Void)?
    ) {
        guard cardName != viewModel.availableCards.last?.viewModel.name else {
            completion?()
            return
        }

        moveToNextPage(from: cardName)
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
