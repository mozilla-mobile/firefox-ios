// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class NimbusOnboardingFeatureLayer {
    func getOnboardingModel(from nimbus: FxNimbus = FxNimbus.shared) -> OnboardingViewModel {
        let framework = nimbus.features.onboardingFrameworkFeature.value()

        return OnboardingViewModel(
            cards: getOrderedOnboardingCards(from: framework.cards,
                                             using: framework.cardOrdering),
            dismissable: framework.dismissable)
    }

    private func getOrderedOnboardingCards(
        from cardData: [NimbusOnboardingCardData],
        using cardOrder: [String]
    ) -> [OnboardingCardInfoModel] {
        let cards = getOnboardingCards(from: cardData)
        var orderedCards = [OnboardingCardInfoModel]()

        // Sorting the cards this way, instead of a simple sort, to account for human
        // error in the ordering. If a card name is misspelled, it will be ignored
        // and not included in the list of cards.
        cardOrder.forEach { cardName in
            if let card = cards.first(where: { $0.name == cardName }) {
                orderedCards.append(card)
            }
        }

        return orderedCards
    }

    private func getOnboardingCards(from cardData: [NimbusOnboardingCardData]) -> [OnboardingCardInfoModel] {
        var cards = [OnboardingCardInfoModel]()

        cardData.forEach { card in
            cards.append(
                OnboardingCardInfoModel(name: card.name,
                                        title: card.title,
                                        body: card.body,
                                        image: getOnboardingImageID(from: card.image),
                                        link: getOnboardingLink(from: card.link),
                                        buttons: getOnboardingCardButtons(from: card.buttons),
                                        type: card.type))
        }

        return cards
    }

    private func getOnboardingCardButtons(from cardButtons: [NimbusOnboardingButton]) -> [OnboardingButtonInfoModel] {
        var buttons = [OnboardingButtonInfoModel]()

        cardButtons.forEach { button in
            buttons.append(OnboardingButtonInfoModel(title: button.title,
                                                     action: button.action))
        }

        return buttons
    }

    private func getOnboardingLink(from cardLink: NimbusOnboardingLink?) -> OnboardingLinkInfoModel? {
        guard let cardLink = cardLink,
              let url = URL(string: cardLink.url)
        else { return nil }

        return OnboardingLinkInfoModel(title: cardLink.title,
                                       url: url)
    }

    private func getOnboardingImageID(from identifier: NimbusOnboardingImages) -> String {
        switch identifier {
        case .welcomeGlobe: return ImageIdentifiers.onboardingWelcomev106
        case .syncDevices: return ImageIdentifiers.onboardingSyncv106
        case .notifications: return ImageIdentifiers.onboardingNotification
        }
    }
}
