// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct IntroViewModel: InformationContainerModel {
    enum InformationCards: Int, CaseIterable {
        case welcome
        case wallpapers
        case signSync

        case updateWelcome
        case updateSignSync

        var telemetryValue: String {
            switch self {
            case .welcome: return "welcome"
            case .wallpapers: return "wallpaper"
            case .signSync: return "signToSync"
            case .updateWelcome: return "update.welcome"
            case .updateSignSync: return "update.signToSync"
            }
        }
    }

    var enabledCards: [InformationCards] {
        return [.welcome, .wallpapers, .signSync]
    }

    func getCardViewModel(index: Int) -> OnboardingCardProtocol? {
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
        default:
            return nil
        }
    }

    func sendCloseButtonTelemetry(index: Int) {
        let extra = [TelemetryWrapper.EventExtraKey.cardType.rawValue: enabledCards[index].telemetryValue]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .onboardingClose,
                                     extras: extra)
    }
}
