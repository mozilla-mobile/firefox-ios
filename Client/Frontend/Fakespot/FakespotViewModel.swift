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

                    if analysisStatus?.isAnalyzing == true {
                        cards.append(.messageCard(.analysisInProgress))
                    } else {
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
            case analysisInProgress
        }
    }

    private(set) var state: ViewState = .loading {
        didSet {
            onStateChange?()
        }
    }

    private(set) var analysisStatus: AnalysisStatus? {
        didSet {
            onAnalysisStatusChange?()
        }
    }

    let shoppingProduct: ShoppingProduct
    var onStateChange: (() -> Void)?
    var isSwiping = false
    var onAnalysisStatusChange: (() -> Void)?

    private var fetchProductTask: Task<Void, Never>?
    private var observeProductTask: Task<Void, Never>?

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

    func fetchProductIfOptedIn() {
        if isOptedIn {
            fetchProductTask = Task { @MainActor [weak self] in
                await self?.fetchProductAnalysis()
                try? await self?.observeProductAnalysisStatus()
            }
        }
    }

    func triggerProductAnalysis() {
        observeProductTask = Task { @MainActor [weak self] in
            await self?.triggerProductAnalyze()
        }
    }

    func fetchProductAnalysis() async {
        state = .loading
        do {
            let product = try await shoppingProduct.fetchProductAnalysisData()
            let needsAnalysis = product?.needsAnalysis ?? false
            let analysis: AnalysisStatus? = needsAnalysis ? try? await shoppingProduct.getProductAnalysisStatus()?.status : nil
            state = .loaded(product, analysis)
        } catch {
            state = .error(error)
        }
    }

    private func triggerProductAnalyze() async {
        analysisStatus = try? await shoppingProduct.triggerProductAnalyze()
        try? await observeProductAnalysisStatus()
        await fetchProductAnalysis()
    }

    private func observeProductAnalysisStatus() async throws {
        var sleepDuration: UInt64 = NSEC_PER_SEC * 30

        while true {
            let result = try await shoppingProduct.getProductAnalysisStatus()
            analysisStatus = result?.status
            guard result?.status.isAnalyzing == true else {
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

    func onViewControllerDeinit() {
        fetchProductTask?.cancel()
        observeProductTask?.cancel()
    }

    @available(iOS 15.0, *)
    func getCurrentDetent(for presentedController: UIPresentationController?) -> UISheetPresentationController.Detent.Identifier? {
        guard let sheetController = presentedController as? UISheetPresentationController else { return nil }
        return sheetController.selectedDetentIdentifier
    }

    // MARK: - Telemetry
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
        default: break
        }
    }

    @available(iOS 15.0, *)
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
