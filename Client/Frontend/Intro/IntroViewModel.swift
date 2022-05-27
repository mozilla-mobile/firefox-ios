// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

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

    func getCardViewModel(index: Int) -> OnboardingCardProtocol {
        let currentCard = enabledCards[index]

        switch currentCard {
        case .welcome:
            return OnboardingCardViewModel(cardType: currentCard,
                                           image: UIImage(named: "tour-Welcome"),
                                           title: .CardTitleWelcome,
                                           description: .Onboarding.IntroDescriptionPart2,
                                           primaryAction: .Onboarding.IntroAction,
                                          secondaryAction: nil,
                                          a11yIdRoot: "Welcome")
        case .wallpapers:
            return OnboardingCardViewModel(cardType: currentCard,
                                           image: nil,
                                           title: .Onboarding.WallpaperTitle,
                                           description: nil,
                                           primaryAction: .Onboarding.WallpaperAction,
                                           secondaryAction: .Onboarding.LaterAction,
                                           a11yIdRoot: "Wallpaper")
        case .signSync:
            return OnboardingCardViewModel(cardType: currentCard,
                                           image: UIImage(named: "tour-Welcome"),
                                           title: .Onboarding.SyncTitle,
                                           description: .Onboarding.SyncDescription,
                                           primaryAction: .Onboarding.SyncAction,
                                           secondaryAction: .WhatsNew.RecentButtonTitle,
                                           a11yIdRoot: "Sync")
        }
    }
}
