// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import protocol MozillaAppServices.NimbusMessagingHelperProtocol

protocol NimbusOnboardingFeatureLayerProtocol {
    associatedtype ViewModel
    func getOnboardingModel(
        for onboardingType: OnboardingType,
        from nimbus: FxNimbus
    ) -> ViewModel
}

extension NimbusOnboardingFeatureLayerProtocol {
    func cardIsValid(
        with card: NimbusOnboardingCardData,
        using conditionTable: [String: String],
        and helper: NimbusMessagingHelperProtocol
    ) -> Bool {
        let prerequisitesAreMet = verifyConditionEligibility(
            from: card.prerequisites,
            checkingAgainst: conditionTable,
            and: helper)

        guard !card.disqualifiers.isEmpty else {
            return prerequisitesAreMet
        }

        let noDisqualifiersAreMet = !verifyConditionEligibility(
            from: card.disqualifiers,
            checkingAgainst: conditionTable,
            and: helper)

        return prerequisitesAreMet && noDisqualifiersAreMet
    }

    func verifyConditionEligibility(
        from cardConditions: [String],
        checkingAgainst conditionLookupTable: [String: String],
        and helper: NimbusMessagingHelperProtocol
    ) -> Bool {
        // Make sure conditions exist and have a value, and that the number
        // of valid conditions matches the number of conditions on the card's
        // respective prerequisite or disqualifier table. If these mismatch,
        // that means a card contains a condition that's not in the feature
        // conditions lookup table. JEXLS can only be evaluated on
        // supported conditions. Otherwise, consider the card invalid.
        let conditions = cardConditions.compactMap({ conditionLookupTable[$0] })
        guard conditions.count == cardConditions.count else { return false }

        do {
            return try NimbusMessagingEvaluationUtility().doesObjectMeet(
                verificationRequirements: conditions,
                using: helper)
        } catch {
            return false
        }
    }

    func getOnboardingHeaderImageID(
        from identifier: NimbusOnboardingHeaderImage
    ) -> String {
        switch identifier {
        case .welcomeGlobe: return ImageIdentifiers.Onboarding.HeaderImages.welcomev106
        case .syncDevices: return ImageIdentifiers.Onboarding.HeaderImages.syncv106
        case .notifications: return ImageIdentifiers.Onboarding.HeaderImages.notification
        case .setDefaultSteps: return ImageIdentifiers.Onboarding.HeaderImages.setDefaultSteps
        case .setToDock: return ImageIdentifiers.Onboarding.HeaderImages.setToDock
        case .searchWidget: return ImageIdentifiers.Onboarding.HeaderImages.searchWidget
            // Customization experiment
        case .themeing: return ImageIdentifiers.Onboarding.HeaderImages.theming
        case .toolbar: return ImageIdentifiers.Onboarding.HeaderImages.toolbar
        case .customizeFirefox: return ImageIdentifiers.Onboarding.HeaderImages.customizeFirefox
            // Challenge the Default experiment
        case .notificationsCtd: return ImageIdentifiers.Onboarding.ChallengeTheDefault.notifications
        case .welcomeCtd: return ImageIdentifiers.Onboarding.ChallengeTheDefault.welcome
        case .syncDevicesCtd: return ImageIdentifiers.Onboarding.ChallengeTheDefault.sync
        case .syncWithIcons: return ImageIdentifiers.Onboarding.HeaderImages.syncWithIcons
        case .trackers: return ImageIdentifiers.Onboarding.HeaderImages.trackers
        }
    }

    func getOnboardingMultipleChoiceButtonImageID(
        from identifier: NimbusOnboardingMultipleChoiceButtonImage
    ) -> String {
        switch identifier {
        case .themeSystem: return ImageIdentifiers.Onboarding.MultipleChoiceButtonImages.themeSystem
        case .themeDark: return ImageIdentifiers.Onboarding.MultipleChoiceButtonImages.themeDark
        case .themeLight: return ImageIdentifiers.Onboarding.MultipleChoiceButtonImages.themeLight
        case .toolbarTop: return ImageIdentifiers.Onboarding.MultipleChoiceButtonImages.toolbarTop
        case .toolbarBottom: return ImageIdentifiers.Onboarding.MultipleChoiceButtonImages.toolbarBottom
        }
    }
}
