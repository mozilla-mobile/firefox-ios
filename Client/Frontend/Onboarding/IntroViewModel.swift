// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct IntroViewModel: OnboardingViewModelProtocol, FeatureFlaggable {
    enum InformationCards: Int, CaseIterable {
        case welcome
        case signSync
        case notification

        case updateWelcome
        case updateSignSync

        var isOnboardingScreen: Bool {
            switch self {
            case .welcome, .signSync, .notification:
                return true
            case .updateWelcome, .updateSignSync:
                return false
            }
        }

        var telemetryValue: String {
            switch self {
            case .welcome: return "welcome"
            case .signSync: return "signToSync"
            case .notification: return "notificationPermission"
            case .updateWelcome: return "update.welcome"
            case .updateSignSync: return "update.signToSync"
            }
        }

        var position: Int {
            switch self {
            case .welcome: return 0
            case .signSync: return 1
            case .notification: return 2
            case .updateWelcome: return 0
            case .updateSignSync: return 1
            }
        }
    }

    // FXIOS-6036 - Make this non optional when coordinators are used
    var introScreenManager: IntroScreenManager?

    var isFeatureEnabled: Bool {
        return featureFlags.isFeatureEnabled(.onboardingFreshInstall, checking: .buildOnly)
    }

    var enabledCards: [IntroViewModel.InformationCards] {
        let notificationCardPosition = OnboardingNotificationCardHelper().cardPosition

        switch notificationCardPosition {
        case .noCard:
            return [.welcome, .signSync]
        case .beforeSync:
            return [.welcome, .notification, .signSync]
        case .afterSync:
            return [.welcome, .signSync, .notification]
        }
    }

    func getInfoModel(cardType: IntroViewModel.InformationCards) -> OnboardingModelProtocol? {
        switch cardType {
        case .welcome:
            return OnboardingInfoModel(image: UIImage(named: ImageIdentifiers.onboardingWelcomev106),
                                       title: .Onboarding.IntroWelcomeTitle,
                                       description: .Onboarding.IntroWelcomeDescription,
                                       linkButtonTitle: .Onboarding.IntroLinkButtonTitle,
                                       primaryAction: .Onboarding.IntroAction,
                                       secondaryAction: .Onboarding.IntroSecondaryAction,
                                       a11yIdRoot: AccessibilityIdentifiers.Onboarding.welcomeCard)
        case .signSync:
            return OnboardingInfoModel(image: UIImage(named: ImageIdentifiers.onboardingSyncv106),
                                       title: .Onboarding.IntroSyncTitle,
                                       description: .Onboarding.IntroSyncDescription,
                                       linkButtonTitle: nil,
                                       primaryAction: .IntroSignInButtonTitle,
                                       secondaryAction: .Onboarding.IntroSyncSkipAction,
                                       a11yIdRoot: AccessibilityIdentifiers.Onboarding.signSyncCard)
        case .notification:
            let shortName = AppName.shortName.rawValue
            return OnboardingInfoModel(image: UIImage(named: ImageIdentifiers.onboardingNotification),
                                       title: String(format: .Onboarding.IntroNotificationTitle, shortName),
                                       description: String(format: .Onboarding.IntroNotificationDescription, shortName),
                                       linkButtonTitle: nil,
                                       primaryAction: .Onboarding.IntroNotificationContinueAction,
                                       secondaryAction: .Onboarding.IntroNotificationSkipAction,
                                       a11yIdRoot: AccessibilityIdentifiers.Onboarding.notificationCard)
        default:
            return nil
        }
    }

    func getCardViewModel(cardType: InformationCards) -> OnboardingCardProtocol? {
        guard let infoModel = getInfoModel(cardType: cardType) else { return nil }

        return OnboardingCardViewModel(cardType: cardType,
                                       infoModel: infoModel,
                                       isFeatureEnabled: isFeatureEnabled)
    }

    func sendCloseButtonTelemetry(index: Int) {
        let extra = [TelemetryWrapper.EventExtraKey.cardType.rawValue: enabledCards[index].telemetryValue]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .onboardingClose,
                                     extras: extra)
    }

    func saveHasSeenOnboarding() {
        introScreenManager?.didSeeIntroScreen()
    }
}
