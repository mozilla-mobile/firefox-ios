// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

class FakespotViewModel {
    enum ViewState {
        case loading
        case loaded(ProductAnalysisData?)
        case error(Error)

        var viewElements: [ViewElement] {
            var elements: [ViewElement] = []

            switch self {
            case .loading:
                elements = [.loadingView]

            case .loaded:
                elements = [.reliabilityCard,
                    .adjustRatingCard,
                    .highlightsCard,
                    .qualityDeterminationCard,
                    .settingsCard]

            case let .error(error):
                let baseElements = [ViewElement.qualityDeterminationCard, .settingsCard]
                if let error = error as NSError?, error.domain == NSURLErrorDomain, error.code == -1009 {
                    return [.noConnectionError] + baseElements
                } else {
                    return [.genericError] + baseElements
                }
            }

            return elements
        }

        var productData: ProductAnalysisData? {
            switch self {
            case .loading, .error: return nil
            case .loaded(let data): return data
            }
        }
    }

    enum ViewElement {
        case loadingView
//        case onboarding // card not created yet (FXIOS-7270)
        case reliabilityCard
        case adjustRatingCard
        case highlightsCard
        case qualityDeterminationCard
        case settingsCard
        case noAnalysisCard
        case genericError
        case noConnectionError
    }

    private(set) var state: ViewState = .loading {
        didSet {
            onStateChange?()
        }
    }
    let shoppingProduct: ShoppingProduct
    var onStateChange: (() -> Void)?

    var viewElements: [ViewElement] {
//        guard isOptedIn else { return [.onboarding] } // card not created yet (FXIOS-7270)

        return state.viewElements
    }

    private let prefs: Prefs
    private var isOptedIn: Bool {
        return prefs.boolForKey(PrefsKeys.Shopping2023OptIn) ?? false
    }

    var reliabilityCardViewModel: FakespotReliabilityCardViewModel? {
        guard let grade = state.productData?.grade,
                let rating = FakespotReliabilityRating(rawValue: grade)
        else { return nil }

        return FakespotReliabilityCardViewModel(rating: rating)
    }

    var highlightsCardViewModel: FakespotHighlightsCardViewModel? {
        guard let highlights = state.productData?.highlights else { return nil }
        return FakespotHighlightsCardViewModel(highlights: highlights)
    }

    var adjustRatingViewModel: FakespotAdjustRatingViewModel? {
        guard let adjustedRating = state.productData?.adjustedRating else { return nil }
        return FakespotAdjustRatingViewModel(rating: adjustedRating)
    }

    let confirmationCardViewModel = FakespotMessageCardViewModel(
        type: .info,
        title: .Shopping.ConfirmationCardTitle,
        primaryActionText: .Shopping.ConfirmationCardButtonText,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.title,
        a11yPrimaryActionIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.primaryAction
    )

    let noConnectionViewModel = FakespotMessageCardViewModel(
        type: .warning,
        title: .Shopping.WarningCardCheckNoConnectionTitle,
        description: .Shopping.WarningCardCheckNoConnectionDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.NoConnectionCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.NoConnectionCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.NoConnectionCard.description
    )

    let genericErrorViewModel = FakespotMessageCardViewModel(
        type: .info,
        title: .Shopping.InfoCardNoInfoAvailableRightNowTitle,
        description: .Shopping.InfoCardNoInfoAvailableRightNowDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.GenericErrorInfoCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.GenericErrorInfoCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.GenericErrorInfoCard.description
    )

    let settingsCardViewModel = FakespotSettingsCardViewModel()
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
