// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class IntroViewModel: OnboardingViewModelProtocol, FeatureFlaggable {
    // MARK: - Properties
    // FXIOS-6036 - Make this non optional when coordinators are used
    var introScreenManager: IntroScreenManager?

    var availableCards: [OnboardingCardViewController]
    var infoPopup: OnboardingDefaultBrowserModelProtocol
    var isDismissable: Bool
    var profile: Profile
    var telemetryUtility: OnboardingTelemetryProtocol
    private var cardModels: [OnboardingCardInfoModelProtocol]

    // MARK: - Initializer
    init(
        introScreenManager: IntroScreenManager? = nil,
        profile: Profile,
        model: OnboardingViewModel,
        telemetryUtility: OnboardingTelemetryProtocol
    ) {
        self.introScreenManager = introScreenManager
        self.profile = profile
        self.telemetryUtility = telemetryUtility
        self.cardModels = model.cards
        self.isDismissable = model.isDismissable
        self.infoPopup = model.infoPopupModel
        self.availableCards = []
    }

    // MARK: - Methods
    func setupViewControllerDelegates(with delegate: OnboardingCardDelegate) {
        availableCards.removeAll()
        cardModels.forEach { cardModel in
            availableCards.append(OnboardingCardViewController(
                viewModel: cardModel,
                delegate: delegate))
        }
    }

    func saveHasSeenOnboarding() {
        introScreenManager?.didSeeIntroScreen()
    }
}
