// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct IntroViewModel: OnboardingViewModelProtocol, FeatureFlaggable {
    // MARK: - Properties
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

    var availableCards: [OnboardingCardViewController]
    var isDismissable: Bool
    private var cardModels: [OnboardingCardInfoModelProtocol]

//    var enabledCards: [IntroViewModel.InformationCards] {
//        let notificationCardPosition = OnboardingNotificationCardHelper().cardPosition
//
//        switch notificationCardPosition {
//        case .noCard:
//            return [.welcome, .signSync]
//        case .beforeSync:
//            return [.welcome, .notification, .signSync]
//        case .afterSync:
//            return [.welcome, .signSync, .notification]
//        }
//    }

    // MARK: - Initializer
    init(introScreenManager: IntroScreenManager? = nil) {
        self.introScreenManager = introScreenManager
        let model = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall)
        self.cardModels = model.cards
        self.isDismissable = model.isDismissable
        self.availableCards = []
    }

    // MARK: - Methods
    func setupViewControllerDelegates(with delegate: OnboardingViewControllerProtocol) {
        availableCards.removeAll()
        cardModels.forEach { card in
            availableCards.append(OnboardingCardViewController(
                viewModel: OnboardingCardViewModel(infoModel: card),
                delegate: delegate))
        }
    }

    func sendCloseButtonTelemetry(index: Int) {
        let extra = [TelemetryWrapper.EventExtraKey.cardType.rawValue: availableCards[index].viewModel.infoModel.name]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .onboardingClose,
                                     extras: extra)
    }

    func saveHasSeenOnboarding() {
        introScreenManager?.didSeeIntroScreen()
    }
}
