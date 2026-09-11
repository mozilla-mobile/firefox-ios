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
            title: "Stay in the loop",
            body: "Turn on notifications to get tips and updates from Firefox.",
            imageName: ImageIdentifiers.Onboarding.HeaderImages.notification,
            primaryButtonTitle: "Turn on notifications",
            primaryButtonAction: .enableNotifications,
            secondaryButtonTitle: "Not now",
            secondaryButtonAction: .declineNotifications)],
        7: [OnboardingCard(
            title: "Browse with confidence",
            body: "Day 7 placeholder card. Firefox blocks trackers by default.",
            imageName: ImageIdentifiers.Onboarding.HeaderImages.trackers)]
    ]
}
