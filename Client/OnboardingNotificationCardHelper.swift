// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class OnboardingNotificationCardHelper: FeatureFlaggable {
    var notificationCardIsInOnboarding: Bool {
        return NimbusOnboardingFeatureLayer()
            .getOnboardingModel(for: .freshInstall)
            .cards
            .contains { $0.buttons.primary.action == .requestNotifications }
    }

    func askForPermissionDuringSync(isOnboarding: Bool) -> Bool {
        if notificationCardIsInOnboarding {
            return !isOnboarding // we ask for permission on notification card instead
        }

        return true
    }
}
