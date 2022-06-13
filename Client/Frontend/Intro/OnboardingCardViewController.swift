// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol OnboardingCardDelegate: AnyObject {
    func showNextPage(_ cardType: IntroViewModel.OnboardingCards)
    func primaryAction(_ cardType: IntroViewModel.OnboardingCards)
}

class OnboardingCardViewController: UIViewController {

    struct UX {
        static let stackViewSpacing: CGFloat = 16
        static let stackViewSpacingButtons: CGFloat = 40
        static let buttonHeight: CGFloat = 45
        static let buttonCornerRadius: CGFloat = 13
        static let stackViewPadding: CGFloat = 20
        static let scrollViewVerticalPadding: CGFloat = 62
    }

    var viewModel: OnboardingCardProtocol
    weak var delegate: OnboardingCardDelegate?

    var nextClosure: ((IntroViewModel.OnboardingCards) -> Void)?
    var primaryActionClosure: ((IntroViewModel.OnboardingCards) -> Void)?

    private lazy var scrollView: UIScrollView = .build { view in
        view.backgroundColor = .clear
    }

    lazy var containerView: UIView = .build { stack in
        stack.backgroundColor = .clear
    }

    lazy var contentContainerView: UIView = .build { stack in
        stack.backgroundColor = .clear
    }

    lazy var contentStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fill
        stack.spacing = UX.stackViewSpacing
        stack.axis = .vertical
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)ImageView"
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .title1,
            maxSize: 58)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)TitleLabel"
    }

    // Only available for Welcome card and default cases
    private lazy var descriptionBoldLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .body,
            maxSize: 53)
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)DescriptionBoldLabel"
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = DynamicFontHelper.defaultHelper.preferredFont(
            withTextStyle: .body,
            maxSize: 53)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)DescriptionLabel"
    }

    lazy var buttonStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .fill
        stack.spacing = UX.stackViewSpacing
        stack.axis = .vertical
    }

    private lazy var primaryButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .callout,
            maxSize: 51)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.backgroundColor = UIColor.Photon.Blue50
        button.setTitleColor(UIColor.Photon.LightGrey05, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.primaryAction), for: .touchUpInside)
        button.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)PrimaryButton"
    }

    private lazy var secondaryButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .callout,
            maxSize: 51)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.backgroundColor = UIColor.Photon.LightGrey30
        button.setTitleColor(UIColor.Photon.DarkGrey90, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.secondaryAction), for: .touchUpInside)
        button.accessibilityIdentifier = "\(self.viewModel.a11yIdRoot)SecondaryButton"
    }

    init(viewModel: OnboardingCardProtocol, delegate: OnboardingCardDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection), LegacyThemeManager.instance.systemThemeIsOn {
            let userInterfaceStyle = traitCollection.userInterfaceStyle
            LegacyThemeManager.instance.current = userInterfaceStyle == .dark ? DarkTheme() : NormalTheme()
            applyTheme()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        updateLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.sendCardViewTelemetry()
    }

    func setupView() {
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

            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Content view wrapper around text
            contentContainerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.stackViewPadding),
            contentContainerView.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -UX.stackViewSpacingButtons),
            contentContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.stackViewPadding),

            contentStackView.topAnchor.constraint(greaterThanOrEqualTo: contentContainerView.topAnchor, constant: UX.stackViewPadding),
            contentStackView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            contentStackView.bottomAnchor.constraint(greaterThanOrEqualTo: contentContainerView.bottomAnchor, constant: -UX.stackViewPadding).priority(.defaultLow),
            contentStackView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: contentContainerView.centerYAnchor),

            buttonStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: UX.stackViewPadding),
            buttonStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            buttonStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -UX.stackViewPadding),

            primaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonHeight),
            secondaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonHeight)
        ])
    }

    private func updateLayout() {
        titleLabel.text = viewModel.title
        descriptionBoldLabel.isHidden = viewModel.cardType != .welcome
        descriptionBoldLabel.text = .Onboarding.IntroDescriptionPart1
        descriptionLabel.isHidden = viewModel.description?.isEmpty ?? true
        descriptionLabel.text = viewModel.description
        secondaryButton.isHidden = viewModel.secondaryAction?.isEmpty ?? true

        imageView.image = viewModel.image
        imageView.isHidden = viewModel.image == nil
        primaryButton.setTitle(viewModel.primaryAction, for: .normal)
        secondaryButton.setTitle(viewModel.secondaryAction, for: .normal)
    }

    private func applyTheme() {
        view.backgroundColor = UIColor.theme.homePanel.panelBackground
        titleLabel.textColor = UIColor.theme.homeTabBanner.textColor
        descriptionLabel.textColor = UIColor.theme.homeTabBanner.textColor
        descriptionBoldLabel.textColor = UIColor.theme.homeTabBanner.textColor

    }

    @objc func primaryAction() {
        viewModel.sendTelemetryButton(isPrimaryAction: true)
        delegate?.primaryAction(viewModel.cardType)
    }

    @objc func secondaryAction() {
        viewModel.sendTelemetryButton(isPrimaryAction: false)
        delegate?.showNextPage(viewModel.cardType)
    }
}
