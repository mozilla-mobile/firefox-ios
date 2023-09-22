// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

class FakespotViewModel {
    enum ViewState {
        case loading
        case onboarding
        case loaded(ProductAnalysisData?)
        case error(Error)

        fileprivate var viewElements: [ViewElement] {
            switch self {
            case .loading:
                return [.loadingView]
            case let .loaded(product):
                if product?.cannotBeAnalyzedCardVisible == true {
                    return [
                        .messageCard(.productCannotBeAnalyzed),
                        .qualityDeterminationCard,
                        .settingsCard
                    ]
                } else if product?.notEnoughReviewsCardVisible == true {
                    return [
                        .messageCard(.notEnoughReviews),
                        .qualityDeterminationCard,
                        .settingsCard
                    ]
                } else {
                    return [
                        ViewElement.reliabilityCard,
                        .adjustRatingCard,
                        .highlightsCard,
                        .qualityDeterminationCard,
                        .settingsCard
                    ]
                }
            case let .error(error):
                let baseElements = [ViewElement.qualityDeterminationCard, .settingsCard]
                if let error = error as NSError?, error.domain == NSURLErrorDomain, error.code == -1009 {
                    return [.messageCard(.noConnectionError)] + baseElements
                } else {
                    return [.messageCard(.genericError)] + baseElements
                }
            case .onboarding:
                return [.onboarding]
            }
        }

        fileprivate var productData: ProductAnalysisData? {
            switch self {
            case .loading, .error, .onboarding: return nil
            case .loaded(let data): return data
            }
        }
    }

    enum ViewElement {
        case loadingView
        case onboarding
        case reliabilityCard
        case adjustRatingCard
        case highlightsCard
        case qualityDeterminationCard
        case settingsCard
        case noAnalysisCard
        case messageCard(MessageType)
        enum MessageType {
            case genericError
            case productCannotBeAnalyzed
            case noConnectionError
            case notEnoughReviews
        }
    }

    private(set) var state: ViewState = .loading {
        didSet {
            onStateChange?()
        }
    }
    let shoppingProduct: ShoppingProduct
    var onStateChange: (() -> Void)?

    var viewElements: [ViewElement] {
        guard isOptedIn else { return [.onboarding] }

        return state.viewElements
    }

    private let prefs: Prefs
    private var isOptedIn: Bool {
        return prefs.boolForKey(PrefsKeys.Shopping2023OptIn) ?? false
    }

    var reliabilityCardViewModel: FakespotReliabilityCardViewModel? {
        guard let grade = state.productData?.grade else { return nil }

        return FakespotReliabilityCardViewModel(grade: grade)
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

    let doesNotAnalyzeReviewsViewModel = FakespotMessageCardViewModel(
        type: .info,
        title: .Shopping.InfoCardFakespotDoesNotAnalyzeReviewsTitle,
        description: .Shopping.InfoCardFakespotDoesNotAnalyzeReviewsDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.DoesNotAnalyzeReviewsInfoCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.DoesNotAnalyzeReviewsInfoCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.DoesNotAnalyzeReviewsInfoCard.description
    )

    let notEnoughReviewsViewModel = FakespotMessageCardViewModel(
        type: .info,
        title: .Shopping.InfoCardNotEnoughReviewsTitle,
        description: .Shopping.InfoCardNotEnoughReviewsDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.NotEnoughReviewsInfoCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.NotEnoughReviewsInfoCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.NotEnoughReviewsInfoCard.description
    )

    let settingsCardViewModel = FakespotSettingsCardViewModel()
    let noAnalysisCardViewModel = FakespotNoAnalysisCardViewModel()
    let reviewQualityCardViewModel = FakespotReviewQualityCardViewModel()
    var optInCardViewModel = FakespotOptInCardViewModel()

    init(shoppingProduct: ShoppingProduct,
         profile: Profile = AppContainer.shared.resolve()) {
        self.shoppingProduct = shoppingProduct
        optInCardViewModel.productSitename = shoppingProduct.product?.sitename
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
