// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

<<<<<<< HEAD
class OnboardingNotificationCardHelper: FeatureFlaggable {
    var cardPosition: OnboardingNotificationCardPosition {
        return featureFlags.getCustomState(for: .onboardingNotificationCard) ?? .noCard
    }

    func askForPermissionDuringSync(isOnboarding: Bool) -> Bool {
        switch cardPosition {
        case .noCard:
            return true
        case .beforeSync, .afterSync:
            return !isOnboarding // we ask for permission on notification card instead
        }
=======
struct OnboardingNotificationCardHelper {
    private func notificationCardIsInOnboarding(
        from featureLayer: NimbusOnboardingFeatureLayer = NimbusOnboardingFeatureLayer()
    ) -> Bool {
        return featureLayer
            .getOnboardingModel(for: .freshInstall)
            .cards
            .contains {
                return $0.buttons.primary.action == .requestNotifications
                || $0.buttons.secondary?.action == .requestNotifications
            }
    }

    func askForPermissionDuringSync(isOnboarding: Bool) -> Bool {
        if notificationCardIsInOnboarding() { return false }

        return isOnboarding
>>>>>>> b9fe0bfb7 (Bugfix FXIOS-6467 [v114] Ask for permission after sync sign in bug (#14592))
    }
}
