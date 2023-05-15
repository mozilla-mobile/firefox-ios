// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockIntroViewController: OnboardingCardDelegate {
    var action: OnboardingActions?

    func handleButtonPress(
        for action: OnboardingActions,
        from cardType: IntroViewModel.InformationCards
    ) {
        switch action {
        case .syncSignIn:
            self.action = .syncSignIn
        case .requestNotifications:
            self.action = .requestNotifications
        case .nextCard:
            showNextPage(cardType)
        case .setDefaultBrowser:
            self.action = .setDefaultBrowser
        case .readPrivacyPolicy:
            showPrivacyPolicy(.welcome)
        }
    }

    func showPrivacyPolicy(_ cardType: IntroViewModel.InformationCards) {
        action = .readPrivacyPolicy
    }

    func showNextPage(_ cardType: IntroViewModel.InformationCards) {
        action = .nextCard
    }

    func pageChanged(_ cardType: IntroViewModel.InformationCards) { }
}
