// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

@testable import Client

class MockOnboardinCardDelegateController: UIViewController, OnboardingCardDelegate, OnboardingViewControllerProtocol, Themeable {
    // Protocol conformance
    var pageController = UIPageViewController()
    var pageControl = UIPageControl()
    var viewModel: OnboardingViewModelProtocol = IntroViewModel(
        profile: MockProfile(),
        model: NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall))
    var didFinishFlow: (() -> Void)?
    var themeManager: ThemeManager = AppContainer.shared.resolve()
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    func applyTheme() { }

    // Protocols under test
    var action: OnboardingActions?

    func handleButtonPress(
        for action: Client.OnboardingActions,
        from cardName: String
    ) {
        switch action {
        case .syncSignIn:
            self.action = .syncSignIn
        case .requestNotifications:
            self.action = .requestNotifications
        case .nextCard:
            showNextPage(from: cardName, completionIfLastCard: {})
        case .setDefaultBrowser:
            self.action = .setDefaultBrowser
        case .openDefaultBrowserPopup:
            presentDefaultBrowserPopup()
        case .readPrivacyPolicy:
            presentPrivacyPolicy(from: cardName,
                                 selector: nil,
                                 completion: {})
        }
    }

    func presentPrivacyPolicy(
        from cardName: String,
        selector: Selector?,
        completion: @escaping () -> Void,
        referringPage: ReferringPage = .onboarding
    ) {
        action = .readPrivacyPolicy
    }

    func presentDefaultBrowserPopup() {
        action = .openDefaultBrowserPopup
    }

    func presentSignToSync(
        with fxaOptions: Client.FxALaunchParams,
        selector: Selector?,
        completion: @escaping () -> Void,
        flowType: Client.FxAPageType,
        referringPage: Client.ReferringPage
    ) {
        action = .syncSignIn
    }

    func showNextPage(from cardNamed: String, completionIfLastCard completion: () -> Void) {
        action = .nextCard
    }

    func pageChanged(from cardName: String) { }
}
