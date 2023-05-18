// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

class OnboardingDefaultSettingsViewController: UIViewController, Themeable {
    private enum UX {
        static let contentStackViewSpacing: CGFloat = 40
        static let textStackViewSpacing: CGFloat = 24

        static let titleFontSize: CGFloat = 20
        static let numeratedTextFontSize: CGFloat = 15
        static let buttonFontSize: CGFloat = 16

        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 13

        static let cardShadowHeight: CGFloat = 14

        static let scrollViewVerticalPadding: CGFloat = 30
        static let topPadding: CGFloat = 20
        static let bottomStackViewPadding: CGFloat = 20
    }

    private lazy var scrollView: UIScrollView = .build { view in
        view.backgroundColor = .clear
    }

    lazy var containerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    lazy var contentContainerView: UIView = .build { stack in
        stack.backgroundColor = .clear
    }

    private lazy var contentStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = UX.contentStackViewSpacing
        stack.axis = .vertical
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title3, size: UX.titleFontSize)
        label.adjustsFontForContentSizeCategory = true
//        label.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)TitleLabel"
    }

    private lazy var numeratedLabels: [UILabel] = []

    private lazy var textStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .leading
        stack.distribution = .fill
        stack.axis = .vertical
        stack.spacing = UX.textStackViewSpacing
    }

    private lazy var primaryButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.primaryAction), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
//        button.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)PrimaryButton"
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

//    var viewModel: OnboardingCardProtocol
//    weak var delegate: OnboardingCardDelegate?
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    private var contentViewHeightConstraint: NSLayoutConstraint!

    init(// viewModel: OnboardingCardProtocol,
//         delegate: OnboardingCardDelegate?,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
//        self.viewModel = viewModel
//        self.delegate = delegate
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()

//        let height = contentContainerView.intrinsicContentSize.height + UX.cardShadowHeight
        let height = contentContainerView.frame.height + UX.cardShadowHeight
        contentViewHeightConstraint.constant = height
        view.layoutIfNeeded()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        setupView()
        updateLayout()
        applyTheme()
    }

    func setupView() {
        addViewsToView()

        contentViewHeightConstraint = contentContainerView.heightAnchor.constraint(equalToConstant: 300)
        contentViewHeightConstraint.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.scrollViewVerticalPadding),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UX.scrollViewVerticalPadding),

            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.scrollViewVerticalPadding),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -UX.scrollViewVerticalPadding),
            scrollView.frameLayoutGuide.heightAnchor.constraint(equalTo: containerView.heightAnchor).priority(.defaultLow),

            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Content view wrapper around text
            contentContainerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            contentStackView.topAnchor.constraint(greaterThanOrEqualTo: contentContainerView.topAnchor, constant: UX.topPadding),
            contentStackView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: 40),
            contentStackView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -40),
            contentStackView.bottomAnchor.constraint(greaterThanOrEqualTo: contentContainerView.bottomAnchor, constant: -UX.bottomStackViewPadding),
            textStackView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
            primaryButton.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
            primaryButton.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            contentViewHeightConstraint
        ])
    }

    private func updateLayout() {
        titleLabel.text = "Switch Your Default Browser"
        primaryButton.setTitle("Go to Settings", for: .normal)
    }

    private func addViewsToView() {
        createLabels(["1. Go to Settings", "2. Tap Default Browser App", "3. Select Firefox"])

        contentStackView.addArrangedSubview(titleLabel)
        numeratedLabels.forEach { textStackView.addArrangedSubview($0)}
        contentStackView.addArrangedSubview(textStackView)
        contentStackView.addArrangedSubview(primaryButton)

        containerView.addSubview(contentStackView)
        contentContainerView.addSubview(containerView)
        scrollView.addSubview(contentContainerView)
        view.addSubview(scrollView)

        view.backgroundColor = .white
    }

    private func createLabels(_ descriptionTexts: [String]) {
        numeratedLabels = []
        for text in descriptionTexts {
            let label: UILabel = .build { label in
                label.textAlignment = .left
                label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline, size: UX.numeratedTextFontSize)
                label.adjustsFontForContentSizeCategory = true
//                label.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)NumeratedLabel"
                label.text = text
                label.numberOfLines = 0
            }
            numeratedLabels.append(label)
        }
    }

    @objc
    func primaryAction() {
        // TO DO: Create Link to Settings App
    }

    func applyTheme() {
        let theme = themeManager.currentTheme
        titleLabel.textColor = theme.colors.textPrimary
        numeratedLabels.forEach { $0.textColor = theme.colors.textPrimary }

        primaryButton.setTitleColor(theme.colors.textInverted, for: .normal)
        primaryButton.backgroundColor = theme.colors.actionPrimary

        view.backgroundColor = theme.colors.layer1
    }
}

extension OnboardingDefaultSettingsViewController: BottomSheetChild {
    func willDismiss() {
//        viewModel.removeAssetsOnDismiss()
//        viewModel.sendDismissImpressionTelemetry()
    }
}
