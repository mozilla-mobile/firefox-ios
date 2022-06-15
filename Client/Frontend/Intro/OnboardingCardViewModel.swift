// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingCardProtocol {
    var cardType: IntroViewModel.OnboardingCards { get set }
    var image: UIImage? { get set }
    var title: String { get set }
    var description: String? { get set }
    var primaryAction: String { get set }
    var secondaryAction: String? { get set }
    var a11yIdRoot: String { get set }

    func sendCardViewTelemetry()
    func sendTelemetryButton(isPrimaryAction: Bool)
}

struct OnboardingCardViewModel: OnboardingCardProtocol {
    var cardType: IntroViewModel.OnboardingCards
    var image: UIImage?
    var title: String
    var description: String?
    var primaryAction: String
    var secondaryAction: String?
    var a11yIdRoot: String
    var welcomeCardBoldText: String = .Onboarding.IntroDescriptionPart1

    init(cardType: IntroViewModel.OnboardingCards,
         image: UIImage?,
         title: String,
         description: String?,
         primaryAction: String,
         secondaryAction: String?,
         a11yIdRoot: String) {

        self.cardType = cardType
        self.image = image
        self.title = title
        self.description = description
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.a11yIdRoot = a11yIdRoot
    }

    func sendCardViewTelemetry() {
        let extra = [TelemetryWrapper.EventExtraKey.cardType.rawValue: cardType.telemetryValue]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .onboardingCardView,
                                     value: nil,
                                     extras: extra)
    }

    func sendTelemetryButton(isPrimaryAction: Bool) {
        let eventObject = isPrimaryAction ? TelemetryWrapper.EventObject.onboardingPrimaryButton : TelemetryWrapper.EventObject.onboardingSecondaryButton
        let extra = [TelemetryWrapper.EventExtraKey.cardType.rawValue: cardType.telemetryValue]

        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: eventObject,
                                     value: nil,
                                     extras: extra)
    }
}
