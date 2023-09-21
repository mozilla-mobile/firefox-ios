// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared

class FakespotViewController: UIViewController, Themeable, Notifiable, UIAdaptivePresentationControllerDelegate {
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
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .subheadline,
                                                            size: UX.betaLabelFontSize)
        label.accessibilityIdentifier = AccessibilityIdentifiers.Shopping.sheetHeaderBetaLabel
    }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
        button.accessibilityLabel = .CloseButtonTitle
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

        setupNotifications(forObserver: self,
                           observing: [.DynamicFontChanged])

        setupView()
        listenForThemeChange(view)
        sendTelemetryOnAppear()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()
        Task {
            await viewModel.fetchData()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        notificationCenter.post(name: .FakespotViewControllerDidDismiss, withObject: nil)
    }

    func applyTheme() {
        let theme = themeManager.currentTheme

        view.backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary
        betaLabel.textColor = theme.colors.textPrimary
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
            betaLabel.bottomAnchor.constraint(equalTo: betaView.bottomAnchor, constant: -UX.betaVerticalSpace)
        ])

        adjustLayout()
    }

    private func adjustLayout() {
        let contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        if contentSizeCategory.isAccessibilityCategory {
            titleStackView.axis = .vertical
            titleStackView.alignment = .leading
            betaView.layer.borderWidth = UX.betaBorderWidthA11ySize
        } else {
            titleStackView.axis = .horizontal
            titleStackView.alignment = .center
            betaView.layer.borderWidth = UX.betaBorderWidth
        }
    }

    private func updateContent() {
        contentStackView.removeAllArrangedViews()

        viewModel.viewElements.forEach { element in
            guard let view = createContentView(viewElement: element) else { return }
            contentStackView.addArrangedSubview(view)

            if let loadingView = view as? FakespotLoadingView {
                loadingView.animate()
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
            viewModel.optInCardViewModel.dismissViewController = { [weak self] in
                guard let self = self else { return }
                self.delegate?.fakespotControllerDidDismiss()
            }
            viewModel.optInCardViewModel.onOptIn = { [weak self] in
                guard let self = self else { return }
                Task {
                    await self.viewModel.fetchData()
                }
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
            reviewQualityCardView.configure()
            return reviewQualityCardView

        case .settingsCard:
            let view: FakespotSettingsCardView = .build()
            view.configure(viewModel.settingsCardViewModel)
            viewModel.settingsCardViewModel.dismissViewController = { [weak self] in
                guard let self = self else { return }
                self.delegate?.fakespotControllerDidDismiss()
            }
            return view

        case .noAnalysisCard:
            let view: FakespotNoAnalysisCardView = .build()
            view.configure(viewModel.noAnalysisCardViewModel)
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

            case .productCannotBeAnalyzed:
                let view: FakespotMessageCardView = .build()
                view.configure(viewModel.doesNotAnalyzeReviewsViewModel)
                return view
            }
        }
    }

    private func recordDismissTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .close,
                                     object: .shoppingBottomSheet)
    }

    private func sendTelemetryOnAppear() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .shoppingBottomSheet)
    }

    @objc
    private func closeTapped() {
        delegate?.fakespotControllerDidDismiss()
        recordDismissTelemetry()
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.fakespotControllerDidDismiss()
        recordDismissTelemetry()
    }
}
