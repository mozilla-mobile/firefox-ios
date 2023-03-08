// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class SurveySurfaceViewController: UIViewController, Themeable {
    struct UX {
        static let buttonMaxWidth = 400
        static let buttonSideMarginMultiplier = 0.05
        static let buttonBottomMarginMultiplier = 0.1

        static let imageViewSize = CGSize(width: 128, height: 128)
    }

    // MARK: - Variables
    var viewModel: SurveySurfaceViewModel

    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    // MARK: - UI Elements
    lazy var containerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    lazy var contentContainerView: UIView = .build { stack in
        stack.backgroundColor = .clear
    }

    lazy var contentStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = UX.stackViewSpacing
        stack.axis = .vertical
    }

    lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)ImageView"
    }

    private lazy var descriptionBoldLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title3,
                                                                       size: UX.descriptionBoldFontSize)
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)DescriptionBoldLabel"
    }

    lazy var buttonStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fill
        stack.spacing = UX.stackViewSpacing
        stack.axis = .vertical
    }

    private lazy var takeSurveyButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.primaryAction), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)PrimaryButton"
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

    private lazy var dismissSurveyButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.secondaryAction), for: .touchUpInside)
        button.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)SecondaryButton"
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

    // MARK: - View Lifecyle
    init(viewModel: SurveySurfaceViewModel,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        
        self.viewModel = viewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        setupView()
        updateLayout()
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        delegate?.pageChanged(viewModel.cardType)
        viewModel.sendCardViewTelemetry()
    }

    func setupView() {
        view.backgroundColor = .clear

        contentStackView.addArrangedSubview(imageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionBoldLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        contentContainerView.addSubviews(contentStackView)

        buttonStackView.addArrangedSubview(primaryButton)
        buttonStackView.addArrangedSubview(secondaryButton)

        containerView.addSubviews(contentContainerView)
        containerView.addSubviews(buttonStackView)
        scrollView.addSubviews(containerView)
        view.addSubview(scrollView)

        // Adapt layout for smaller screens
        let scrollViewVerticalPadding = shouldUseSmallDeviceLayout ? UX.smallScrollViewVerticalPadding :  UX.scrollViewVerticalPadding
        let stackViewSpacingButtons = shouldUseSmallDeviceLayout ? UX.smallStackViewSpacingButtons :  UX.stackViewSpacingButtons
        let imageViewHeight = shouldUseSmallDeviceLayout ?
            UX.imageViewSize.height : UX.smallImageViewSize.height

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: scrollViewVerticalPadding),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -scrollViewVerticalPadding),

            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor, constant: scrollViewVerticalPadding),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -scrollViewVerticalPadding),
            scrollView.frameLayoutGuide.heightAnchor.constraint(equalTo: containerView.heightAnchor).priority(.defaultLow),

            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Content view wrapper around text
            contentContainerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.stackViewPadding),
            contentContainerView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -stackViewSpacingButtons),
            contentContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.stackViewPadding),

            contentStackView.topAnchor.constraint(greaterThanOrEqualTo: contentContainerView.topAnchor, constant: UX.stackViewPadding),
            contentStackView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            contentStackView.bottomAnchor.constraint(greaterThanOrEqualTo: contentContainerView.bottomAnchor, constant: -UX.stackViewPadding).priority(.defaultLow),
            contentStackView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: contentContainerView.centerYAnchor),

            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.stackViewPadding),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -UX.stackViewPadding),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.stackViewPadding),

            imageView.heightAnchor.constraint(equalToConstant: imageViewHeight)
        ])

        contentStackView.spacing = shouldUseSmallDeviceLayout ? UX.smallStackViewSpacing : UX.stackViewSpacing
        buttonStackView.spacing = shouldUseSmallDeviceLayout ? UX.smallStackViewSpacing : UX.stackViewSpacing
    }

    private func updateLayout() {
        titleLabel.text = viewModel.infoModel.title
        descriptionBoldLabel.isHidden = !viewModel.shouldShowDescriptionBold
        descriptionBoldLabel.text = .Onboarding.IntroDescriptionPart1
        descriptionLabel.isHidden = viewModel.infoModel.description?.isEmpty ?? true
        descriptionLabel.text = viewModel.infoModel.description

        imageView.image = viewModel.infoModel.image
        primaryButton.setTitle(viewModel.infoModel.primaryAction, for: .normal)
        handleSecondaryButton()
    }

    // MARK: - Themable
    func applyTheme() {
        let theme = themeManager.currentTheme
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor  = theme.colors.textPrimary
        descriptionBoldLabel.textColor = theme.colors.textPrimary

        primaryButton.setTitleColor(theme.colors.textInverted, for: .normal)
        primaryButton.backgroundColor = theme.colors.actionPrimary

        secondaryButton.setTitleColor(theme.colors.textSecondaryAction, for: .normal)
        secondaryButton.backgroundColor = theme.colors.actionSecondary
        handleSecondaryButton()
    }
}
