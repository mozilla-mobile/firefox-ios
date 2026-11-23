// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct OnboardingSheetRow: Equatable {
    public let imageName: String
    public let title: String
    public let subtitle: String

    public init(imageName: String, title: String, subtitle: String) {
        self.imageName = imageName
        self.title = title
        self.subtitle = subtitle
    }
}

public struct OnboardingSheetViewModel: Equatable {
    public let heroImageName: String
    public let heroGradient: OnboardingSheetHeroGradient
    public let title: String
    public let description: String
    public let rows: [OnboardingSheetRow]
    public let learnMoreTitle: String
    public let ctaTitle: String
    public let closeAccessibilityLabel: String
    public let ctaAccessibilityIdentifier: String
    public let learnMoreAccessibilityIdentifier: String
    public let closeAccessibilityIdentifier: String

    public init(
        heroImageName: String,
        heroGradient: OnboardingSheetHeroGradient,
        title: String,
        description: String,
        rows: [OnboardingSheetRow],
        learnMoreTitle: String,
        ctaTitle: String,
        closeAccessibilityLabel: String,
        ctaAccessibilityIdentifier: String,
        learnMoreAccessibilityIdentifier: String,
        closeAccessibilityIdentifier: String
    ) {
        self.heroImageName = heroImageName
        self.heroGradient = heroGradient
        self.title = title
        self.description = description
        self.rows = rows
        self.learnMoreTitle = learnMoreTitle
        self.ctaTitle = ctaTitle
        self.closeAccessibilityLabel = closeAccessibilityLabel
        self.ctaAccessibilityIdentifier = ctaAccessibilityIdentifier
        self.learnMoreAccessibilityIdentifier = learnMoreAccessibilityIdentifier
        self.closeAccessibilityIdentifier = closeAccessibilityIdentifier
    }
}
