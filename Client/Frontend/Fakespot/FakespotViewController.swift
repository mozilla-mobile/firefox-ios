// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared

class FakespotViewController: UIViewController, Themeable, UIAdaptivePresentationControllerDelegate {
    private struct UX {
        static let headerTopSpacing: CGFloat = 22
        static let headerHorizontalSpacing: CGFloat = 18
        static let titleCloseSpacing: CGFloat = 16
        static let titleLabelFontSize: CGFloat = 17
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
    }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage(named: StandardImageIdentifiers.ExtraLarge.crossCircleFill), for: .normal)
        button.addTarget(self, action: #selector(self.closeTapped), for: .touchUpInside)
        button.accessibilityLabel = .CloseButtonTitle
    }

    private lazy var errorCardView: FakespotMessageCardView = .build()
    private lazy var confirmationCardView: FakespotMessageCardView = .build()
    private lazy var reliabilityCardView: FakespotReliabilityCardView = .build()
    private lazy var highlightsCardView: FakespotHighlightsCardView = .build()
    private lazy var settingsCardView: FakespotSettingsCardView = .build()
    private lazy var loadingView: FakespotLoadingView = .build()
    private lazy var noAnalysisCardView: NoAnalysisCardView = .build()
    private lazy var adjustRatingView: AdjustRatingView = .build()
    private lazy var reviewQualityCardView: FaekspotReviewQualityCardView = .build()

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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup & lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        setupView()
        listenForThemeChange(view)
        sendTelemetryOnAppear()

        confirmationCardView.configure(viewModel.confirmationCardViewModel)
        reliabilityCardView.configure(viewModel.reliabilityCardViewModel)
        errorCardView.configure(viewModel.errorCardViewModel)
        highlightsCardView.configure(viewModel.highlightsCardViewModel)
        settingsCardView.configure(viewModel.settingsCardViewModel)
        adjustRatingView.configure(viewModel.adjustRatingViewModel)
        noAnalysisCardView.configure(viewModel.noAnalysisCardViewModel)
        reviewQualityCardView.configure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyTheme()
        loadingView.animate()
        Task {
            await viewModel.fetchData()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if presentingViewController == nil {
            recordTelemetry()
        }
    }

    func applyTheme() {
        let theme = themeManager.currentTheme

        view.backgroundColor = theme.colors.layer1
        titleLabel.textColor = theme.colors.textPrimary

        errorCardView.applyTheme(theme: theme)
        confirmationCardView.applyTheme(theme: theme)
        reliabilityCardView.applyTheme(theme: theme)
        highlightsCardView.applyTheme(theme: theme)
        settingsCardView.applyTheme(theme: theme)
        noAnalysisCardView.applyTheme(theme: theme)
        loadingView.applyTheme(theme: theme)
        adjustRatingView.applyTheme(theme: theme)
        reviewQualityCardView.applyTheme(theme: theme)
    }

    private func setupView() {
        headerView.addSubviews(titleLabel, closeButton)
        view.addSubviews(headerView, scrollView)
        contentStackView.addArrangedSubview(reliabilityCardView)
        contentStackView.addArrangedSubview(adjustRatingView)
        contentStackView.addArrangedSubview(highlightsCardView)
        contentStackView.addArrangedSubview(confirmationCardView)
        contentStackView.addArrangedSubview(errorCardView)
        contentStackView.addArrangedSubview(settingsCardView)
        contentStackView.addArrangedSubview(noAnalysisCardView)
        contentStackView.addArrangedSubview(reviewQualityCardView)
        contentStackView.addArrangedSubview(loadingView)
        scrollView.addSubview(contentStackView)

        let titleCenterYConstraint = titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor)

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

            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -UX.titleCloseSpacing),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            titleCenterYConstraint,

            closeButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.trailingAnchor),
            closeButton.bottomAnchor.constraint(lessThanOrEqualTo: headerView.bottomAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight),
            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonWidthHeight)
        ])

        _ = titleCenterYConstraint.priority(.defaultLow)
    }

    private func recordTelemetry() {
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
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.fakespotControllerDidDismiss()
    }
}
