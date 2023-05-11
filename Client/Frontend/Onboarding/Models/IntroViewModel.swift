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

    func getInfoModel(cardType: IntroViewModel.InformationCards) -> OnboardingCardInfoModelProtocol? {
        let shortName = AppName.shortName.rawValue

        switch cardType {
        case .welcome:
            return OnboardingCardInfoModel(
                name: "welcome",
                title: String(format: .Onboarding.Welcome.Title),
                body: String(format: .Onboarding.Welcome.Description, shortName),
                link: OnboardingLinkInfoModel(
                    title: .Onboarding.PrivacyPolicyLinkButtonTitle,
                    url: URL(string: "https://macrumors.com")!),
                buttons: OnboardingButtons(
                    primary: OnboardingButtonInfoModel(
                        title: .Onboarding.Welcome.GetStartedAction,
                        action: .nextCard)),
                type: .freshInstall,
                a11yIdRoot: AccessibilityIdentifiers.Onboarding.welcomeCard,
                imageID: ImageIdentifiers.onboardingWelcomev106)
        case .signSync:
            return OnboardingCardInfoModel(
                name: "signSync",
                title: String(format: .Onboarding.Sync.Title),
                body: String(format: .Onboarding.Sync.Description),
                link: nil,
                buttons: OnboardingButtons(
                    primary: OnboardingButtonInfoModel(
                        title: .Onboarding.Sync.SignInAction,
                        action: .syncSignIn),
                    secondary: OnboardingButtonInfoModel(
                        title: .Onboarding.Sync.SkipAction,
                        action: .nextCard)),
                type: .freshInstall,
                a11yIdRoot: AccessibilityIdentifiers.Onboarding.signSyncCard,
                imageID: ImageIdentifiers.onboardingSyncv106)
        case .notification:
            return OnboardingCardInfoModel(
                name: "notification",
                title: String(format: .Onboarding.Notification.Title, shortName),
                body: String(format: .Onboarding.Notification.Description, shortName),
                link: nil,
                buttons: OnboardingButtons(
                    primary: OnboardingButtonInfoModel(
                        title: .Onboarding.Notification.ContinueAction,
                        action: .requestNotifications),
                    secondary: OnboardingButtonInfoModel(
                        title: .Onboarding.Notification.SkipAction,
                        action: .nextCard)),
                type: .freshInstall,
                a11yIdRoot: AccessibilityIdentifiers.Onboarding.notificationCard,
                imageID: ImageIdentifiers.onboardingSyncv106)
        default:
            return nil
        }
    }

    func getCardViewModel(cardType: InformationCards) -> OnboardingCardProtocol? {
        guard let infoModel = getInfoModel(cardType: cardType) else { return nil }

        return LegacyOnboardingCardViewModel(cardType: cardType,
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
