// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct IntroViewModel {
    enum OnboardingCards: Int, CaseIterable {
        case welcome
        case wallpapers
        case signSync
    }

    var shouldShowNewOnboarding: Bool {
        return true
    }

    var enabledCards: [OnboardingCards] {
        return OnboardingCards.allCases
    }

    private(set) var currentCard: OnboardingCards

    func getCardViewModel() -> OnboardingCardProtocol {
        switch currentCard {
        case .welcome:
            return OnboardingCardViewModel(cardType: currentCard,
                                          image: UIImage(named: "tour-Welcome"),
                                          title: "Welcome title",
                                          description: "Welcome description",
                                          primaryAction: "Primary",
                                          secondaryAction: nil,
                                          a11yIdRoot: "Welcome")
        case .wallpapers:
            return OnboardingCardViewModel(cardType: currentCard,
                                          image: UIImage(named: "tour-Welcome"),
                                          title: "Wallpapers title",
                                          description: "Wallpapers description",
                                          primaryAction: "Primary",
                                          secondaryAction: "Next",
                                          a11yIdRoot: "Wallpaper")
        case .signSync:
            return OnboardingCardViewModel(cardType: currentCard,
                                          image: UIImage(named: "tour-Welcome"),
                                          title: "Sign title",
                                          description: "Sign description",
                                          primaryAction: "Primary",
                                          secondaryAction: "Start browsing",
                                          a11yIdRoot: "SignIn")
        }
    }

    mutating func showNextCard() {
        currentCard = IntroViewModel.OnboardingCards(rawValue: currentCard.rawValue + 1)!
    }
}
