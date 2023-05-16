// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingCardDelegate: AnyObject {
    func handleButtonPress(for action: OnboardingActions, from cardNamed: String)

    func showPrivacyPolicy(from cardNamed: String,
                           selector: Selector,
                           withCompletion completion: @escaping () -> Void)
    func presentPrivacyPolicy(url: URL,
                              selector: Selector,
                              completion: @escaping () -> Void,
                              referringPage: ReferringPage)

    func showNextPage(from cardNamed: String,
                      completionIfLastCard completion: () -> Void)
    func pageChanged(from cardNamed: String)
}

extension OnboardingCardDelegate where Self: OnboardingViewControllerProtocol,
                                       Self: UIViewController {
    // MARK: - Privacy Policy
    func showPrivacyPolicy(
        from cardNamed: String,
        selector: Selector,
        withCompletion completion: @escaping () -> Void
    ) {
        guard let infoModel = viewModel.availableCards
            .first(where: { $0.viewModel.infoModel.name == cardNamed})?
            .viewModel.infoModel,
              let url = infoModel.link?.url
        else { return }

        presentPrivacyPolicy(url: url, selector: selector, completion: completion)
    }

    func presentPrivacyPolicy(
        url: URL,
        selector: Selector,
        completion: @escaping () -> Void,
        referringPage: ReferringPage = .onboarding
    ) {
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
