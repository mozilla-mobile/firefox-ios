// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

class FakespotViewModel: ObservableObject {
    enum ViewState {
        case loading
        case loaded(ProductAnalysisData?)
        case error(Error)

        var viewElements: [ViewElement] {
            var elements: [ViewElement] = []

            switch self {
            case .loading:
                elements = [.loadingView]

            case .loaded(let data):
                elements = [.reliabilityCard, .adjustRatingCard]

                if data?.highlights != nil {
                    elements.append(.highlightsCard)
                }

//                elements.append(.qualityDeterminationCard)
                elements.append(.settingsCard)

            case .error(let error):
                // add error card
                elements = [.settingsCard] // [.qualityDeterminationCard, .settingsCard]
            }

            return elements
        }
    }

    enum ViewElement {
        case loadingView
//        case onboarding
        case reliabilityCard
        case adjustRatingCard
        case highlightsCard
//        case qualityDeterminationCard
        case settingsCard
        case noAnalysisCard
        case messageCard
    }

    private(set) var state: ViewState = .loading {
        didSet {
            stateChangeClosure?()
        }
    }
    let shoppingProduct: ShoppingProduct
    var stateChangeClosure: (() -> Void)?

    var viewElements: [ViewElement] {
//        guard isOptedIn else { return [.onboarding] }

        return state.viewElements
    }

    private let prefs: Prefs
    private var isOptedIn: Bool {
        return prefs.boolForKey(PrefsKeys.Shopping2023OptIn) ?? false
    }

    let confirmationCardViewModel = FakespotMessageCardViewModel(
        title: .Shopping.ConfirmationCardTitle,
        primaryActionText: .Shopping.ConfirmationCardButtonText,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.title,
        a11yPrimaryActionIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.primaryAction
    )

    let reliabilityCardViewModel = FakespotReliabilityCardViewModel(rating: .gradeA)

    let errorCardViewModel = FakespotErrorCardViewModel(
        title: .Shopping.ErrorCardTitle,
        description: .Shopping.ErrorCardDescription,
        actionTitle: .Shopping.ErrorCardButtonText
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

    let settingsCardViewModel = FakespotSettingsCardViewModel()

    let adjustRatingViewModel = FakespotAdjustRatingViewModel(rating: 3.5)

    let noAnalysisCardViewModel = FakespotNoAnalysisCardViewModel()

    init(shoppingProduct: ShoppingProduct,
         profile: Profile = AppContainer.shared.resolve()) {
        self.shoppingProduct = shoppingProduct
        self.prefs = profile.prefs
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
