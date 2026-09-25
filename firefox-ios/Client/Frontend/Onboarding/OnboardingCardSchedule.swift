// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum OnboardingCardButtonAction {
    case none
    case enableNotifications
    case declineNotifications
}

/// Content for an onboarding card
struct OnboardingCard {
    let title: String
    let body: String
    // Asset name in the Client bundle, or nil for a text-only card
    let imageName: String?
    let primaryButtonTitle: String
    let primaryButtonAction: OnboardingCardButtonAction
    let secondaryButtonTitle: String?
    let secondaryButtonAction: OnboardingCardButtonAction

    init(
        title: String,
        body: String,
        imageName: String? = nil,
        primaryButtonTitle: String = "Continue",
        primaryButtonAction: OnboardingCardButtonAction = .none,
        secondaryButtonTitle: String? = nil,
        secondaryButtonAction: OnboardingCardButtonAction = .none
    ) {
        self.title = title
        self.body = body
        self.imageName = imageName
        self.primaryButtonTitle = primaryButtonTitle
        self.primaryButtonAction = primaryButtonAction
        self.secondaryButtonTitle = secondaryButtonTitle
        self.secondaryButtonAction = secondaryButtonAction
    }
}

/// This is the single table to edit to change which card(s) appear on which day. Keys are
/// engagement-day numbers (the Nth distinct day the user opens the app).
enum OnboardingDripSchedule {
    static let cardsByDay: [Int: [OnboardingCard]] = [
        2: [OnboardingCard(
            title: String.Onboarding.MultiDay.NotificationCard.Title,
            body: String.Onboarding.MultiDay.NotificationCard.BodyText,
            imageName: ImageIdentifiers.Onboarding.ContinuousOnboarding.notification,
            primaryButtonTitle: String.Onboarding.MultiDay.NotificationCard.AcceptButtonText,
            primaryButtonAction: .enableNotifications,
            secondaryButtonTitle: String.Onboarding.MultiDay.NotificationCard.DeclineButtonText,
            secondaryButtonAction: .declineNotifications)],
        7: [OnboardingCard(
            title: String.Onboarding.MultiDay.SyncCard.Title,
            body: String.Onboarding.MultiDay.SyncCard.BodyText,
            imageName: ImageIdentifiers.Onboarding.ContinuousOnboarding.sync,
            primaryButtonTitle: String.Onboarding.MultiDay.SyncCard.AcceptButtonText,
            primaryButtonAction: .none, // replace with something like .promptSignIn later
            secondaryButtonTitle: String.Onboarding.MultiDay.SyncCard.DeclineButtonText,
            secondaryButtonAction: .none)]
    ]
}
