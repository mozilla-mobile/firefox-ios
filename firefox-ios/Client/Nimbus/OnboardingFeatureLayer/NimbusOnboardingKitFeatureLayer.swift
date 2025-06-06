// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import OnboardingKit

/// A translation layer for the `onboardingFrameworkFeature.fml`
///
/// Responsible for creating a model for onboarding from the information
/// available in the fml, regardless of experiment. All updates to the
/// structure of the fml will have to be reflected in this class, especially
/// because defaults are not provided herein, but in the fml.
class NimbusOnboardingKitFeatureLayer: NimbusOnboardingFeatureLayerProtocol {
    private var helperUtility: NimbusMessagingHelperUtilityProtocol

    init(with helperUtility: NimbusMessagingHelperUtilityProtocol = NimbusMessagingHelperUtility()) {
        self.helperUtility = helperUtility
    }

    func getOnboardingModel(
        for onboardingType: OnboardingType,
        from nimbus: FxNimbus = FxNimbus.shared
    ) -> OnboardingKitViewModel {
        let framework = nimbus.features.onboardingFrameworkFeature.value()

        let cards = getOrderedOnboardingCards(
            for: onboardingType,
            from: framework.cards,
            withConditions: framework.conditions)

        return OnboardingKitViewModel(
            cards: cards,
            isDismissable: framework.dismissable)
    }

    private func getOrderedOnboardingCards(
        for onboardingType: OnboardingType,
        from cardData: [String: NimbusOnboardingCardData],
        withConditions conditionTable: [String: String]
    ) -> [OnboardingKitCardInfoModel] {
        // Sorting the cards this way, instead of a simple sort, to account for human
        // error in the order naming. If a card name is misspelled, it will be ignored
        // and not included in the list of cards.
        return getOnboardingCards(
            from: cardData.filter {
                $0.value.onboardingType == onboardingType &&
                $0.value.uiVariant == .modern
            },
            withConditions: conditionTable
        )
        .sorted(by: { $0.order < $1.order })
        // We have to update the a11yIdRoot using the correct order of the cards
        .enumerated()
        .map { index, card in
            return OnboardingKitCardInfoModel(
                cardType: card.cardType,
                name: card.name,
                order: card.order,
                title: card.title,
                body: card.body,
                link: card.link,
                buttons: card.buttons,
                multipleChoiceButtons: card.multipleChoiceButtons,
                onboardingType: card.onboardingType,
                a11yIdRoot: "\(card.a11yIdRoot)\(index)",
                imageID: card.imageID,
                instructionsPopup: card.instructionsPopup)
        }
    }

    private func getOnboardingCards(
        from cardData: [String: NimbusOnboardingCardData],
        withConditions conditionTable: [String: String]
    ) -> [OnboardingKitCardInfoModel] {
        let a11yOnboarding = AccessibilityIdentifiers.Onboarding.onboarding
        let a11yUpgrade = AccessibilityIdentifiers.Upgrade.upgrade

        // If `NimbusMessagingHelper` creation fails, we cannot continue with
        // evaluating card triggers based on their JEXL prerequisites.
        // Therefore, we return an empty array.
        guard let helper = helperUtility.createNimbusMessagingHelper() else { return [] }

        return cardData.compactMap { cardName, cardData in
            if cardIsValid(with: cardData, using: conditionTable, and: helper) {
                return OnboardingKitCardInfoModel(
                    cardType: OnboardingKit.OnboardingCardType(rawValue: cardData.cardType.rawValue) ?? .basic,
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
                    multipleChoiceButtons: getOnboardingMultipleChoiceButtons_(from: cardData.multipleChoiceButtons),
                    onboardingType: cardData.onboardingType,
                    a11yIdRoot: cardData.onboardingType == .freshInstall ? a11yOnboarding : a11yUpgrade,
                    imageID: getOnboardingHeaderImageID(from: cardData.image),
                    instructionsPopup: getPopupInfoModel(
                        from: cardData.instructionsPopup,
                        withA11yID: "")
                )
            }

            return nil
        }
    }

    /// Returns an optional array of ``OnboardingButtonInfoModel`` given the data.
    /// A card is not viable without buttons.
    private func getOnboardingCardButtons(
        from cardButtons: NimbusOnboardingButtons
    ) -> OnboardingKit.OnboardingButtons<OnboardingActions> {
        return OnboardingKit.OnboardingButtons(
            primary: OnboardingKit.OnboardingButtonInfoModel(
                title: String(format: cardButtons.primary.title,
                              AppName.shortName.rawValue),
                action: cardButtons.primary.action),
            secondary: cardButtons.secondary.map {
                OnboardingKit.OnboardingButtonInfoModel(title: $0.title, action: $0.action)
            })
    }

    private func getOnboardingMultipleChoiceButtons_(
        from cardButtons: [NimbusOnboardingMultipleChoiceButton]
    ) -> [OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>] {
        return cardButtons.map { button in
            return OnboardingKit.OnboardingMultipleChoiceButtonModel(
                title: button.title,
                action: button.action,
                imageID: getOnboardingMultipleChoiceButtonImageID(from: button.image)
            )
        }
    }

    private func getOnboardingLink(
        from cardLink: NimbusOnboardingLink?
    ) -> OnboardingKit.OnboardingLinkInfoModel? {
        guard let cardLink = cardLink,
              let url = URL(string: cardLink.url)
        else { return nil }

        return OnboardingKit.OnboardingLinkInfoModel(title: cardLink.title, url: url)
    }

    private func getPopupInfoModel(
        from data: NimbusOnboardingInstructionPopup?,
        withA11yID a11yID: String
    ) -> OnboardingKit.OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>? {
        guard let data else { return nil }

        return OnboardingKit.OnboardingInstructionsPopupInfoModel(
            title: data.title,
            instructionSteps: data.instructions
                .map { String(format: $0, AppName.shortName.rawValue)
                },
            buttonTitle: data.buttonTitle,
            buttonAction: data.buttonAction,
            a11yIdRoot: a11yID)
    }
}
