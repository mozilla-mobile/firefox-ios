// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class NimbusOnboardingFeatureLayer: NimbusOnboardingFeatureLayerProtocol {
    /// Fetches an ``OnboardingViewModel`` from ``FxNimbus`` configuration.
    ///
    /// - Parameter nimbus: The ``FxNimbus/shared`` instance.
    /// - Returns: An ``OnboardingViewModel`` to be used in the onboarding.
    func getOnboardingModel(from nimbus: FxNimbus = FxNimbus.shared) -> OnboardingViewModel {
        let framework = nimbus.features.onboardingFrameworkFeature.value()

        return OnboardingViewModel(
            cards: getOrderedOnboardingCards(from: framework.cards,
                                             using: framework.cardOrdering),
            dismissable: framework.dismissable)
    }

    /// Will sort onboarding cards according to specified order in the
    /// Nimbus configuration. If the names of cards and the names in the card
    /// order array don't match, these cards will simply not be shown in onboarding.
    ///
    /// - Parameters:
    ///   - cardData: Card data from ``FxNimbus/shared``
    ///   - cardOrder: Card order from ``FxNimbus/shared``
    /// - Returns: Card data converted to ``OnboardingCardInfoModel`` and ordered.
    private func getOrderedOnboardingCards(
        from cardData: [NimbusOnboardingCardData],
        using cardOrder: [String]
    ) -> [OnboardingCardInfoModel] {
        let cards = getOnboardingCards(from: cardData)

        // Sorting the cards this way, instead of a simple sort, to account for human
        // error in the order naming. If a card name is misspelled, it will be ignored
        // and not included in the list of cards.
        return cardOrder.compactMap { cardName in
            guard let card = cards.first(where: { $0.name == cardName }) else { return nil }
            return card
        }
    }

    /// Converts ``NimbusOnboardingCardData`` to ``OnboardingCardInfoModel``
    /// to be used in the onboarding process.
    ///
    /// All cards must have valid formats and data. For example, a card with no
    /// buttons, will be omitted from the returned cards.
    ///
    /// - Parameter cardData: Card data from ``FxNimbus/shared``
    /// - Returns: An array of viable ``OnboardingCardInfoModel``
    private func getOnboardingCards(from cardData: [NimbusOnboardingCardData]) -> [OnboardingCardInfoModel] {
        return cardData.compactMap { card in
            let image = getOnboardingImageID(from: card.image)
            guard let buttons = getOnboardingCardButtons(from: card.buttons),
                  !buttons.isEmpty
            else { return nil }

            return OnboardingCardInfoModel(name: card.name,
                                           title: card.title,
                                           body: card.body,
                                           image: image,
                                           link: getOnboardingLink(from: card.link),
                                           buttons: buttons,
                                           type: card.type)
        }
    }

    /// Returns an optional array of ``OnboardingButtonInfoModel`` given the data.
    /// A card is not viable without buttons.
    private func getOnboardingCardButtons(from cardButtons: [NimbusOnboardingButton]) -> [OnboardingButtonInfoModel]? {
        if cardButtons.isEmpty { return nil }

        return cardButtons.map { OnboardingButtonInfoModel(title: $0.title, action: $0.action) }
    }

    /// Returns an optional ``OnboardingLinkInfoModel``, if one is provided. This will be
    /// used by the application in the privacy policy link.
    private func getOnboardingLink(from cardLink: NimbusOnboardingLink?) -> OnboardingLinkInfoModel? {
        guard let cardLink = cardLink,
              let url = URL(string: cardLink.url)
        else { return nil }

        return OnboardingLinkInfoModel(title: cardLink.title, url: url)
    }

    /// Translates a nimbus image ID for onboarding to an ``ImageIdentifiers`` based id
    /// that corresponds to an app resource.
    ///
    /// In the case that an unknown image identifier is entered into experimenter, the
    /// Nimbus will return the default image identifier, in this case,
    /// ``NimbusOnboardingImages/welcomeGlobe``
    ///
    /// - Parameter identifier: The given identifier for an image from ``FxNimbus/shared``
    /// - Returns: A string to be used as a proper identifier in the onboarding
    private func getOnboardingImageID(from identifier: NimbusOnboardingImages) -> String {
        switch identifier {
        case .welcomeGlobe: return ImageIdentifiers.onboardingWelcomev106
        case .syncDevices: return ImageIdentifiers.onboardingSyncv106
        case .notifications: return ImageIdentifiers.onboardingNotification
        }
    }
}
