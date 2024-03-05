// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

enum CardViewType: String {
    case welcomeView = "welcome"
    case defaultBrowserView = "default-browser"
    case widgetTutorial = "widget-tutorial"
}

class OnboardingTelemetryHelper {
    public enum Event {
        case getStartedAppeared
        case getStartedCloseTapped
        case getStartedButtonTapped
        case defaultBrowserCloseTapped
        case defaultBrowserSettingsTapped
        case defaultBrowserSkip
        case defaultBrowserAppeared
        case widgetCardAppeared
        case widgetPrimaryButtonTapped
        case widgetCloseTapped
    }

    func handle(event: Event) {
        switch event {
        case .getStartedAppeared:
            let cardTypeExtra = GleanMetrics.Onboarding.CardViewExtra(cardType: CardViewType.welcomeView.rawValue)
            GleanMetrics.Onboarding.cardView.record(cardTypeExtra)
        case .getStartedCloseTapped:
            let cardTypeExtra = GleanMetrics.Onboarding.CloseTapExtra(cardType: CardViewType.welcomeView.rawValue)
            GleanMetrics.Onboarding.closeTap.record(cardTypeExtra)
        case .getStartedButtonTapped:
            let cardTypeExtra = GleanMetrics.Onboarding.PrimaryButtonTapExtra(cardType: CardViewType.welcomeView.rawValue)
            GleanMetrics.Onboarding.primaryButtonTap.record(cardTypeExtra)
        case .defaultBrowserCloseTapped:
            let cardTypeExtra = GleanMetrics.Onboarding.CloseTapExtra(cardType: CardViewType.defaultBrowserView.rawValue)
            GleanMetrics.Onboarding.closeTap.record(cardTypeExtra)
        case .defaultBrowserSettingsTapped:
            GleanMetrics.DefaultBrowserOnboarding.goToSettingsPressed.add()
        case .defaultBrowserSkip:
            GleanMetrics.DefaultBrowserOnboarding.skipButtonTapped.record()
        case .defaultBrowserAppeared:
            let cardTypeExtra = GleanMetrics.Onboarding.CardViewExtra(cardType: CardViewType.defaultBrowserView.rawValue)
            GleanMetrics.Onboarding.cardView.record(cardTypeExtra)
        case .widgetCardAppeared:
            let cardTypeExtra = GleanMetrics.Onboarding.CardViewExtra(cardType: CardViewType.widgetTutorial.rawValue)
            GleanMetrics.Onboarding.cardView.record(cardTypeExtra)
        case .widgetPrimaryButtonTapped:
            let cardTypeExtra = GleanMetrics.Onboarding.PrimaryButtonTapExtra(cardType: CardViewType.widgetTutorial.rawValue)
            GleanMetrics.Onboarding.primaryButtonTap.record(cardTypeExtra)
        case .widgetCloseTapped:
            let cardTypeExtra = GleanMetrics.Onboarding.CloseTapExtra(cardType: CardViewType.widgetTutorial.rawValue)
            GleanMetrics.Onboarding.closeTap.record(cardTypeExtra)
        }
    }
}
