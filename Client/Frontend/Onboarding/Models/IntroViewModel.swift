// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class IntroViewModel: OnboardingViewModelProtocol, FeatureFlaggable {
    // MARK: - Properties
    enum InformationCards: Int, CaseIterable {
        case welcome
        case signSync
        case notification

        case updateWelcome
        case updateSignSync

        var telemetryValue: String {
            switch self {
            case .welcome: return "welcome"
            case .signSync: return "signToSync"
            case .notification: return "notificationPermission"
            case .updateWelcome: return "update.welcome"
            case .updateSignSync: return "update.signToSync"
            }
        }
    }

    // FXIOS-6036 - Make this non optional when coordinators are used
    var introScreenManager: IntroScreenManager?

    var availableCards: [OnboardingCardViewController]
    var isDismissable: Bool
    var profile: Profile
    private var cardModels: [OnboardingCardInfoModelProtocol]

    // MARK: - Initializer
    init(
        introScreenManager: IntroScreenManager? = nil,
        profile: Profile
    ) {
        self.introScreenManager = introScreenManager
        self.profile = profile
        let model = NimbusOnboardingFeatureLayer().getOnboardingModel(for: .freshInstall)
        self.cardModels = model.cards
        self.isDismissable = model.isDismissable
        self.availableCards = []
    }

    // MARK: - Methods
    func setupViewControllerDelegates(with delegate: OnboardingCardDelegate) {
        availableCards.removeAll()
        cardModels.forEach { card in
            availableCards.append(OnboardingCardViewController(
                viewModel: OnboardingCardViewModel(infoModel: card),
                delegate: delegate))
        }
    }

// FXIOS-6358 - Implement telemetry
//    func sendCloseButtonTelemetry(index: Int) {
//        let extra = [TelemetryWrapper.EventExtraKey.cardType.rawValue: availableCards[index].viewModel.infoModel.name]
//
//        TelemetryWrapper.recordEvent(category: .action,
//                                     method: .tap,
//                                     object: .onboardingClose,
//                                     extras: extra)
//    }

    func saveHasSeenOnboarding() {
        introScreenManager?.didSeeIntroScreen()
    }
}
