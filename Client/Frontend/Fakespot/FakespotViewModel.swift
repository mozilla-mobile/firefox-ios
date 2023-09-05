// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class FakespotViewModel {
    enum ViewState<T> {
        case loading
        case loaded(T)
        case error(Error)
    }

    @Published private(set) var state: ViewState<ProductAnalysisData?> = .loading
    let shoppingProduct: ShoppingProduct

    let reliabilityCardViewModel = ReliabilityCardViewModel(
        cardA11yId: AccessibilityIdentifiers.Shopping.ReliabilityCard.card,
        title: .Shopping.ReliabilityCardTitle,
        titleA11yId: AccessibilityIdentifiers.Shopping.ReliabilityCard.title,
        rating: .gradeA,
        ratingLetterA11yId: AccessibilityIdentifiers.Shopping.ReliabilityCard.ratingLetter,
        ratingDescriptionA11yId: AccessibilityIdentifiers.Shopping.ReliabilityCard.ratingDescription
    )

    let errorCardViewModel = FakespotErrorCardViewModel(
        title: .Shopping.ErrorCardTitle,
        description: .Shopping.ErrorCardDescription,
        actionTitle: .Shopping.ErrorCardButtonText
    )

    let highlightsCardViewModel = HighlightsCardViewModel(
        footerTitle: .Shopping.HighlightsCardFooterText,
        footerActionTitle: .Shopping.HighlightsCardFooterButtonText
    )

    let settingsCardViewModel = FakespotSettingsCardViewModel(
        cardA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.card,
        showProductsLabelTitle: .Shopping.SettingsCardRecommendedProductsLabel,
        showProductsLabelTitleA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.productsLabel,
        turnOffButtonTitle: .Shopping.SettingsCardTurnOffButton,
        turnOffButtonTitleA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.turnOffButton,
        recommendedProductsSwitchA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.recommendedProductsSwitch
    )

    let adjustRatingViewModel = AdjustRatingViewModel(
        title: .Shopping.AdjustedRatingTitle,
        description: .Shopping.AdjustedRatingDescription,
        titleA11yId: AccessibilityIdentifiers.Shopping.AdjustRating.title,
        cardA11yId: AccessibilityIdentifiers.Shopping.AdjustRating.card,
        descriptionA11yId: AccessibilityIdentifiers.Shopping.AdjustRating.description,
        rating: 3.5
    )

    let noAnalysisCardViewModel = NoAnalysisCardViewModel()

    init(shoppingProduct: ShoppingProduct) {
        self.shoppingProduct = shoppingProduct
    }

    func fetchData() async {
        state = .loading
        do {
            state = try await .loaded(shoppingProduct.fetchProductAnalysisData())
        } catch {
            state = .error(error)
        }
    }
}
