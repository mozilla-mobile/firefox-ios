// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import OnboardingKit

enum OnboardingReason: String {
    case newUser = "new_user"
    case showTour = "show_tour"
}

protocol OnboardingTelemetryProtocol: AnyObject {
    func sendCardViewTelemetry(from cardName: String)
    func sendButtonActionTelemetry(from cardName: String,
                                   with action: OnboardingActions,
                                   and primaryButton: Bool)
    func sendMultipleChoiceButtonActionTelemetry(
        from cardName: String,
        with action: OnboardingMultipleChoiceAction
    )
    func sendDismissOnboardingTelemetry(from cardName: String)
    func sendGoToSettingsButtonTappedTelemetry()
    func sendDismissButtonTappedTelemetry()
    /// Records `onboarding.shown` and submits the `onboarding` ping.
    func sendOnboardingShownTelemetry()
    /// Records `onboarding.dismissed` with the given method and submits the `onboarding` ping.
    func sendOnboardingDismissedTelemetry(outcome: OnboardingFlowOutcome)
    func sendWallpaperSelectorViewTelemetry()
    func sendWallpaperSelectorCloseTelemetry()
    func sendWallpaperSelectorSelectedTelemetry(wallpaperName: String, wallpaperType: String)
    func sendWallpaperSelectedTelemetry(wallpaperName: String, wallpaperType: String)
    func sendEngagementNotificationTappedTelemetry()
    func sendEngagementNotificationCancelTelemetry()
}
