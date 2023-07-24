// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import MozillaAppServices

/// A translation layer for the `onboardingFrameworkFeature.fml`
///
/// Responsible for creating a model for onboarding from the information
/// available in the fml, regardless of experiment. All updates to the
/// structure of the fml will have to be reflected in this class, especially
/// because defaults are not provided herein, but in the fml.
class NimbusOnboardingFeatureLayer: NimbusOnboardingFeatureLayerProtocol {
    private var helperUtility: NimbusMessagingHelperUtilityProtocol

    init(with helperUtility: NimbusMessagingHelperUtilityProtocol = NimbusMessagingHelperUtility()) {
        self.helperUtility = helperUtility
    }

    func getOnboardingModel(
        for onboardingType: OnboardingType,
        from nimbus: FxNimbus = FxNimbus.shared
    ) -> OnboardingViewModel {
        let framework = nimbus.features.onboardingFrameworkFeature.value()

        let cards = getOrderedOnboardingCards(
            for: onboardingType,
            from: framework.cards,
            withConditions: framework.conditions)

        return OnboardingViewModel(
            cards: cards,
            isDismissable: framework.dismissable)
    }

    private func getOrderedOnboardingCards(
        for onboardingType: OnboardingType,
        from cardData: [String: NimbusOnboardingCardData],
        withConditions conditionTable: [String: String]
    ) -> [OnboardingCardInfoModel] {
        // Sorting the cards this way, instead of a simple sort, to account for human
        // error in the order naming. If a card name is misspelled, it will be ignored
        // and not included in the list of cards.
        return getOnboardingCards(
            from: cardData.filter { $0.value.type == onboardingType },
            withConditions: conditionTable
        )
        .sorted(by: { $0.order < $1.order })
        // We have to update the a11yIdRoot using the correct order of the cards
        .enumerated()
        .map { index, card in
            return OnboardingCardInfoModel(
                name: card.name,
                order: card.order,
                title: card.title,
                body: card.body,
                link: card.link,
                buttons: card.buttons,
                type: card.type,
                a11yIdRoot: "\(card.a11yIdRoot)\(index)",
                imageID: card.imageID,
                instructionsPopup: card.instructionsPopup)
        }
    }

    private func getOnboardingCards(
        from cardData: [String: NimbusOnboardingCardData],
        withConditions conditionTable: [String: String]
    ) -> [OnboardingCardInfoModel] {
        let a11yOnboarding = AccessibilityIdentifiers.Onboarding.onboarding
        let a11yUpgrade = AccessibilityIdentifiers.Upgrade.upgrade

        // AppServices' Foreign Function Interface JEXL evaluator is an expensive
        // function. Therefore, we create a JEXL cache at the top level, to
        // be reused for each card, because the same conditions may have
        // already been evaluated, increasing performance.
        // However, this is unsing an `inout` operator, and that's poor practice.
        // It will be removed in:
        // TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-6572
        var jexlCache = [String: Bool]()

        // If `NimbusMessagingHelper` creation fails, we cannot continue with
        // evaluating card triggers based on their JEXL prerequisites.
        // Therefore, we return an empty array.
        guard let helper = helperUtility.createNimbusMessagingHelper() else { return [] }

        return cardData.compactMap { cardName, cardData in
            if cardIsValid(with: cardData, using: conditionTable, jexlCache: &jexlCache, and: helper) {
                return OnboardingCardInfoModel(
                    name: cardName,
                    order: cardData.order,
                    title: String(
                        format: cardData.title,
                        AppName.shortName.rawValue),
                    body: String(
                        format: cardData.body,
                        AppName.shortName.rawValue,
                        AppName.shortName.rawValue),
                    link: getOnboardingLink(from: cardData.link),
                    buttons: getOnboardingCardButtons(from: cardData.buttons),
                    type: cardData.type,
                    a11yIdRoot: cardData.type == .freshInstall ? a11yOnboarding : a11yUpgrade,
                    imageID: getOnboardingImageID(from: cardData.image),
                    instructionsPopup: getPopupInfoModel(
                        from: cardData.instructionsPopup,
                        withA11yID: "")
                )
            }

            return nil
        }
    }

    private func cardIsValid(
        with card: NimbusOnboardingCardData,
        using conditionTable: [String: String],
        jexlCache: inout [String: Bool],
        and helper: NimbusMessagingHelperProtocol
    ) -> Bool {
        let prerequisitesAreMet = verifyConditionEligibility(
            from: card.prerequisites,
            checkingAgainst: conditionTable,
            using: &jexlCache,
            and: helper)

        guard !card.disqualifiers.isEmpty else {
            return prerequisitesAreMet
        }

        let noDisqualifiersAreMet = !verifyConditionEligibility(
            from: card.disqualifiers,
            checkingAgainst: conditionTable,
            using: &jexlCache,
            and: helper)

        return prerequisitesAreMet && noDisqualifiersAreMet
    }

    private func verifyConditionEligibility(
        from cardConditions: [String],
        checkingAgainst conditionLookupTable: [String: String],
        using jexlCache: inout [String: Bool],
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
                using: helper,
                and: &jexlCache)
        } catch {
            return false
        }
    }

    /// Returns an optional array of ``OnboardingButtonInfoModel`` given the data.
    /// A card is not viable without buttons.
    private func getOnboardingCardButtons(from cardButtons: NimbusOnboardingButtons) -> OnboardingButtons {
        return OnboardingButtons(
            primary: OnboardingButtonInfoModel(
                title: cardButtons.primary.title,
                action: cardButtons.primary.action),
            secondary: cardButtons.secondary.map {
                OnboardingButtonInfoModel(title: $0.title, action: $0.action)
            })
    }

    private func getOnboardingLink(from cardLink: NimbusOnboardingLink?) -> OnboardingLinkInfoModel? {
        guard let cardLink = cardLink,
              let url = URL(string: cardLink.url)
        else { return nil }

        return OnboardingLinkInfoModel(title: cardLink.title, url: url)
    }

    private func getOnboardingImageID(from identifier: NimbusOnboardingImages) -> String {
        switch identifier {
        case .welcomeGlobe: return ImageIdentifiers.onboardingWelcomev106
        case .syncDevices: return ImageIdentifiers.onboardingSyncv106
        case .notifications: return ImageIdentifiers.onboardingNotification
        case .notificationsCtd: return ImageIdentifiers.onboardingNotificationsCTD
        case .welcomeCtd: return ImageIdentifiers.onboardingWelcomeCTD
        case .syncDevicesCtd: return ImageIdentifiers.onboardingSyncCTD
        case .setToDock: return ImageIdentifiers.onboardingSetToDock
        }
    }

    private func getPopupInfoModel(
        from data: NimbusInstructionPopup?,
        withA11yID a11yID: String
    ) -> OnboardingInstructionsPopupInfoModel? {
        guard let data else { return nil }

        return OnboardingInstructionsPopupInfoModel(
            title: data.title,
            instructionSteps: data.instructions
                .map { String(format: $0, AppName.shortName.rawValue)},
            buttonTitle: data.buttonTitle,
            buttonAction: data.buttonAction,
            a11yIdRoot: a11yID)
    }
}
