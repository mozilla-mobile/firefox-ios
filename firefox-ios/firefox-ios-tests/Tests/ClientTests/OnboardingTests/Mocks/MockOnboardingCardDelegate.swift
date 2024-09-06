// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

@testable import Client

class MockOnboardinCardDelegateController: UIViewController,
                                           OnboardingCardDelegate,
                                           OnboardingViewControllerProtocol,
                                           Themeable {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    var currentWindowUUID: UUID? { return windowUUID }

    // Protocol conformance
    var pageController = UIPageViewController()
    var pageControl = UIPageControl()
    var viewModel: OnboardingViewModelProtocol = IntroViewModel(
        profile: MockProfile(),
        model: NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall),
        telemetryUtility: OnboardingTelemetryUtility(
            with: NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall)))
    var didFinishFlow: (() -> Void)?
    var themeManager: ThemeManager = AppContainer.shared.resolve()
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    func applyTheme() { }

    // Protocols under test
    var action: OnboardingActions?
    var multipleChoiceAction: OnboardingMultipleChoiceAction?

    func handleBottomButtonActions(
        for action: Client.OnboardingActions,
        from cardName: String,
        isPrimaryButton: Bool
    ) {
        switch action {
        case .syncSignIn:
            self.action = .syncSignIn
        case .requestNotifications:
            self.action = .requestNotifications
        case .forwardOneCard:
            showNextPage(numberOfCards: 1, from: cardName, completionIfLastCard: {})
        case .forwardTwoCard:
            showNextPage(numberOfCards: 2, from: cardName, completionIfLastCard: {})
        case .forwardThreeCard:
            showNextPage(numberOfCards: 3, from: cardName, completionIfLastCard: {})
        case .setDefaultBrowser:
            self.action = .setDefaultBrowser
        case .openInstructionsPopup:
            presentDefaultBrowserPopup()
        case .readPrivacyPolicy:
            presentPrivacyPolicy(from: cardName,
                                 selector: nil,
                                 completion: {})
        case .openIosFxSettings:
            DefaultApplicationHelper().openSettings()
        case .endOnboarding:
            self.action = .endOnboarding
        }
    }

    func handleMultipleChoiceButtonActions(
        for action: OnboardingMultipleChoiceAction,
        from cardName: String
    ) {
        switch action {
        case .themeDark:
            self.multipleChoiceAction = .themeDark
        case .themeLight:
            self.multipleChoiceAction = .themeLight
        case .themeSystemDefault:
            self.multipleChoiceAction = .themeSystemDefault
        case .toolbarBottom:
            self.multipleChoiceAction = .toolbarBottom
        case .toolbarTop:
            self.multipleChoiceAction = .toolbarTop
        }
    }

    func sendCardViewTelemetry(from cardName: String) { }

    func presentPrivacyPolicy(
        from cardName: String,
        selector: Selector?,
        completion: @escaping () -> Void,
        referringPage: ReferringPage = .onboarding
    ) {
        action = .readPrivacyPolicy
    }

    func presentDefaultBrowserPopup() {
        action = .openInstructionsPopup
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

    func showNextPage(numberOfCards: Int, from cardNamed: String, completionIfLastCard completion: () -> Void) {
        action = .forwardOneCard
        if numberOfCards == 1 {
            action = .forwardOneCard
        } else if numberOfCards == 2 {
            action = .forwardTwoCard
        } else if numberOfCards == 3 {
            action = .forwardThreeCard
        }
    }

    func pageChanged(from cardName: String) { }
}
