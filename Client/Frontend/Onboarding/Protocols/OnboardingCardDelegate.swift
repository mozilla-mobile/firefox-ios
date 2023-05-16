// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol OnboardingCardDelegate: AnyObject {
    func handleButtonPress(for action: OnboardingActions,
                           from cardName: String)

    func presentPrivacyPolicy(from cardName: String,
                              selector: Selector?,
                              completion: (() -> Void)?,
                              referringPage: ReferringPage)
    func presentDefaultBrowserPopup()

    func presentSignToSync(
        with fxaOptions: FxALaunchParams,
        selector: Selector?,
        completion: @escaping () -> Void,
        flowType: FxAPageType,
        referringPage: ReferringPage)

    func showNextPage(from cardNamed: String, completionIfLastCard completion: () -> Void)
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
            .first(where: { $0.viewModel.infoModel.name == cardName})?
            .viewModel.infoModel,
              let url = infoModel.link?.url
        else { return }

        let privacyPolicyVC = PrivacyPolicyViewController(url: url)
        let controller: DismissableNavigationViewController
        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: selector)

        privacyPolicyVC.navigationItem.rightBarButtonItem = buttonItem
        controller = DismissableNavigationViewController(rootViewController: privacyPolicyVC)

        controller.onViewDismissed = completion

        present(controller, animated: true)
    }

    // MARK: - Default Browser Popup
    // TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-6359
    func presentDefaultBrowserPopup() {
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
        let controller: DismissableNavigationViewController
        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: selector)
        buttonItem.tintColor = themeManager.currentTheme.colors.actionPrimary
        singInSyncVC.navigationItem.rightBarButtonItem = buttonItem
        controller = DismissableNavigationViewController(rootViewController: singInSyncVC)

        controller.onViewDismissed = completion

        self.present(controller, animated: true)
    }

    // MARK: - Page helpers
    func showNextPage(
        from cardName: String,
        completionIfLastCard completion: () -> Void
    ) {
        guard cardName != viewModel.availableCards.last?.viewModel.infoModel.name else {
            completion()
            return
        }

        moveToNextPage(from: cardName)
    }

    // Extra step to make sure pageControl.currentPage is the right index card
    // because UIPageViewControllerDataSource call fails
    func pageChanged(from cardName: String) {
        if let cardIndex = viewModel.availableCards
            .firstIndex(where: { $0.viewModel.infoModel.name == cardName }),
           cardIndex != pageControl.currentPage {
            pageControl.currentPage = cardIndex
        }
    }
}
