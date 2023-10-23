// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary

// MARK: View
final class FakespotOptInCardView: UIView, ThemeApplicable {
    private struct UX {
        static let headerLabelFontSize: CGFloat = 28
        static let bodyLabelFontSize: CGFloat = 15
        static let learnMoreButtonFontSize: CGFloat = 15
        static let termsOfUseButtonInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let disclaimerTextLabelFontSize: CGFloat = 13
        static let disclaimerBlockInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let learnMoreInsets = UIEdgeInsets(top: -10, left: 0, bottom: 10, right: 0)
        static let termsOfUseButtonTitleFontSize: CGFloat = 13
        static let privacyPolicyButtonTitleFontSize: CGFloat = 13
        static let mainButtonFontSize: CGFloat = 16
        static let mainButtonCornerRadius: CGFloat = 14
        static let mainButtonInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        static let secondaryButtonFontSize: CGFloat = 13
        static let contentStackViewSpacing: CGFloat = 12
        static let contentStackViewPadding: CGFloat = 16
        static let disclaimerStackViewSpacing: CGFloat = 3
        static let optInImageViewIpadTopSpace: CGFloat = 30
        static let optInImageViewIpadBottomSpace: CGFloat = 40
    }

    private var viewModel: FakespotOptInCardViewModel?

    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var mainView: UIView = .build()

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.contentStackViewSpacing
    }

    private lazy var disclaimerStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.disclaimerStackViewSpacing
    }

    private lazy var optInImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.shoppingOptInCardImage)
        imageView.contentMode = .scaleAspectFit
    }

    // MARK: Labels
    private lazy var headerLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline,
                                                            size: UX.headerLabelFontSize,
                                                            weight: .medium)
        label.accessibilityTraits.insert(.header)
    }

    private lazy var bodyLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.bodyLabelFontSize)
    }

    private lazy var disclaimerTextLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.disclaimerTextLabelFontSize)
    }

    // MARK: Buttons
    private lazy var learnMoreButton: ResizableButton = .build { button in
        button.contentHorizontalAlignment = .leading
        button.buttonEdgeSpacing = 0
        button.addTarget(self, action: #selector(self.didTapLearnMore), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                         size: UX.learnMoreButtonFontSize)
        button.contentEdgeInsets = UX.learnMoreInsets
    }

    private lazy var termsOfUseButton: ResizableButton = .build { button in
        button.contentHorizontalAlignment = .leading
        button.buttonEdgeSpacing = 0
        button.contentEdgeInsets = UX.disclaimerBlockInsets
        button.addTarget(self, action: #selector(self.didTapTermsOfUse), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                         size: UX.termsOfUseButtonTitleFontSize)
    }

    private lazy var privacyPolicyButton: ResizableButton = .build { button in
        button.contentHorizontalAlignment = .leading
        button.buttonEdgeSpacing = 0
        button.contentEdgeInsets = UX.disclaimerBlockInsets
        button.addTarget(self, action: #selector(self.didTapPrivacyPolicy), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                         size: UX.privacyPolicyButtonTitleFontSize)
    }

    private lazy var mainButton: ResizableButton = .build { button in
        button.contentHorizontalAlignment = .center
        button.buttonEdgeSpacing = 0
        button.layer.cornerRadius = UX.mainButtonCornerRadius
        button.contentEdgeInsets = UX.mainButtonInsets
        button.addTarget(self, action: #selector(self.didTapMainButton), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline,
                                                                         size: UX.mainButtonFontSize,
                                                                         weight: .semibold)
    }

    private lazy var secondaryButton: ResizableButton = .build { button in
        button.contentHorizontalAlignment = .center
        button.buttonEdgeSpacing = 0
        button.addTarget(self, action: #selector(self.didTapSecondaryButton), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                         size: UX.secondaryButtonFontSize)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        sendTelemetryOnAppear()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Constraints Setup
    private func setupLayout() {
        addSubviews(cardContainer, mainView)
        mainView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(headerLabel)

        contentStackView.addArrangedSubview(bodyLabel)
        contentStackView.addArrangedSubview(learnMoreButton)

        contentStackView.addArrangedSubview(optInImageView)
        addVerticalSpaceToImageView()

        disclaimerStackView.addArrangedSubview(disclaimerTextLabel)
        disclaimerStackView.addArrangedSubview(privacyPolicyButton)
        disclaimerStackView.addArrangedSubview(termsOfUseButton)
        contentStackView.addArrangedSubview(disclaimerStackView)

        contentStackView.addArrangedSubview(mainButton)
        contentStackView.addArrangedSubview(secondaryButton)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: mainView.topAnchor,
                                                  constant: UX.contentStackViewPadding),
            contentStackView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor,
                                                     constant: -UX.contentStackViewPadding),
            contentStackView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor,
                                                      constant: UX.contentStackViewPadding),
            contentStackView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor,
                                                       constant: -UX.contentStackViewPadding),
        ])
    }

    private func addVerticalSpaceToImageView() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }

        contentStackView.setCustomSpacing(UX.optInImageViewIpadTopSpace, after: learnMoreButton)
        contentStackView.setCustomSpacing(UX.optInImageViewIpadBottomSpace, after: optInImageView)
    }

    // MARK: Button Actions
    @objc
    private func didTapLearnMore() {
        viewModel?.onTapLearnMore()
    }

    @objc
    private func didTapTermsOfUse() {
        viewModel?.onTapTermsOfUse()
    }

    @objc
    private func didTapPrivacyPolicy() {
        viewModel?.onTapPrivacyPolicy()
    }

    @objc
    private func didTapMainButton() {
        viewModel?.onTapMainButton()
    }

    @objc
    private func didTapSecondaryButton() {
        viewModel?.onTapSecondaryButton()
    }

    // MARK: View Setup
    func configure(_ viewModel: FakespotOptInCardViewModel) {
        self.viewModel = viewModel

        headerLabel.text = viewModel.headerTitle
        headerLabel.accessibilityIdentifier = viewModel.headerA11yId

        bodyLabel.attributedText = viewModel.bodyText
        bodyLabel.accessibilityIdentifier = viewModel.bodyA11yId

        disclaimerTextLabel.attributedText = viewModel.disclaimerText
        disclaimerTextLabel.accessibilityIdentifier = viewModel.disclaimerLabelA11yId

        learnMoreButton.setTitle(viewModel.learnMoreButtonText, for: .normal)
        learnMoreButton.accessibilityIdentifier = viewModel.learnMoreButtonA11yId

        termsOfUseButton.setTitle(viewModel.termsOfUseButtonText, for: .normal)
        termsOfUseButton.accessibilityIdentifier = viewModel.termsOfUseButtonA11yId

        privacyPolicyButton.setTitle(viewModel.privacyPolicyButtonText, for: .normal)
        privacyPolicyButton.accessibilityIdentifier = viewModel.privacyPolicyButtonA11yId

        mainButton.setTitle(viewModel.mainButtonText, for: .normal)
        mainButton.accessibilityIdentifier = viewModel.mainButtonA11yId

        secondaryButton.setTitle(viewModel.secondaryButtonText, for: .normal)
        secondaryButton.accessibilityIdentifier = viewModel.secondaryButtonA11yId

        let cardModel = ShadowCardViewModel(view: mainView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)
    }

    // MARK: Telemetry
    private func sendTelemetryOnAppear() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .shoppingOnboarding)
    }

    // MARK: - Theming System
    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
        let colors = theme.colors
        headerLabel.textColor = colors.textPrimary
        bodyLabel.textColor = colors.textPrimary
        disclaimerTextLabel.textColor = colors.textSecondary
        learnMoreButton.setTitleColor(colors.textAccent, for: .normal)
        termsOfUseButton.setTitleColor(colors.textAccent, for: .normal)
        privacyPolicyButton.setTitleColor(colors.textAccent, for: .normal)
        mainButton.setTitleColor(colors.textInverted, for: .normal)
        mainButton.backgroundColor = colors.actionPrimary
        secondaryButton.setTitleColor(colors.textAccent, for: .normal)
    }
}
