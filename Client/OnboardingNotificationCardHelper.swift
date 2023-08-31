// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct OnboardingNotificationCardHelper {
    public func notificationCardIsInOnboarding(
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

    func shouldAskForNotificationsPermission(telemetryObj: TelemetryWrapper.EventObject) -> Bool {
        let isOnboarding = telemetryObj == .onboarding
        let shouldAskForPermission = !OnboardingNotificationCardHelper().notificationCardIsInOnboarding() || !isOnboarding
        return shouldAskForPermission
    }
}
