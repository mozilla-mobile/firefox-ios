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

    var enabledCards: [OnboardingCards]  = OnboardingCards.allCases

    func getCardViewModel(index: Int) -> OnboardingCardProtocol {
        let currentCard = enabledCards[index]

        switch currentCard {
        case .welcome:
            return OnboardingCardViewModel(cardType: currentCard,
                                           image: UIImage(named: ImageIdentifiers.onboardingWelcome),
                                           title: .CardTitleWelcome,
                                           description: .Onboarding.IntroDescriptionPart2,
                                           primaryAction: .Onboarding.IntroAction,
                                           secondaryAction: nil,
                                           a11yIdRoot: AccessibilityIdentifiers.Onboarding.welcomeCard)
        case .wallpapers:
            return OnboardingCardViewModel(cardType: currentCard,
                                           image: nil,
                                           title: .Onboarding.WallpaperTitle,
                                           description: nil,
                                           primaryAction: .Onboarding.WallpaperAction,
                                           secondaryAction: .Onboarding.LaterAction,
                                           a11yIdRoot: AccessibilityIdentifiers.Onboarding.wallpapersCard)
        case .signSync:
            return OnboardingCardViewModel(cardType: currentCard,
                                           image: UIImage(named: ImageIdentifiers.onboardingSync),
                                           title: .Onboarding.SyncTitle,
                                           description: .Onboarding.SyncDescription,
                                           primaryAction: .Onboarding.SyncAction,
                                           secondaryAction: .WhatsNew.RecentButtonTitle,
                                           a11yIdRoot: AccessibilityIdentifiers.Onboarding.signSyncCard)
        }
    }

    func getNextIndex(currentIndex: Int, goForward: Bool) -> Int? {
        if goForward && currentIndex + 1 < enabledCards.count {
            return currentIndex + 1
        }

        if !goForward && currentIndex > 0 {
            return currentIndex - 1
        }

        return nil
    }
}
