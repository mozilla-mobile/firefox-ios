// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingCardProtocol {
    var infoModel: OnboardingCardInfoModelProtocol { get }

    func sendCardViewTelemetry()
    func sendTelemetryButton(isPrimaryAction: Bool)
}

struct OnboardingCardViewModel: OnboardingCardProtocol {
    var infoModel: OnboardingCardInfoModelProtocol

    init(infoModel: OnboardingCardInfoModelProtocol) {
        self.infoModel = infoModel
    }

    func sendCardViewTelemetry() {
// FXIOS-6358 - Implement telemetry
//        let extra = [TelemetryWrapper.EventExtraKey.cardType.rawValue: cardType.telemetryValue]
//        let eventObject: TelemetryWrapper.EventObject = cardType.isOnboardingScreen ?
//            . onboardingCardView : .upgradeOnboardingCardView

//        TelemetryWrapper.recordEvent(category: .action,
//                                     method: .view,
//                                     object: eventObject,
//                                     value: nil,
//                                     extras: extra)
    }

    func sendTelemetryButton(isPrimaryAction: Bool) {
//        let eventObject: TelemetryWrapper.EventObject
//        let extra = [TelemetryWrapper.EventExtraKey.cardType.rawValue: cardType.telemetryValue]
//
//        switch (isPrimaryAction, cardType.isOnboardingScreen) {
//        case (true, true):
//            eventObject = TelemetryWrapper.EventObject.onboardingPrimaryButton
//        case (false, true):
//            eventObject = TelemetryWrapper.EventObject.onboardingSecondaryButton
//        case (true, false):
//            eventObject = TelemetryWrapper.EventObject.upgradeOnboardingPrimaryButton
//        case (false, false):
//            eventObject = TelemetryWrapper.EventObject.upgradeOnboardingSecondaryButton
//        }
//
//        TelemetryWrapper.recordEvent(category: .action,
//                                     method: .tap,
//                                     object: eventObject,
//                                     value: nil,
//                                     extras: extra)
    }
}
