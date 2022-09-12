// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct IntroViewModel: OnboardingViewModelProtocol, FeatureFlaggable {
    enum InformationCards: Int, CaseIterable {
        case welcome
        case wallpapers
        case signSync

        case updateWelcome
        case updateSignSync

        var isOnboardingScreen: Bool {
            switch self {
            case .welcome, .wallpapers, .signSync:
                return true
            case .updateWelcome, .updateSignSync:
                return false
            }
        }

        var telemetryValue: String {
            switch self {
            case .welcome: return "welcome"
            case .wallpapers: return "wallpaper"
            case .signSync: return "signToSync"
            case .updateWelcome: return "update.welcome"
            case .updateSignSync: return "update.signToSync"
            }
        }

        var position: Int {
            switch self {
            case .welcome: return 0
            case .wallpapers: return 1
            case .signSync: return 2
            case .updateWelcome: return 0
            case .updateSignSync: return 1
            }
        }
    }

    var isv106Version: Bool {
        return featureFlags.isFeatureEnabled(.onboardingFreshInstall, checking: .buildOnly)
    }

    var enabledCards: [IntroViewModel.InformationCards] {
        return [.welcome, .signSync]
    }

    func getInfoModel(cardType: IntroViewModel.InformationCards) -> OnboardingModelProtocol? {
        switch (cardType, isv106Version) {
        case (.welcome, false):
            return OnboardingInfoModel(image: UIImage(named: ImageIdentifiers.onboardingWelcome),
                                       title: .CardTitleWelcome,
                                       description: .Onboarding.IntroDescriptionPart2,
                                       primaryAction: .Onboarding.IntroAction,
                                       secondaryAction: nil,
                                       a11yIdRoot: AccessibilityIdentifiers.Onboarding.welcomeCard)
        case (.welcome, true):
            return OnboardingInfoModel(image: UIImage(named: ImageIdentifiers.onboardingWelcomev106),
                                       title: .Onboarding.IntroWelcomeTitle,
                                       description: .Onboarding.IntroWelcomeDescription,
                                       primaryAction: .Onboarding.IntroAction,
                                       secondaryAction: nil,
                                       a11yIdRoot: AccessibilityIdentifiers.Onboarding.welcomeCard)
        case (.wallpapers, _):
            return OnboardingInfoModel(image: nil,
                                       title: .Onboarding.WallpaperTitle,
                                       description: nil,
                                       primaryAction: .Onboarding.WallpaperAction,
                                       secondaryAction: .Onboarding.LaterAction,
                                       a11yIdRoot: AccessibilityIdentifiers.Onboarding.wallpapersCard)
        case (.signSync, false):
            return OnboardingInfoModel(image: UIImage(named: ImageIdentifiers.onboardingSync),
                                       title: .Onboarding.SyncTitle,
                                       description: .Onboarding.SyncDescription,
                                       primaryAction: .Onboarding.SyncAction,
                                       secondaryAction: .WhatsNew.RecentButtonTitle,
                                       a11yIdRoot: AccessibilityIdentifiers.Onboarding.signSyncCard)
        case (.signSync, true):
            return OnboardingInfoModel(image: UIImage(named: ImageIdentifiers.onboardingSyncv106),
                                       title: .Onboarding.IntroSyncTitle,
                                       description: .Onboarding.IntroSyncDescription,
                                       primaryAction: .IntroSignInButtonTitle,
                                       secondaryAction: .Onboarding.IntroSyncSkipAction,
                                       a11yIdRoot: AccessibilityIdentifiers.Onboarding.signSyncCard)
        default:
            return nil
        }
    }

    func getCardViewModel(cardType: InformationCards) -> OnboardingCardProtocol? {
        guard let infoModel = getInfoModel(cardType: cardType) else { return nil }

        return OnboardingCardViewModel(cardType: cardType,
                                       infoModel: infoModel,
                                       isv106Version: isv106Version)
    }

    func sendCloseButtonTelemetry(index: Int) {
        let extra = [TelemetryWrapper.EventExtraKey.cardType.rawValue: enabledCards[index].telemetryValue]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .onboardingClose,
                                     extras: extra)
    }
}
