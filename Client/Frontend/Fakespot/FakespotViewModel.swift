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
        case loaded(ProductAnalysisData?, AnalysisStatus?)
        case error(Error)

        fileprivate var viewElements: [ViewElement] {
            switch self {
            case .loading:
                return [.loadingView]
            case let .loaded(product, analysisStatus):
                guard let product else {
                    return [
                        .messageCard(.genericError),
                        .qualityDeterminationCard,
                        .settingsCard
                    ]
                }

                if product.cannotBeAnalyzedCardVisible {
                    return [
                        .messageCard(.productCannotBeAnalyzed),
                        .qualityDeterminationCard,
                        .settingsCard
                    ]
                } else if product.notAnalyzedCardVisible {
                    return [
                        .noAnalysisCard,
                        .qualityDeterminationCard,
                        .settingsCard
                    ]
                } else if product.notEnoughReviewsCardVisible {
                    return [
                        .messageCard(.notEnoughReviews),
                        .qualityDeterminationCard,
                        .settingsCard
                    ]
                } else if product.needsAnalysisCardVisible {
                    // Don't show needs analysis message card if analysis is in progress
                    var cards: [ViewElement] = []

                    if analysisStatus != .inProgress && analysisStatus != .pending {
                        cards.append(.messageCard(.needsAnalysis))
                    }

                    cards += [
                        .reliabilityCard,
                        .adjustRatingCard,
                        .highlightsCard,
                        .qualityDeterminationCard,
                        .settingsCard
                    ]

                    return cards
                } else {
                    return [
                        .reliabilityCard,
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
            case .loaded(let data, _): return data
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
            case needsAnalysis
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
        return FakespotHighlightsCardViewModel(highlights: highlights.items)
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

    var needsAnalysisViewModel = FakespotMessageCardViewModel(
        type: .infoTransparent,
        title: .Shopping.InfoCardNeedsAnalysisTitle,
        primaryActionText: .Shopping.InfoCardNeedsAnalysisPrimaryAction,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.NeedsAnalysisInfoCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.NeedsAnalysisInfoCard.title,
        a11yPrimaryActionIdentifier: AccessibilityIdentifiers.Shopping.NeedsAnalysisInfoCard.primaryAction
    )

    let analysisProgressViewModel = FakespotMessageCardViewModel(
        type: .infoLoading,
        title: .Shopping.InfoCardProgressAnalysisTitle,
        description: .Shopping.InfoCardProgressAnalysisDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.AnalysisProgressInfoCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.AnalysisProgressInfoCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.AnalysisProgressInfoCard.description
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
            async let product = try await shoppingProduct.fetchProductAnalysisData()
            async let analysis = try? await shoppingProduct.getProductAnalysisStatus()?.status
            state = try await .loaded(product, analysis)
        } catch {
            state = .error(error)
        }
    }

    @Published var analysisStatus: AnalysisStatus?

    func triggerProductAnalyze() async {
        analysisStatus = try? await shoppingProduct.triggerProductAnalyze()
        try? await getProductAnalysisStatus()
        await fetchData()
    }

    func getProductAnalysisStatus() async throws {
        var sleepDuration: UInt64 = NSEC_PER_SEC * 30

        while true {
            let result = try await shoppingProduct.getProductAnalysisStatus()
            analysisStatus = result?.status
            guard result?.status == .pending ||  result?.status == .inProgress else {
                analysisStatus = nil
                break
            }

            // Sleep for the current duration
            try await Task.sleep(nanoseconds: sleepDuration)

            // Decrease the sleep duration by 10 seconds (NSEC_PER_SEC * 10) on each iteration.
            if sleepDuration > NSEC_PER_SEC * 10 {
                sleepDuration -= NSEC_PER_SEC * 10
            }
        }
    }
}
