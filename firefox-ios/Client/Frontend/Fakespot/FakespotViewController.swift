// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared
import Redux

class FakespotViewController: UIViewController,
                              Themeable,
                              Notifiable,
                              UIAdaptivePresentationControllerDelegate,
                              UISheetPresentationControllerDelegate,
                              UIScrollViewDelegate,
                              StoreSubscriber {
    typealias SubscriberStateType = BrowserViewControllerState

    private struct UX {
        static let headerTopSpacing: CGFloat = 22
        static let headerHorizontalSpacing: CGFloat = 18
        static let titleCloseSpacing: CGFloat = 16
        static let titleStackSpacing: CGFloat = 8
        static let betaBorderWidth: CGFloat = 2
        static let betaBorderWidthA11ySize: CGFloat = 4
        static let betaCornerRadius: CGFloat = 8
        static let betaHorizontalSpace: CGFloat = 6
        static let betaVerticalSpace: CGFloat = 4
        static let scrollViewTopSpacing: CGFloat = 12
        static let scrollContentTopPadding: CGFloat = 16
        static let scrollContentBottomPadding: CGFloat = 40
        static let scrollContentHorizontalPadding: CGFloat = 16
        static let scrollContentStackSpacing: CGFloat = 16
        static let shadowRadius: CGFloat = 14
        static let shadowOpacity: Float = 1
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let animationDuration: TimeInterval = 0.2
    }
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    private var viewModel: FakespotViewModel
    private let windowUUID: WindowUUID
    var fakespotState: FakespotState

    var currentWindowUUID: UUID? { return windowUUID }

    private var adView: FakespotAdView?

    private lazy var scrollView: UIScrollView = .build()

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.scrollContentStackSpacing
    }

    private lazy var shadowView: UIView = .build { view in
        view.layer.shadowOffset = UX.shadowOffset
        view.layer.shadowRadius = UX.shadowRadius
    }

    private lazy var headerView: UIView = .build()

    private lazy var titleLabel: UILabel = .build { label in
        label.text = .Shopping.SheetHeaderTitle
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.sheetHeaderTitle
        label.accessibilityTraits.insert(.header)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private var titleStackView: UIStackView = .build { stackView in
        stackView.axis = .horizontal
        stackView.spacing = UX.titleStackSpacing
        stackView.alignment = .center
    }

    private lazy var betaView: UIView = .build { view in
        view.layer.borderWidth = UX.betaBorderWidth
        view.layer.cornerRadius = UX.betaCornerRadius
    }

    private lazy var betaLabel: UILabel = .build { label in
        label.text = .Shopping.SheetHeaderBetaTitle
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.textAlignment = .center
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.sheetHeaderBetaLabel
    }

    private lazy var closeButton: CloseButton = .build { view in
        let viewModel = CloseButtonViewModel(
            a11yLabel: .Shopping.CloseButtonAccessibilityLabel,
            a11yIdentifier: AccessibilityIdentifiers.Shopping.sheetCloseButton
        )
        view.configure(viewModel: viewModel)
        view.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
    }

    // MARK: - Initializers
    init(
        windowUUID: WindowUUID,
        viewModel: FakespotViewModel,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.viewModel = viewModel
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        fakespotState = FakespotState(windowUUID: windowUUID)
        super.init(nibName: nil, bundle: nil)
        listenToStateChange()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup & lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        sheetPresentationController?.delegate = self
        scrollView.delegate = self

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])

        setupView()
        listenForThemeChange(view)
        viewModel.fetchProductIfOptedIn()
        subscribeToRedux()
        shouldRecordAdsExposureEvents()
    }

    // MARK: - Redux

    func subscribeToRedux() {
        let uuid = windowUUID
        store.subscribe(self, transform: {
            $0.select({ appState in
                return BrowserViewControllerState(appState: appState, uuid: uuid)
            })
        })
    }

    func unsubscribeFromRedux() {
        store.unsubscribe(self)
    }

    func newState(state: BrowserViewControllerState) {
        fakespotState = state.fakespotState
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        adjustLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewModel.isSwiping = false
        setShadowPath()
        handleAdVisibilityChanges()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        notificationCenter.post(name: .FakespotViewControllerDidAppear, withObject: windowUUID)
        updateModalA11y()

        guard !fakespotState.currentTabUUID.isEmpty,
              fakespotState.sendSurfaceDisplayedTelemetryEvent
        else { return }
        viewModel.recordBottomSheetDisplayed(presentationController)
        let action = FakespotAction(windowUUID: windowUUID,
                                    actionType: FakespotActionType.surfaceDisplayedEventSend)
        store.dispatch(action)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        notificationCenter.post(name: .FakespotViewControllerDidDismiss, withObject: windowUUID)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        viewModel.isSwiping = true
    }

    func update(viewModel: FakespotViewModel, triggerFetch: Bool = true) {
        // Only update the model if the shopping product changed to avoid unnecessary API calls
        guard self.viewModel.shoppingProduct != viewModel.shoppingProduct else {
            handleAdVisibilityChanges()
            return
        }

        self.viewModel = viewModel
        shouldRecordAdsExposureEvents()

        // Sets adView to nil when switching tabs on iPad to prevent retaining references from a previous tab,
        // ensuring accurate ad impression tracking.
        adView = nil
        listenToStateChange()

        guard triggerFetch else { return }
        viewModel.fetchProductIfOptedIn()
    }

    private func shouldRecordAdsExposureEvents() {
        viewModel.shouldRecordAdsExposureEvents = { [weak self] in
            guard let self, let productId = viewModel.shoppingProduct.product?.id else { return false }
            let tabUUID = self.fakespotState.currentTabUUID

            return (self.fakespotState.telemetryState[tabUUID]?.adEvents[productId]?.sendAdExposureEvent ?? true)
        }
    }

    private func handleAdVisibilityChanges() {
        guard let adView,
              !fakespotState.currentTabUUID.isEmpty,
              let productId = viewModel.shoppingProduct.product?.id,
              fakespotState.telemetryState[fakespotState.currentTabUUID]?.adEvents[productId]?.sendAdsImpressionEvent ?? true
        else { return }
        viewModel.handleVisibilityChanges(for: adView, in: scrollView)
    }

    private func setShadowPath() {
        // Calculate the rect for the shadowPath, ensuring it is at the bottom of the view
        let shadowPathRect = CGRect(
            x: 0,
            y: shadowView.bounds.maxY - shadowView.layer.shadowRadius,
            width: shadowView.bounds.width,
            height: shadowView.layer.shadowRadius
        )
        shadowView.layer.shadowPath = UIBezierPath(rect: shadowPathRect).cgPath
    }

    private func listenToStateChange() {
        viewModel.onStateChange = { [weak self] in
            ensureMainThread {
                self?.updateContent()
            }
        }
    }

    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        shadowView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        shadowView.backgroundColor = theme.colors.layer1
        view.backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
        betaLabel.textColor = theme.colors.textSecondary
        betaView.layer.borderColor = theme.colors.actionSecondary.cgColor

        contentStackView.arrangedSubviews.forEach { view in
            guard let view = view as? ThemeApplicable else { return }
            view.applyTheme(theme: theme)
        }
    }

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DynamicFontChanged:
            adjustLayout()
        default: break
        }
    }

    private func setupView() {
        betaView.addSubview(betaLabel)
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(betaView)
        headerView.addSubviews(titleStackView, closeButton)
        view.addSubviews(scrollView, shadowView, headerView)

        scrollView.addSubview(contentStackView)
        updateContent()

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor,
                                                  constant: UX.scrollContentTopPadding),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor,
                                                      constant: UX.scrollContentHorizontalPadding),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor,
                                                     constant: -UX.scrollContentBottomPadding),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor,
                                                       constant: -UX.scrollContentHorizontalPadding),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor,
                                                    constant: -UX.scrollContentHorizontalPadding * 2),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: UX.scrollViewTopSpacing),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.headerTopSpacing),
            headerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                constant: UX.headerHorizontalSpacing),
            headerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                                 constant: -UX.headerHorizontalSpacing),

            shadowView.topAnchor.constraint(equalTo: view.topAnchor),
            shadowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shadowView.bottomAnchor.constraint(equalTo: scrollView.topAnchor),

            titleStackView.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleStackView.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor,
                                                     constant: -UX.titleCloseSpacing),
            titleStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.trailingAnchor),
            closeButton.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor),

            betaLabel.topAnchor.constraint(equalTo: betaView.topAnchor, constant: UX.betaVerticalSpace),
            betaLabel.leadingAnchor.constraint(equalTo: betaView.leadingAnchor, constant: UX.betaHorizontalSpace),
            betaLabel.trailingAnchor.constraint(equalTo: betaView.trailingAnchor, constant: -UX.betaHorizontalSpace),
            betaLabel.bottomAnchor.constraint(equalTo: betaView.bottomAnchor, constant: -UX.betaVerticalSpace),
        ])
    }

    private func adjustLayout() {
        closeButton.isHidden = FakespotUtils().shouldDisplayInSidebar()

        guard let titleLabelText = titleLabel.text, let betaLabelText = betaLabel.text else { return }

        var availableTitleStackWidth = headerView.frame.width
        if availableTitleStackWidth == 0 {
            // calculate the width if auto-layout doesn't have it yet
            availableTitleStackWidth = view.frame.width - UX.headerHorizontalSpacing * 2
        }
        availableTitleStackWidth -= closeButton.frame.width + UX.titleCloseSpacing // remove close button and spacing
        let titleTextWidth = FakespotUtils.widthOfString(titleLabelText, usingFont: titleLabel.font)

        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        let betaLabelWidth = FakespotUtils.widthOfString(betaLabelText, usingFont: betaLabel.font)
        let betaViewWidth = betaLabelWidth + UX.betaHorizontalSpace * 2
        let maxTitleWidth = availableTitleStackWidth - betaViewWidth - UX.titleStackSpacing

        // swiftlint:disable line_length
        betaView.layer.borderWidth = contentSizeCategory.isAccessibilityCategory ? UX.betaBorderWidthA11ySize : UX.betaBorderWidth
        // swiftlint:enable line_length

        if contentSizeCategory.isAccessibilityCategory || titleTextWidth > maxTitleWidth {
            titleStackView.axis = .vertical
            titleStackView.alignment = .leading
        } else {
            titleStackView.axis = .horizontal
            titleStackView.alignment = .center
        }

        titleStackView.setNeedsLayout()
        titleStackView.layoutIfNeeded()
    }

    private func updateContent() {
        contentStackView.removeAllArrangedViews()

        viewModel.viewElements.forEach { element in
            guard let view = createContentView(viewElement: element) else { return }
            contentStackView.addArrangedSubview(view)

            if let loadingView = view as? FakespotLoadingView {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    loadingView.animate()
                }
            }
        }
        applyTheme()
    }

    private func adjustShadowBasedOnIntersection() {
        let shadowViewFrameInSuperview = shadowView.convert(
            shadowView.bounds,
            to: view
        )
        let contentStackViewFrameInSuperview = contentStackView.convert(
            contentStackView.bounds,
            to: view
        )

        if shadowViewFrameInSuperview.intersects(contentStackViewFrameInSuperview) {
            guard !viewModel.isViewIntersected else { return }
            viewModel.isViewIntersected.toggle()
            UIView.animate(withDuration: UX.animationDuration) {
                self.shadowView.layer.shadowOpacity = UX.shadowOpacity
            }
        } else {
            guard viewModel.isViewIntersected else { return }
            viewModel.isViewIntersected.toggle()
            UIView.animate(withDuration: UX.animationDuration) {
                self.shadowView.layer.shadowOpacity = 0
            }
        }
    }

    private func createContentView(viewElement: FakespotViewModel.ViewElement) -> UIView? {
        let windowUUID = windowUUID
        switch viewElement {
        case .loadingView:
            let view: FakespotLoadingView = .build()
            return view
        case .onboarding:
            let view: FakespotOptInCardView = .build()
            viewModel.optInCardViewModel.dismissViewController = { [weak self] dismissPermanently, action in
                if dismissPermanently {
                    self?.triggerDismiss()
                } else {
                    let appearanceAction = FakespotAction(isOpen: false,
                                                          windowUUID: windowUUID,
                                                          actionType: FakespotActionType.setAppearanceTo)
                                                          store.dispatch(appearanceAction)
                }

                guard let self = self, let action else { return }
                viewModel.recordDismissTelemetry(by: action)
            }
            viewModel.optInCardViewModel.onOptIn = { [weak self] in
                guard let self = self else { return }
                self.viewModel.fetchProductIfOptedIn()
            }
            view.configure(viewModel.optInCardViewModel)
            return view

        case .reliabilityCard:
            guard let cardViewModel = viewModel.reliabilityCardViewModel else { return nil }
            let view: FakespotReliabilityCardView = .build()
            view.configure(cardViewModel)
            return view

        case .adjustRatingCard:
            guard let cardViewModel = viewModel.adjustRatingViewModel else { return nil }
            let view: FakespotAdjustRatingView = .build()
            view.configure(cardViewModel)
            return view

        case .highlightsCard:
            guard var cardViewModel = viewModel.highlightsCardViewModel else { return nil }
            cardViewModel.expandState = fakespotState.isHighlightsSectionExpanded ? .expanded : .collapsed
            cardViewModel.onExpandStateChanged = { state in
                let action = FakespotAction(isExpanded: state == .expanded,
                                            windowUUID: windowUUID,
                                            actionType: FakespotActionType.highlightsDidChange)
                store.dispatch(action)
            }
            let view: FakespotHighlightsCardView = .build()
            view.configure(cardViewModel)
            return view

        case .qualityDeterminationCard:
            let reviewQualityCardView: FakespotReviewQualityCardView = .build()
            viewModel.reviewQualityCardViewModel.expandState = fakespotState.isReviewQualityExpanded ? .expanded : .collapsed
            viewModel.reviewQualityCardViewModel.dismissViewController = {
                let action = FakespotAction(isOpen: false,
                                            windowUUID: windowUUID,
                                            actionType: FakespotActionType.setAppearanceTo)
                store.dispatch(action)
            }
            viewModel.reviewQualityCardViewModel.onExpandStateChanged = { state in
                let action = FakespotAction(isExpanded: state == .expanded,
                                            windowUUID: windowUUID,
                                            actionType: FakespotActionType.reviewQualityDidChange)
                store.dispatch(action)
            }
            reviewQualityCardView.configure(viewModel.reviewQualityCardViewModel)

            return reviewQualityCardView

        case .settingsCard:
            let view: FakespotSettingsCardView = .build()
            viewModel.settingsCardViewModel.expandState = fakespotState.isSettingsExpanded ? .expanded : .collapsed
            viewModel.settingsCardViewModel.dismissViewController = { [weak self] dismissPermanently, action in
                guard let self = self, let action else { return }
                if dismissPermanently {
                    self.triggerDismiss()
                } else {
                    let surfanceDisplayedAction = FakespotAction(isExpanded: false,
                                                                 windowUUID: windowUUID,
                                                                 actionType: FakespotActionType.surfaceDisplayedEventSend)
                                                                 store.dispatch(surfanceDisplayedAction)
                }
                viewModel.recordDismissTelemetry(by: action)
            }
            viewModel.settingsCardViewModel.toggleAdsEnabled = { [weak self] in
                self?.viewModel.toggleAdsEnabled()
            }
            viewModel.settingsCardViewModel.onExpandStateChanged = { state in
                let action = FakespotAction(isExpanded: state == .expanded,
                                            windowUUID: windowUUID,
                                            actionType: FakespotActionType.settingsStateDidChange)
                store.dispatch(action)
            }
            view.configure(viewModel.settingsCardViewModel)

            return view

        case .noAnalysisCard:
             let view: FakespotNoAnalysisCardView = .build()
             viewModel.noAnalysisCardViewModel.onTapStartAnalysis = { [weak self] in
                 self?.onNeedsAnalysisTap()
             }
             view.configure(viewModel.noAnalysisCardViewModel)
             return view

        case .productAdCard(let adData):
            guard viewModel.areAdsEnabled else { return nil }
            let view: FakespotAdView = .build()
            var viewModel = FakespotAdViewModel(productAdsData: adData)
            viewModel.onTapProductLink = { [weak self] in
                self?.viewModel.addTab(url: adData.url)
                self?.viewModel.recordSurfaceAdsClickedTelemetry()
                self?.viewModel.reportAdEvent(eventName: .trustedDealsLinkClicked, aidvs: [adData.aid])
                let action = FakespotAction(isOpen: false,
                                            windowUUID: windowUUID,
                                            actionType: FakespotActionType.setAppearanceTo)
                store.dispatch(action)
            }
            view.configure(viewModel)
            adView = view
            return view

        case .messageCard(let messageType):
            switch messageType {
            case .genericError:
                let view: FakespotMessageCardView = .build()
                view.configure(viewModel.genericErrorViewModel)
                return view

            case .noConnectionError:
                let view: FakespotMessageCardView = .build()
                view.configure(viewModel.noConnectionViewModel)
                return view

            case .productNotSupported:
                let view: FakespotMessageCardView = .build()
                view.configure(viewModel.notSupportedProductViewModel)
                return view

            case .notEnoughReviews:
                let view: FakespotMessageCardView = .build()
                view.configure(viewModel.notEnoughReviewsViewModel)
                return view

            case .needsAnalysis:
                let view: FakespotMessageCardView = .build()
                viewModel.needsAnalysisViewModel.primaryAction = { [weak view, weak self] in
                    guard let self else { return }
                    view?.configure(self.viewModel.analysisProgressViewModel)
                    self.onNeedsAnalysisTap()
                    self.viewModel.recordTelemetry(for: .messageCard(.needsAnalysis))
                }
                view.configure(viewModel.needsAnalysisViewModel)
                TelemetryWrapper.recordEvent(
                    category: .action,
                    method: .view,
                    object: .shoppingSurfaceStaleAnalysisShown
                )
                return view

            case .analysisInProgress:
                let view: FakespotMessageCardView = .build()
                view.configure(viewModel.analysisProgressViewModel)
                return view

            case .reportProductInStock:
                let view: FakespotMessageCardView = .build()
                viewModel.reportProductInStockViewModel.primaryAction = { [weak view, weak self] in
                    guard let self else { return }
                    view?.configure(self.viewModel.reportingProductFeedbackViewModel)
                    self.viewModel.reportProductBackInStock()
                }
                view.configure(viewModel.reportProductInStockViewModel)
                return view

            case .infoComingSoonCard:
                let view: FakespotMessageCardView = .build()
                view.configure(viewModel.infoComingSoonCardViewModel)
                return view
            }
        }
    }

    private func onNeedsAnalysisTap() {
        viewModel.triggerProductAnalysis()
    }

    @objc
    private func closeTapped() {
        triggerDismiss()
        viewModel.recordDismissTelemetry(by: .closeButton)
    }

    private func triggerDismiss() {
        let action = FakespotAction(windowUUID: windowUUID,
                                    actionType: FakespotActionType.dismiss)
        store.dispatch(action)
    }

    deinit {
        unsubscribeFromRedux()
        viewModel.onViewControllerDeinit()
    }

    private func updateModalA11y() {
        var currentDetent: UISheetPresentationController.Detent.Identifier? = viewModel.getCurrentDetent(
            for: sheetPresentationController
        )

        if currentDetent == nil,
           let sheetPresentationController,
           let firstDetent = sheetPresentationController.detents.first {
            if firstDetent == .medium() {
                currentDetent = .medium
            } else if firstDetent == .large() {
                currentDetent = .large
            }
        }

        // in iOS 15 modals with a large detent read content underneath the modal in voice over
        // to prevent this we manually turn this off
        view.accessibilityViewIsModal = currentDetent == .large ? true : false
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        triggerDismiss()

        let currentDetent = viewModel.getCurrentDetent(for: presentationController)

        if viewModel.isSwiping || currentDetent == .large {
            viewModel.recordDismissTelemetry(by: .swipingTheSurfaceHandle)
        } else {
            viewModel.recordDismissTelemetry(by: .clickOutside)
        }
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        adjustLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.adjustLayout()
        }, completion: nil)
    }

    // MARK: - UISheetPresentationControllerDelegate
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
        _ sheetPresentationController: UISheetPresentationController
    ) {
        updateModalA11y()
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustShadowBasedOnIntersection()
        handleAdVisibilityChanges()
    }
}
