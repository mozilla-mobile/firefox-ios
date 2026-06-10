// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class ActivityEventHelper {
    struct OnboardingOptions: OptionSet, CaseIterable {
        let rawValue: Int

        static let askForNotificationPermission = OnboardingOptions(rawValue: 1 << 0) // 1
        static let setAsDefaultBrowser = OnboardingOptions(rawValue: 1 << 1) // 2
        static let syncSignIn = OnboardingOptions(rawValue: 1 << 2) // 4

        static var allCases: [OnboardingOptions] {
            return [.askForNotificationPermission, .setAsDefaultBrowser, .syncSignIn]
        }
    }

    var chosenOptions: OnboardingOptions = []

    init(chosenOptions: OnboardingOptions = []) {
        self.chosenOptions = chosenOptions
    }

    // MARK: SkAdNetwork
    func updateOnboardingUserActivationEvent() {
        guard chosenOptions.contains(.setAsDefaultBrowser) else { return }
        ConversionEventTracker().record(.setAsDefault)
    }
}
