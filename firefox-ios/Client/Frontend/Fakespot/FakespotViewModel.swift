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
                // Choosing the product with the same or better rating to display
                .first(where: { $0.adjustedRating >= minRating })
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

    let windowUUID: WindowUUID
    let shoppingProduct: ShoppingProduct
    var onStateChange: (() -> Void)?
    var shouldRecordAdsExposureEvents: (() -> Bool)?
    var isSwiping = false
    var isViewIntersected = false
    // Timer-related properties for handling view visibility
    private var isViewVisible = false
    private var timer: Timer?
    private let tabManager: TabManager

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

    var areAdsEnabled: Bool {
        return prefs.boolForKey(PrefsKeys.Shopping2023EnableAds) ?? true
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

    lazy var confirmationCardViewModel = FakespotMessageCardViewModel(
        windowUUID: windowUUID,
        type: .info,
        title: .Shopping.ConfirmationCardTitle,
        primaryActionText: .Shopping.ConfirmationCardButtonText,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.title,
        a11yPrimaryActionIdentifier: AccessibilityIdentifiers.Shopping.ConfirmationCard.primaryAction
    )

    lazy var noConnectionViewModel = FakespotMessageCardViewModel(
        windowUUID: windowUUID,
        type: .warning,
        title: .Shopping.WarningCardCheckNoConnectionTitle,
        description: .Shopping.WarningCardCheckNoConnectionDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.NoConnectionCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.NoConnectionCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.NoConnectionCard.description
    )

    lazy var genericErrorViewModel = FakespotMessageCardViewModel(
        windowUUID: windowUUID,
        type: .info,
        title: .Shopping.InfoCardNoInfoAvailableRightNowTitle,
        description: .Shopping.InfoCardNoInfoAvailableRightNowDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.GenericErrorInfoCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.GenericErrorInfoCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.GenericErrorInfoCard.description
    )

    lazy var notSupportedProductViewModel = FakespotMessageCardViewModel(
        windowUUID: windowUUID,
        type: .info,
        title: .Shopping.InfoCardFakespotDoesNotAnalyzeReviewsTitle,
        description: .Shopping.InfoCardFakespotDoesNotAnalyzeReviewsDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.DoesNotAnalyzeReviewsInfoCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.DoesNotAnalyzeReviewsInfoCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.DoesNotAnalyzeReviewsInfoCard.description
    )

    lazy var notEnoughReviewsViewModel = FakespotMessageCardViewModel(
        windowUUID: windowUUID,
        type: .info,
        title: .Shopping.InfoCardNotEnoughReviewsTitle,
        description: .Shopping.InfoCardNotEnoughReviewsDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.NotEnoughReviewsInfoCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.NotEnoughReviewsInfoCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.NotEnoughReviewsInfoCard.description
    )

    lazy var needsAnalysisViewModel = FakespotMessageCardViewModel(
        windowUUID: windowUUID,
        type: .infoTransparent,
        title: .Shopping.InfoCardNeedsAnalysisTitle,
        primaryActionText: .Shopping.InfoCardNeedsAnalysisPrimaryAction,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.NeedsAnalysisInfoCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.NeedsAnalysisInfoCard.title,
        a11yPrimaryActionIdentifier: AccessibilityIdentifiers.Shopping.NeedsAnalysisInfoCard.primaryAction
    )

    lazy var analysisProgressViewModel = FakespotMessageCardViewModel(
        windowUUID: windowUUID,
        type: .infoLoading,
        title: .Shopping.InfoCardProgressAnalysisTitle,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.AnalysisProgressInfoCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.AnalysisProgressInfoCard.title
    )

    lazy var reportProductInStockViewModel = FakespotMessageCardViewModel(
        windowUUID: windowUUID,
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
        windowUUID: windowUUID,
        type: .info,
        title: .Shopping.InfoCardReportSubmittedByCurrentUserTitle,
        description: .Shopping.InfoCardReportSubmittedByCurrentUserDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.ReportingProductFeedbackCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.ReportingProductFeedbackCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.ReportingProductFeedbackCard.description
    )

    lazy var infoComingSoonCardViewModel = FakespotMessageCardViewModel(
        windowUUID: windowUUID,
        type: .info,
        title: .Shopping.InfoCardInfoComingSoonTitle,
        description: .Shopping.InfoCardInfoComingSoonDescription,
        a11yCardIdentifier: AccessibilityIdentifiers.Shopping.InfoComingSoonCard.card,
        a11yTitleIdentifier: AccessibilityIdentifiers.Shopping.InfoComingSoonCard.title,
        a11yDescriptionIdentifier: AccessibilityIdentifiers.Shopping.InfoComingSoonCard.description
    )

    let settingsCardViewModel: FakespotSettingsCardViewModel
    var noAnalysisCardViewModel = FakespotNoAnalysisCardViewModel()
    let reviewQualityCardViewModel: FakespotReviewQualityCardViewModel
    var optInCardViewModel: FakespotOptInCardViewModel

    private var analyzeCount = 0

    init(shoppingProduct: ShoppingProduct,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager) {
        self.windowUUID = tabManager.windowUUID
        self.shoppingProduct = shoppingProduct
        self.settingsCardViewModel = FakespotSettingsCardViewModel(tabManager: tabManager)
        self.reviewQualityCardViewModel = FakespotReviewQualityCardViewModel(tabManager: tabManager)
        optInCardViewModel = FakespotOptInCardViewModel(tabManager: tabManager)
        optInCardViewModel.productSitename = shoppingProduct.product?.sitename
        optInCardViewModel.supportedTLDWebsites = shoppingProduct.supportedTLDWebsites
        reviewQualityCardViewModel.productSitename = shoppingProduct.product?.sitename
        self.prefs = profile.prefs
        self.tabManager = tabManager
    }

    func fetchProductIfOptedIn() {
        if isOptedIn {
            fetchProductTask = Task { @MainActor [weak self] in
                guard let self else { return }
                await self.fetchProductAnalysis()
                do {
                    // A product might be already in analysis status so we listen for progress
                    // until it's completed, then fetch new information
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

    func toggleAdsEnabled() {
        prefs.setBool(!areAdsEnabled, forKey: PrefsKeys.Shopping2023EnableAds)
        FakespotUtils().addSettingTelemetry()
        recordAdsToggleTelemetry()
        // Make sure the view updates with the new ads setting
        onStateChange?()
    }

    struct ProductState {
        let product: ProductAnalysisResponse?
        let productAds: [ProductAdsResponse]
        let analysisStatus: AnalysisStatus?
        let analyzeCount: Int
    }

    func fetchProductAnalysis(showLoading: Bool = true) async {
        let windowUUID = tabManager.windowUUID
        if showLoading { state = .loading }
        do {
            let product = try await shoppingProduct.fetchProductAnalysisData()
            let productAds = await loadProductAds(for: product?.productId)

            let needsAnalysis = product?.needsAnalysis ?? false
            // swiftlint:disable line_length
            let analysis: AnalysisStatus? = needsAnalysis ? try? await shoppingProduct.getProductAnalysisStatus()?.status : nil
            // swiftlint:enable line_length
            state = .loaded(
                ProductState(
                    product: product,
                    productAds: productAds,
                    analysisStatus: analysis,
                    analyzeCount: analyzeCount
                )
            )

            guard product != nil,
                  let productId = shoppingProduct.product?.id,
                  shouldRecordAdsExposureEvents?() == true
            else { return }

            if productAds.isEmpty {
                recordSurfaceNoAdsAvailableTelemetry()
            } else {
                recordAdsExposureTelemetry()
                reportAdEvent(eventName: .trustedDealsPlacement, aidvs: productAds.map(\.aid))
            }

            let action = FakespotAction(productId: productId,
                                        windowUUID: windowUUID,
                                        actionType: FakespotActionType.adsExposureEventSendFor)
            store.dispatch(action)
        } catch {
            state = .error(error)
        }
    }

    func loadProductAds(for productId: String?) async -> [ProductAdsResponse] {
        if let productId,
           let cachedAds = await ProductAdsCache.shared.getCachedAds(forKey: productId) {
            return cachedAds
        } else {
            let newAds: [ProductAdsResponse]
            if shoppingProduct.isProductAdsFeatureEnabled, areAdsEnabled {
                newAds = await shoppingProduct.fetchProductAdsData()
            } else {
                newAds = []
            }
            if let productId, !newAds.isEmpty {
                await ProductAdsCache.shared.cacheAds(newAds, forKey: productId)
            }

            return newAds
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
                    let sleepDuration: UInt64 = NSEC_PER_SEC * 3

                    while true {
                        let result = try await shoppingProduct.getProductAnalysisStatus()
                        guard let result else {
                            continuation.finish()
                            break
                        }

                        await MainActor.run {
                            self.analysisProgressViewModel.analysisProgress = result.progress
                            self.analysisProgressViewModel.analysisProgressChanged?(
                                self.analysisProgressViewModel.analysisProgress
                            )
                        }

                        continuation.yield(result.status)
                        guard result.status.isAnalyzing == true else {
                            continuation.finish()
                            break
                        }

                        // Sleep for the current duration
                        try await Task.sleep(nanoseconds: sleepDuration)
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

    func getCurrentDetent(
        for presentedController: UIPresentationController?
    ) -> UISheetPresentationController.Detent.Identifier? {
        guard let sheetController = presentedController as? UISheetPresentationController else { return nil }
        return sheetController.selectedDetentIdentifier
    }

    // MARK: - Timer Handling
    private func startTimer(aid: String) {
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.5,
            repeats: false,
            block: { [weak self] _ in
                self?.timerFired(aid: aid)
            }
        )
        // Add the timer to the common run loop mode
        // to ensure that the timerFired(aid:) method fires even during user interactions such as scrolling,
        // without requiring the user to lift their finger from the screen.
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func timerFired(aid: String) {
        recordSurfaceAdsImpressionTelemetry()
        reportAdEvent(eventName: .trustedDealsImpression, aidvs: [aid])
        stopTimer()

        guard let productId = shoppingProduct.product?.id else { return }
        let action = FakespotAction(productId: productId,
                                    windowUUID: windowUUID,
                                    actionType: FakespotActionType.adsImpressionEventSendFor)
        store.dispatch(action)
        isViewVisible = false
    }

    func handleVisibilityChanges(for view: FakespotAdView, in superview: UIView) {
        let halfViewHeight = view.frame.height / 2
        let intersection = superview.bounds.intersection(view.frame)
        let areViewsIntersected = intersection.height >= halfViewHeight && halfViewHeight > 0

        if areViewsIntersected {
            guard !isViewVisible else { return }
            isViewVisible.toggle()
            if let ad = view.ad { startTimer(aid: ad.aid) }
        } else {
            guard isViewVisible else { return }
            isViewVisible.toggle()
            stopTimer()
        }
    }

    func addTab(url: URL) {
        tabManager.addTabsForURLs([url], zombie: false, shouldSelectTab: true)
    }

    // MARK: - Telemetry

    func reportAdEvent(eventName: FakespotAdsEvent, aidvs: [String]) {
        Task {
            _ = try? await shoppingProduct.reportAdEvent(
                eventName: eventName,
                eventSource: FakespotAdsEvent.eventSource,
                aidvs: aidvs
            )
        }
    }

    public func recordSurfaceAdsClickedTelemetry() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingBottomSheet,
            value: .surfaceAdsClicked
        )
    }

    private static func recordNoReviewReliabilityAvailableTelemetry() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .navigate,
            object: .shoppingBottomSheet
        )
    }

    private func recordSurfaceAdsImpressionTelemetry() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingBottomSheet,
            value: .shoppingAdsImpression
        )
    }

    private func recordSurfaceNoAdsAvailableTelemetry() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingBottomSheet,
            value: .shoppingNoAdsAvailable
        )
    }

    private func recordAdsExposureTelemetry() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .shoppingBottomSheet,
            value: .shoppingAdsExposure
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

    func recordAdsToggleTelemetry() {
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .tap,
            object: .shoppingAdsSettingToggle,
            extras: [
                TelemetryWrapper.ExtraKey.Shopping.adsSettingToggle.rawValue: areAdsEnabled
            ]
        )
    }
}
