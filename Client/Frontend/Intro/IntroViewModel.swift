// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct IntroViewModel: OnboardingViewModelProtocol, FeatureFlaggable {
    enum InformationCards: Int, CaseIterable {
        case welcome
        case signSync

        case updateWelcome
        case updateSignSync

        var isOnboardingScreen: Bool {
            switch self {
            case .welcome, .signSync:
                return true
            case .updateWelcome, .updateSignSync:
                return false
            }
        }

        var telemetryValue: String {
            switch self {
            case .welcome: return "welcome"
            case .signSync: return "signToSync"
            case .updateWelcome: return "update.welcome"
            case .updateSignSync: return "update.signToSync"
            }
        }

        var position: Int {
            switch self {
            case .welcome: return 0
            case .signSync: return 1
            case .updateWelcome: return 0
            case .updateSignSync: return 1
            }
        }
    }

    var isFeatureEnabled: Bool {
        return featureFlags.isFeatureEnabled(.onboardingFreshInstall, checking: .buildOnly)
    }

    var enabledCards: [IntroViewModel.InformationCards] {
        return [.welcome, .signSync]
    }

    func getInfoModel(cardType: IntroViewModel.InformationCards) -> OnboardingModelProtocol? {
        switch cardType {
        case .welcome:
            return OnboardingInfoModel(image: UIImage(named: ImageIdentifiers.onboardingWelcomev106),
                                       title: .Onboarding.IntroWelcomeTitle,
                                       description: .Onboarding.IntroWelcomeDescription,
                                       primaryAction: .Onboarding.IntroAction,
                                       secondaryAction: nil,
                                       a11yIdRoot: AccessibilityIdentifiers.Onboarding.welcomeCard)
        case .signSync:
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
                                       isFeatureEnabled: isFeatureEnabled)
    }

    func sendCloseButtonTelemetry(index: Int) {
        let extra = [TelemetryWrapper.EventExtraKey.cardType.rawValue: enabledCards[index].telemetryValue]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .onboardingClose,
                                     extras: extra)
    }
}
