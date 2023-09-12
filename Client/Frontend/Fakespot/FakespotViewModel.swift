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

    let confirmationCardViewModel = FakespotMessageCardViewModel(
        type: .info,
        title: .Shopping.ConfirmationCardTitle,
        primaryActionText: .Shopping.ConfirmationCardButtonText,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.title,
        a11yPrimaryActionIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.primaryAction
    )

    let reliabilityCardViewModel = FakespotReliabilityCardViewModel(
        cardA11yId: AccessibilityIdentifiers.Shopping.ReliabilityCard.card,
        title: .Shopping.ReliabilityCardTitle,
        titleA11yId: AccessibilityIdentifiers.Shopping.ReliabilityCard.title,
        rating: .gradeA,
        ratingLetterA11yId: AccessibilityIdentifiers.Shopping.ReliabilityCard.ratingLetter,
        ratingDescriptionA11yId: AccessibilityIdentifiers.Shopping.ReliabilityCard.ratingDescription
    )

    let errorCardViewModel = FakespotMessageCardViewModel(
        type: .error,
        title: .Shopping.ErrorCardTitle,
        description: .Shopping.ErrorCardDescription,
        primaryActionText: .Shopping.ErrorCardButtonText,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.ErrorCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.ErrorCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.ErrorCard.description,
        a11yPrimaryActionIdentifier: AccessibilityIdentifiers.Shopping.ErrorCard.primaryAction
    )

    let highlightsCardViewModel = {
        // Dummy data to show content until we integrate with the API
        let highlights = Highlights(price: ["Great quality that one can expect from Apple.",
                                            "Replacing iPad 5th gen that won't support iOS17, but still wanted to be able to charge all devices with the same lightning cable (especially when traveling).",
                                            "I am very pleased with my decision to save some money and go with the 9th generation iPad."],
                                    quality: ["Threw the box away so can't return it, but would not buy this model again, even at the discounted price."],
                                    competitiveness: ["Please make sure to use some paper like screen protector if you’re using pencil on the screen."])
        return FakespotHighlightsCardViewModel(highlights: highlights)
    }()

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
