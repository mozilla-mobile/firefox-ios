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
        case loaded(ProductState)
        case error(Error)

        fileprivate var productData: ProductAnalysisResponse? {
            switch self {
            case .loading, .error, .onboarding: return nil
            case .loaded(let productState): return productState.product
            }
        }
    }

    fileprivate func viewElements(for viewState: ViewState) -> [ViewElement] {
        switch viewState {
        case .loading:
            return [.loadingView]
        case .loaded(let productState):
            guard let product = productState.product else {
                return [
                    .messageCard(.genericError),
                    .qualityDeterminationCard,
                    .settingsCard
                ]
            }

            let minRating = product.adjustedRating ?? 0
            let productAdCard = productState
                .productAds
                .sorted(by: { $0.adjustedRating > $1.adjustedRating })
                .first(where: { $0.adjustedRating >= minRating }) // Choosing the product with the same or better rating to display
                .map(ViewElement.productAdCard)

            if product.grade == nil {
                Self.recordNoReviewReliabilityAvailableTelemetry()
            }

            if product.infoComingSoonCardVisible && shoppingProduct.isProductBackInStockFeatureEnabled {
                return [
                    .messageCard(.infoComingSoonCard),
                    .qualityDeterminationCard,
                    .settingsCard
                ]
            } else if product.reportProductInStockCardVisible && shoppingProduct.isProductBackInStockFeatureEnabled {
                return [
                    .messageCard(.reportProductInStock),
                    .qualityDeterminationCard,
                    .settingsCard
                ]
            } else if product.productNotSupportedCardVisible {
                return [
                    .messageCard(.productNotSupported),
                    .qualityDeterminationCard,
                    .settingsCard
                ]
            } else if product.notAnalyzedCardVisible {
                // Don't show not analyzed message card if analysis is in progress
                var cards: [ViewElement] = []

                if productState.analysisStatus?.isAnalyzing == true {
                    cards.append(.messageCard(.analysisInProgress))
                } else {
                    cards.append(.noAnalysisCard)
                }

                cards += [
                    .qualityDeterminationCard,
                    .settingsCard
                ]
                return cards
            } else if product.notEnoughReviewsCardVisible {
                var cards: [ViewElement] = []

                if productState.analyzeCount > 0 {
                    cards.append(.messageCard(.notEnoughReviews))
                } else {
                    if productState.analysisStatus?.isAnalyzing == true {
                        cards.append(.messageCard(.analysisInProgress))
                    } else {
                        cards.append(.noAnalysisCard)
                    }
                }

                cards += [
                    .qualityDeterminationCard,
                    .settingsCard
                ]
                return cards
            } else if product.needsAnalysisCardVisible {
                // Don't show needs analysis message card if analysis is in progress
                var cards: [ViewElement] = []

                if productState.analysisStatus?.isAnalyzing == true {
                    cards.append(.messageCard(.analysisInProgress))
                } else {
                    cards.append(.messageCard(.needsAnalysis))
                }

                cards += [
                    .reliabilityCard,
                    .adjustRatingCard,
                    .highlightsCard,
                    .qualityDeterminationCard,
                    productAdCard,
                    .settingsCard
                ].compactMap { $0 }

                return cards
            } else {
                return [
                    .reliabilityCard,
                    .adjustRatingCard,
                    .highlightsCard,
                    .qualityDeterminationCard,
                    productAdCard,
                    .settingsCard
                ].compactMap { $0 }
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

    enum ViewElement {
        case loadingView
        case onboarding
        case reliabilityCard
        case adjustRatingCard
        case highlightsCard
        case qualityDeterminationCard
        case settingsCard
        case noAnalysisCard
        case productAdCard(ProductAdsResponse)
        case messageCard(MessageType)
        enum MessageType {
            case genericError
            case productNotSupported
            case noConnectionError
            case notEnoughReviews
            case needsAnalysis
            case analysisInProgress
            case reportProductInStock
            case infoComingSoonCard
        }
    }

    private(set) var state: ViewState = .loading {
        didSet {
            onStateChange?()
        }
    }

    let shoppingProduct: ShoppingProduct
    var onStateChange: (() -> Void)?
    var isSwiping = false
    var isViewIntersected = false

    private var fetchProductTask: Task<Void, Never>?
    private var observeProductTask: Task<Void, Never>?

    var viewElements: [ViewElement] {
        guard isOptedIn else { return [.onboarding] }

        return viewElements(for: state)
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
        guard let highlights = state.productData?.highlights, !highlights.items.isEmpty else { return nil }
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

    let notSupportedProductViewModel = FakespotMessageCardViewModel(
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
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.AnalysisProgressInfoCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.AnalysisProgressInfoCard.title
    )

    lazy var reportProductInStockViewModel = FakespotMessageCardViewModel(
        type: .info,
        title: .Shopping.InfoCardProductNotInStockTitle,
        description: .Shopping.InfoCardProductNotInStockDescription,
        primaryActionText: .Shopping.InfoCardProductNotInStockPrimaryAction,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.ReportProductInStockCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.ReportProductInStockCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.ReportProductInStockCard.description,
        a11yPrimaryActionIdentifier: AccessibilityIdentifiers.Shopping.ReportProductInStockCard.primaryAction
    )

    lazy var reportingProductFeedbackViewModel = FakespotMessageCardViewModel(
        type: .info,
        title: .Shopping.InfoCardReportSubmittedByCurrentUserTitle,
        description: .Shopping.InfoCardReportSubmittedByCurrentUserDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.ReportingProductFeedbackCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.ReportingProductFeedbackCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.ReportingProductFeedbackCard.description
    )

    lazy var infoComingSoonCardViewModel = FakespotMessageCardViewModel(
        type: .info,
        title: .Shopping.InfoCardInfoComingSoonTitle,
        description: .Shopping.InfoCardInfoComingSoonDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.InfoComingSoonCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.InfoComingSoonCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.InfoComingSoonCard.description
    )

    let settingsCardViewModel = FakespotSettingsCardViewModel()
    var noAnalysisCardViewModel = FakespotNoAnalysisCardViewModel()
    let reviewQualityCardViewModel = FakespotReviewQualityCardViewModel()
    var optInCardViewModel = FakespotOptInCardViewModel()

    private var analyzeCount = 0

    init(shoppingProduct: ShoppingProduct,
         profile: Profile = AppContainer.shared.resolve()) {
        self.shoppingProduct = shoppingProduct
        optInCardViewModel.productSitename = shoppingProduct.product?.sitename
        optInCardViewModel.supportedTLDWebsites = shoppingProduct.supportedTLDWebsites
        reviewQualityCardViewModel.productSitename = shoppingProduct.product?.sitename
        self.prefs = profile.prefs
    }

    func fetchProductIfOptedIn() {
        if isOptedIn {
            fetchProductTask = Task { @MainActor [weak self] in
                guard let self else { return }
                await self.fetchProductAnalysis()
                do {
                    // A product might be already in analysis status so we listen for progress until it's completed, then fetch new information
                    for try await status in self.observeProductAnalysisStatus() where status.isAnalyzing == false {
                        await self.fetchProductAnalysis(showLoading: false)
                    }
                } catch {
                    if case .loaded(let productState) = state {
                        // Restore the previous state in case of a failure
                        state = .loaded(
                            ProductState(
                                product: productState.product,
                                productAds: productState.productAds,
                                analysisStatus: nil,
                                analyzeCount: analyzeCount
                            )
                        )
                    }
                }
            }
        }
    }

    func triggerProductAnalysis() {
        observeProductTask = Task { @MainActor [weak self] in
            await self?.triggerProductAnalyze()
        }
    }

    struct ProductState {
        let product: ProductAnalysisResponse?
        let productAds: [ProductAdsResponse]
        let analysisStatus: AnalysisStatus?
        let analyzeCount: Int
    }

    func fetchProductAnalysis(showLoading: Bool = true) async {
        if showLoading { state = .loading }
        do {
            let product = try await shoppingProduct.fetchProductAnalysisData()
            let productAds: [ProductAdsResponse] = if shoppingProduct.isProductAdsFeatureEnabled {
                await shoppingProduct.fetchProductAdsData()
            } else {
                []
            }
            let needsAnalysis = product?.needsAnalysis ?? false
            let analysis: AnalysisStatus? = needsAnalysis ? try? await shoppingProduct.getProductAnalysisStatus()?.status : nil
            state = .loaded(
                ProductState(
                    product: product,
                    productAds: productAds,
                    analysisStatus: analysis,
                    analyzeCount: analyzeCount
                )
            )
        } catch {
            state = .error(error)
        }
    }

    private func triggerProductAnalyze() async {
        analyzeCount += 1
        let status = try? await shoppingProduct.triggerProductAnalyze()
        guard status?.isAnalyzing == true else {
            await fetchProductAnalysis()
            return
        }

        if case .loaded(let productState) = state {
            // update the state to in progress so UI is updated
            state = .loaded(
                ProductState(
                    product: productState.product,
                    productAds: productState.productAds,
                    analysisStatus: status,
                    analyzeCount: analyzeCount
                )
            )
        }

        do {
            // Listen for analysis status until it's completed, then fetch new information
            for try await status in observeProductAnalysisStatus() where status.isAnalyzing == false {
                await fetchProductAnalysis()
            }
        } catch {
            // Sometimes we get an error that product is not found in analysis so we fetch new information
            await fetchProductAnalysis()
        }
    }

    func reportProductBackInStock() {
        recordTelemetry(for: .messageCard(.reportProductInStock))
        Task {
            _ = try? await shoppingProduct.reportProductBackInStock()
        }
    }

    private func observeProductAnalysisStatus() -> AsyncThrowingStream<AnalysisStatus, Error> {
        AsyncThrowingStream<AnalysisStatus, Error> { continuation in
            Task {
                do {
                    var sleepDuration: UInt64 = NSEC_PER_SEC * 30

                    while true {
                        let result = try await shoppingProduct.getProductAnalysisStatus()
                        guard let result else {
                            continuation.finish()
                            break
                        }
                        continuation.yield(result.status)
                        guard result.status.isAnalyzing == true else {
                            continuation.finish()
                            break
                        }

                        // Sleep for the current duration
                        try await Task.sleep(nanoseconds: sleepDuration)

                        // Decrease the sleep duration by 10 seconds (NSEC_PER_SEC * 10) on each iteration.
                        if sleepDuration > NSEC_PER_SEC * 10 {
                            sleepDuration -= NSEC_PER_SEC * 10
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func onViewControllerDeinit() {
        fetchProductTask?.cancel()
        observeProductTask?.cancel()
    }

    func getCurrentDetent(for presentedController: UIPresentationController?) -> UISheetPresentationController.Detent.Identifier? {
        guard let sheetController = presentedController as? UISheetPresentationController else { return nil }
        return sheetController.selectedDetentIdentifier
    }

    // MARK: - Telemetry
    private static func recordNoReviewReliabilityAvailableTelemetry() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .navigate,
            object: .shoppingBottomSheet
        )
    }

    func recordDismissTelemetry(by action: TelemetryWrapper.EventExtraKey.Shopping) {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .close,
            object: .shoppingBottomSheet,
            extras: [TelemetryWrapper.ExtraKey.action.rawValue: action.rawValue]
        )
    }

    func recordTelemetry(for viewElement: ViewElement) {
        switch viewElement {
        case .messageCard(.needsAnalysis):
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .tap,
                object: .shoppingNeedsAnalysisCardViewPrimaryButton
            )
        case .messageCard(.reportProductInStock):
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .tap,
                object: .shoppingProductBackInStockButton
            )
        default: break
        }
    }

    func recordBottomSheetDisplayed(_ presentedController: UIPresentationController?) {
        let currentDetent = getCurrentDetent(for: presentedController)
        let state: TelemetryWrapper.EventExtraKey.Shopping = currentDetent == .large ? .fullView : .halfView
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingBottomSheet,
            extras: [TelemetryWrapper.ExtraKey.size.rawValue: state.rawValue]
        )
    }
}
