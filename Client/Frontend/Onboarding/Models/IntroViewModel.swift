// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

class IntroViewModel: OnboardingViewModelProtocol, FeatureFlaggable {
    struct OnboardingOptions: OptionSet, CaseIterable {
        let rawValue: Int

        static let askForNotificationPermission = OnboardingOptions(rawValue: 1 << 0) // 1
        static let setAsDefaultBrowser = OnboardingOptions(rawValue: 1 << 1) // 2
        static let syncSignIn = OnboardingOptions(rawValue: 1 << 2) // 4

        static var allCases: [OnboardingOptions] {
            return [.askForNotificationPermission, .setAsDefaultBrowser, .syncSignIn]
        }
    }

    // MARK: - Properties
    // FXIOS-6036 - Make this non optional when coordinators are used
    var introScreenManager: IntroScreenManager?
    var chosenOptions: OnboardingOptions = []

    var availableCards: [OnboardingCardViewController]
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

    // MARK: SkAdNetwork
    // this event should be sent in the first 24h time window, if it's not sent the conversion value is locked by Apple
    func updateOnboardingUserActivationEvent() {
        let fineValue = OnboardingOptions.allCases.map { chosenOptions.contains($0) ? $0.rawValue : 0 }.reduce(0, +)
        let conversionValue = ConversionValueUtil(fineValue: fineValue, coarseValue: .low, logger: DefaultLogger.shared)
        // we should send this event only if an action has been selected during the onboarding flow
        if fineValue > 0 {
            conversionValue.adNetworkAttributionUpdateConversionEvent()
        }
    }
}
