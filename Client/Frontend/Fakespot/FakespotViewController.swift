// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared

class FakespotViewController:
    UIViewController,
    Themeable,
    Notifiable,
    UIAdaptivePresentationControllerDelegate,
    UISheetPresentationControllerDelegate {
    private struct UX {
        static let headerTopSpacing: CGFloat = 22
        static let headerHorizontalSpacing: CGFloat = 18
        static let titleCloseSpacing: CGFloat = 16
        static let titleLabelFontSize: CGFloat = 17
        static let titleStackSpacing: CGFloat = 8
        static let betaLabelFontSize: CGFloat = 15
        static let betaBorderWidth: CGFloat = 2
        static let betaBorderWidthA11ySize: CGFloat = 4
        static let betaCornerRadius: CGFloat = 8
        static let betaHorizontalSpace: CGFloat = 6
        static let betaVerticalSpace: CGFloat = 4
        static let closeButtonWidthHeight: CGFloat = 30
        static let scrollViewTopSpacing: CGFloat = 12
        static let scrollContentTopPadding: CGFloat = 16
        static let scrollContentBottomPadding: CGFloat = 40
        static let scrollContentHorizontalPadding: CGFloat = 16
        static let scrollContentStackSpacing: CGFloat = 16
    }
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    private let viewModel: FakespotViewModel
    weak var delegate: FakespotViewControllerDelegate?

    private lazy var scrollView: UIScrollView = .build()

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.scrollContentStackSpacing
    }

    private lazy var headerView: UIView = .build()

    private lazy var titleLabel: UILabel = .build { label in
        label.text = .Shopping.SheetHeaderTitle
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline,
                                                            size: UX.titleLabelFontSize,
                                                            weight: .semibold)
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
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .subheadline,
                                                            size: UX.betaLabelFontSize)
        label.textAlignment = .center
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.sheetHeaderBetaLabel
    }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
        button.accessibilityLabel = .CloseButtonTitle
        button.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.sheetCloseButton
    }

    // MARK: - Initializers
    init(
        viewModel: FakespotViewModel,
        notificationCenter: NotificationProtocol = NotificationCenter.default,
        themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.viewModel = viewModel
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)

        viewModel.onStateChange = { [weak self] in
            ensureMainThread {
                self?.updateContent()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup & lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        sheetPresentationController?.delegate = self

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])

        setupView()
        listenForThemeChange(view)
        viewModel.fetchProductIfOptedIn()
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        notificationCenter.post(name: .FakespotViewControllerDidAppear)
        viewModel.recordBottomSheetDisplayed(presentationController)
        updateModalA11y()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        notificationCenter.post(name: .FakespotViewControllerDidDismiss)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        viewModel.isSwiping = true
    }

    func applyTheme() {
        let theme = themeManager.currentTheme

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
        view.addSubviews(headerView, scrollView)

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

            titleStackView.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleStackView.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor,
                                                     constant: -UX.titleCloseSpacing),
            titleStackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.trailingAnchor),
            closeButton.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),

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
        availableTitleStackWidth -= UX.closeButtonWidthHeight + UX.titleCloseSpacing // remove close button and spacing
        let titleTextWidth = FakespotUtils.widthOfString(titleLabelText, usingFont: titleLabel.font)

        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        let betaLabelWidth = FakespotUtils.widthOfString(betaLabelText, usingFont: betaLabel.font)
        let betaViewWidth = betaLabelWidth + UX.betaHorizontalSpace * 2
        let maxTitleWidth = availableTitleStackWidth - betaViewWidth - UX.titleStackSpacing

        betaView.layer.borderWidth = contentSizeCategory.isAccessibilityCategory ? UX.betaBorderWidthA11ySize : UX.betaBorderWidth

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

    private func createContentView(viewElement: FakespotViewModel.ViewElement) -> UIView? {
        switch viewElement {
        case .loadingView:
            let view: FakespotLoadingView = .build()
            return view
        case .onboarding:
            let view: FakespotOptInCardView = .build()
            viewModel.optInCardViewModel.dismissViewController = { [weak self] action in
                guard let self = self else { return }
                self.delegate?.fakespotControllerDidDismiss(animated: true)
                guard let action else { return }
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
            guard let cardViewModel = viewModel.highlightsCardViewModel else { return nil }
            let view: FakespotHighlightsCardView = .build()
            view.configure(cardViewModel)
            return view

        case .qualityDeterminationCard:
            let reviewQualityCardView: FakespotReviewQualityCardView = .build()
            viewModel.reviewQualityCardViewModel.dismissViewController = { [weak self] in
                guard let self = self else { return }
                self.delegate?.fakespotControllerDidDismiss(animated: true)
            }
            reviewQualityCardView.configure(viewModel.reviewQualityCardViewModel)
            return reviewQualityCardView

        case .settingsCard:
            let view: FakespotSettingsCardView = .build()
            view.configure(viewModel.settingsCardViewModel)
            viewModel.settingsCardViewModel.dismissViewController = { [weak self] action in
                guard let self = self else { return }
                self.delegate?.fakespotControllerDidDismiss(animated: true)
                guard let action else { return }
                viewModel.recordDismissTelemetry(by: action)
            }
            return view

        case .noAnalysisCard:
             let view: FakespotNoAnalysisCardView = .build()
             viewModel.noAnalysisCardViewModel.onTapStartAnalysis = { [weak view, weak self] in
                 view?.updateLayoutForInProgress()
                 self?.onNeedsAnalysisTap()
             }
             view.configure(viewModel.noAnalysisCardViewModel)
             return view

        case .progressAnalysisCard:
             let view: FakespotNoAnalysisCardView = .build()
             view.configure(viewModel.noAnalysisCardViewModel)
             view.updateLayoutForInProgress()
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
                TelemetryWrapper.recordEvent(category: .action, method: .view, object: .shoppingSurfaceStaleAnalysisShown)
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
        delegate?.fakespotControllerDidDismiss(animated: true)
        viewModel.recordDismissTelemetry(by: .closeButton)
    }

    deinit {
        viewModel.onViewControllerDeinit()
    }

    private func updateModalA11y() {
        var currentDetent: UISheetPresentationController.Detent.Identifier? = viewModel.getCurrentDetent(for: sheetPresentationController)

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
        delegate?.fakespotControllerDidDismiss(animated: true)
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
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        updateModalA11y()
    }
}
