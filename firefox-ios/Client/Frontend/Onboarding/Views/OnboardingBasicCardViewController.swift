// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import ComponentLibrary

class OnboardingBasicCardViewController: OnboardingCardViewController {
    struct UX {
        static let stackViewSpacingWithLink: CGFloat = 15
        static let stackViewSpacingWithoutLink: CGFloat = 24
        static let stackViewSpacingButtons: CGFloat = 16
        static let topStackViewPaddingPad: CGFloat = 70
        static let topStackViewPaddingPhone: CGFloat = 90
        static let bottomStackViewPaddingPad: CGFloat = 32
        static let bottomStackViewPaddingPhone: CGFloat = 0
        static let horizontalTopStackViewPaddingPad: CGFloat = 100
        static let horizontalTopStackViewPaddingPhone: CGFloat = 24
        static let scrollViewVerticalPadding: CGFloat = 62
        static let descriptionBoldFontSize: CGFloat = 20
        static let imageViewSize = CGSize(width: 240, height: 300)

        // small device
        static let smallImageViewSize = CGSize(width: 240, height: 280)
        static let smallTopStackViewPadding: CGFloat = 40

        // tiny device (SE 1st gen)
        static let tinyImageViewSize = CGSize(width: 144, height: 180)

        static let baseImageHeight: CGFloat = 211
    }

    // MARK: - Properties
    weak var delegate: OnboardingCardDelegate?

    lazy var buttonStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .equalSpacing
        stack.axis = .vertical
    }

    private lazy var linkButton: LinkButton = .build { button in
        button.addTarget(self, action: #selector(self.linkButtonAction), for: .touchUpInside)
    }

    // TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-6816
    // This should not be calculated using scaling coefficients, but with some
    // version based on constrains of some kind. The ticket above ensures this work
    // should get addressed.
    private var imageViewHeight: CGFloat {
        return UX.baseImageHeight * scalingCoefficient()
    }

    private func scalingCoefficient() -> CGFloat {
        if shouldUseTinyDeviceLayout {
            return 1.0
        } else if shouldUseSmallDeviceLayout {
            return 1.25
        }

        return 1.4
    }

    // MARK: - Initializers
    init(
        viewModel: OnboardingCardInfoModelProtocol,
        delegate: OnboardingCardDelegate?,
        windowUUID: WindowUUID
    ) {
        self.delegate = delegate

        super.init(viewModel: viewModel, windowUUID: windowUUID)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        updateLayout()
        applyTheme()
        listenForThemeChange(view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate?.pageChanged(from: viewModel.name)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.sendCardViewTelemetry(from: viewModel.name)
    }

    // MARK: - View setup
    func setupView() {
        view.backgroundColor = .clear
        contentStackView.spacing = stackViewSpacing()
        buttonStackView.spacing = stackViewSpacing()
        addViewsToView()

        // Adapt layout for smaller screens
        var scrollViewVerticalPadding = UX.scrollViewVerticalPadding
        var topPadding = UX.topStackViewPaddingPhone
        var horizontalTopStackViewPadding = UX.horizontalTopStackViewPaddingPhone
        var bottomStackViewPadding = UX.bottomStackViewPaddingPhone

        if UIDevice.current.userInterfaceIdiom == .pad {
            topStackView.spacing = stackViewSpacing()
            buttonStackView.spacing = UX.stackViewSpacingButtons
            if traitCollection.horizontalSizeClass == .regular {
                scrollViewVerticalPadding = SharedUX.smallScrollViewVerticalPadding
                topPadding = UX.topStackViewPaddingPad
                horizontalTopStackViewPadding = UX.horizontalTopStackViewPaddingPad
                bottomStackViewPadding = -UX.bottomStackViewPaddingPad
            } else {
                scrollViewVerticalPadding = SharedUX.smallScrollViewVerticalPadding
                topPadding = UX.topStackViewPaddingPhone
                horizontalTopStackViewPadding = UX.horizontalTopStackViewPaddingPhone
                bottomStackViewPadding = -UX.bottomStackViewPaddingPhone
            }
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            horizontalTopStackViewPadding = UX.horizontalTopStackViewPaddingPhone
            bottomStackViewPadding = -UX.bottomStackViewPaddingPhone
            if shouldUseSmallDeviceLayout {
                topStackView.spacing = SharedUX.smallStackViewSpacing
                buttonStackView.spacing = SharedUX.smallStackViewSpacing
                scrollViewVerticalPadding = SharedUX.smallScrollViewVerticalPadding
                topPadding = UX.smallTopStackViewPadding
            } else {
                topStackView.spacing = stackViewSpacing()
                buttonStackView.spacing = UX.stackViewSpacingButtons
                scrollViewVerticalPadding = UX.scrollViewVerticalPadding
                topPadding = view.frame.height * 0.1
            }
        }

        NSLayoutConstraint.activate(
            [
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: scrollViewVerticalPadding),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -scrollViewVerticalPadding),

                scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.frameLayoutGuide.topAnchor.constraint(
                    equalTo: view.topAnchor,
                    constant: scrollViewVerticalPadding
                ),
                scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                scrollView.frameLayoutGuide.bottomAnchor.constraint(
                    equalTo: view.bottomAnchor,
                    constant: -scrollViewVerticalPadding
                ),
                scrollView.frameLayoutGuide.heightAnchor.constraint(
                    equalTo: containerView.heightAnchor
                ).priority(.defaultLow),

                scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
                scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

                // Content view wrapper around text
                contentContainerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topPadding),
                contentContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                contentContainerView.bottomAnchor.constraint(
                    equalTo: containerView.bottomAnchor,
                    constant: bottomStackViewPadding
                ),
                contentContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

                contentStackView.topAnchor.constraint(greaterThanOrEqualTo: contentContainerView.topAnchor),
                contentStackView.leadingAnchor.constraint(
                    equalTo: contentContainerView.leadingAnchor,
                    constant: horizontalTopStackViewPadding
                ),
                contentStackView.bottomAnchor.constraint(
                    greaterThanOrEqualTo: contentContainerView.bottomAnchor,
                    constant: -10
                ),
                contentStackView.trailingAnchor.constraint(
                    equalTo: contentContainerView.trailingAnchor,
                    constant: -horizontalTopStackViewPadding
                ),
                contentStackView.centerYAnchor.constraint(equalTo: contentContainerView.centerYAnchor),

                topStackView.topAnchor.constraint(equalTo: contentStackView.topAnchor),
                topStackView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
                topStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),

                linkButton.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
                linkButton.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),

                buttonStackView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
                buttonStackView.bottomAnchor.constraint(equalTo: contentStackView.bottomAnchor),
                buttonStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),

                imageView.heightAnchor.constraint(equalToConstant: imageViewHeight)
            ]
        )
    }

    private func addViewsToView() {
        topStackView.addArrangedSubview(imageView)
        topStackView.addArrangedSubview(titleLabel)
        topStackView.addArrangedSubview(descriptionLabel)
        contentStackView.addArrangedSubview(topStackView)
        contentStackView.addArrangedSubview(linkButton)

        buttonStackView.addArrangedSubview(primaryButton)
        buttonStackView.addArrangedSubview(secondaryButton)
        contentStackView.addArrangedSubview(buttonStackView)

        contentContainerView.addSubview(contentStackView)
        containerView.addSubviews(contentContainerView)
        scrollView.addSubviews(containerView)
        view.addSubview(scrollView)
    }

    private func stackViewSpacing() -> CGFloat {
        guard viewModel.link?.title != nil else {
            return UX.stackViewSpacingWithoutLink
        }

        return UX.stackViewSpacingWithLink
    }

    private func setupLinkButton() {
        guard let buttonTitle = viewModel.link?.title else {
            linkButton.isUserInteractionEnabled = false
            linkButton.isHidden = true
            return
        }
        let buttonViewModel = LinkButtonViewModel(
            title: buttonTitle,
            a11yIdentifier: "\(self.viewModel.a11yIdRoot)LinkButton",
            font: FXFontStyles.Regular.callout.scaledFont(),
            contentHorizontalAlignment: .center
        )
        linkButton.configure(viewModel: buttonViewModel)
        linkButton.applyTheme(theme: currentTheme())
    }

    // MARK: - Button Actions
    @objc
    override func primaryAction() {
        delegate?.handleBottomButtonActions(
            for: viewModel.buttons.primary.action,
            from: viewModel.name,
            isPrimaryButton: true)
    }

    @objc
    override func secondaryAction() {
        guard let buttonAction = viewModel.buttons.secondary?.action else { return }

        delegate?.handleBottomButtonActions(
            for: buttonAction,
            from: viewModel.name,
            isPrimaryButton: false)
    }

    @objc
    func linkButtonAction() {
        delegate?.handleBottomButtonActions(
            for: .readPrivacyPolicy,
            from: viewModel.name,
            isPrimaryButton: false)
    }

    // MARK: - Themeable
    override func applyTheme() {
        let theme = currentTheme()
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor  = theme.colors.textPrimary

        primaryButton.applyTheme(theme: theme)
        setupSecondaryButton()
        setupLinkButton()
    }
}
