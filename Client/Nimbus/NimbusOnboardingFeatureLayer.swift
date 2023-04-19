// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class NimbusOnboardingFeatureLayer {
    // MARK: - Properties
    private let nimbus: FxNimbus

    init(nimbus: FxNimbus = FxNimbus.shared) {
        self.nimbus = nimbus
    }

    func getOnboardingModel() -> OnboardingViewModel {
        let framework = nimbus.features.onboardingFrameworkFeature.value()

        return OnboardingViewModel(cards: framework.cards,
                                   cardOrder: framework.cardOrdering,
                                   dismissable: framework.dismissable)
    }

    private func getOnboardingCards(from cardData: [OnboardingCardData]) -> [OnboardingCardInfo] {
        var cards = [OnboardingCardInfo]()

        card.forEach { card in
            let buttons = getOnboardingCardButtons(from: card.buttons)
            cards.append(OnboardingCardInfo(
                name: card.name,
                title: card.title,
                body: card.body,
                link: getOnboardingLink(from: card.link),
                buttons: getOnboardingCardButtons(from: card.buttons),
                type: card.type))
        }
    }

    private func getOnboardingCardButtons(from cardButtons: [OnboardingButton]) -> [OnboardingButtonInfo] {

    }

    private func getOnboardingLink(from cardLink: OnboardingLink) -> OnboardingLinkInfo? {

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
    let cardOrder: [String]?
    let dismissable: Bool
}
