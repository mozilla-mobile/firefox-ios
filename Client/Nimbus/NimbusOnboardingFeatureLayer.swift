// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

// I'm building everything in one big file for now because of existing legacy stuff.
// I'll split everything up for the PR. :)
class NimbusOnboardingFeatureLayer {
    func getOnboardingModel(from nimbus: FxNimbus = FxNimbus.shared) -> OnboardingViewModel {
        let framework = nimbus.features.onboardingFrameworkFeature.value()

        return OnboardingViewModel(
            cards: getOrderedOnboardingCards(from: framework.cards,
                                             using: framework.cardOrdering),
            dismissable: framework.dismissable)
    }

    private func getOrderedOnboardingCards(
        from cardData: [OnboardingCardData],
        using cardOrder: [String]
    ) -> [OnboardingCardInfo] {
        return getOnboardingCards(from: cardData).sorted { firstCard, secondCard in
            guard let indexOfFirstCard = cardOrder.firstIndex(of: firstCard.name),
                  let indexOfSecondCard = cardOrder.firstIndex(of: secondCard.name)
            else { return false }

            return indexOfFirstCard < indexOfSecondCard
        }
    }

    private func getOnboardingCards(from cardData: [OnboardingCardData]) -> [OnboardingCardInfo] {
        var cards = [OnboardingCardInfo]()

//        cardData.forEach { card in
//            let buttons = getOnboardingCardButtons(from: card.buttons)
//            cards.append(OnboardingCardInfo(
//                name: card.name,
//                title: card.title,
//                body: card.body,
//                link: getOnboardingLink(from: card.link),
//                buttons: getOnboardingCardButtons(from: card.buttons),
//                type: card.type))
//        }

        return cards
    }

    private func getOnboardingCardButtons(from cardButtons: [OnboardingButton]) -> [OnboardingButtonInfo] {
        var buttons = [OnboardingButtonInfo]()

//        cardButtons.forEach { button in
//             blah blah blah
//        }

        return buttons
    }

    private func getOnboardingLink(from cardLink: OnboardingLink?) -> OnboardingLinkInfo? {
        guard let cardLink = cardLink,
              let url = URL(string: cardLink.url)
        else { return nil }

        return OnboardingLinkInfo(title: cardLink.title,
                                  url: url)
    }
}

struct OnboardingButtonInfo {
    let title: String
    let action: OnboardingActions
}

struct OnboardingLinkInfo {
    let title: String
    let url: URL
}

struct OnboardingCardInfo {
    let name: String
    let title: String
    let body: String
    let link: OnboardingLinkInfo?
    let buttons: [OnboardingButtonInfo]
    let type: OnboardingType
}

struct OnboardingViewModel {
    let cards: [OnboardingCardInfo]?
    let dismissable: Bool
}
