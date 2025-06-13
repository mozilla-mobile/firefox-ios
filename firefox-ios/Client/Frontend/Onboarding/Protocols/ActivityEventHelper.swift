// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class ActivityEventHelper {
    var chosenOptions: IntroViewModel.OnboardingOptions = []

    init(chosenOptions: IntroViewModel.OnboardingOptions = []) {
        self.chosenOptions = chosenOptions
    }

    // MARK: SkAdNetwork
    // this event should be sent in the first 24h time window, if it's not sent the conversion value is locked by Apple
    func updateOnboardingUserActivationEvent() {
        let fineValue = IntroViewModel
            .OnboardingOptions
            .allCases
            .map { chosenOptions.contains($0) ? $0.rawValue : 0 }.reduce(0, +)
        let conversionValue = ConversionValueUtil(fineValue: fineValue, coarseValue: .low, logger: DefaultLogger.shared)
        // we should send this event only if an action has been selected during the onboarding flow
        if fineValue > 0 {
            conversionValue.adNetworkAttributionUpdateConversionEvent()
        }
    }
}
