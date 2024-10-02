// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary
import Account

// MARK: View
final class FakespotOptInCardView: UIView, ThemeApplicable {
    private struct UX {
        static let privacyButtonInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
        static let termsOfUseButtonInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
        static let learnMoreInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0)
        static let secondaryButtonInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let contentStackViewSpacing: CGFloat = 16
        static let contentStackHorizontalPadding: CGFloat = 16
        static let contentStackTopPadding: CGFloat = 16
        static let contentStackBottomPadding: CGFloat = 8
        static let disclaimerStackViewSpacing: CGFloat = 0
        static let buttonAdjustedVerticalSpacing: CGFloat = 0
        static let disclaimerAdjustedSpacing: CGFloat = 8
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
        label.font = FXFontStyles.Bold.title1.scaledFont()
        label.accessibilityTraits.insert(.header)
    }

    private lazy var bodyLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
    }

    private lazy var disclaimerTextLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Regular.footnote.scaledFont()
    }

    // MARK: Buttons
    private lazy var learnMoreButton: LinkButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapLearnMore), for: .touchUpInside)
    }

    private lazy var termsOfUseButton: LinkButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapTermsOfUse), for: .touchUpInside)
    }

    private lazy var privacyPolicyButton: LinkButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapPrivacyPolicy), for: .touchUpInside)
    }

    private lazy var mainButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapMainButton), for: .touchUpInside)
    }

    private lazy var secondaryButton: LinkButton = .build { button in
        button.addTarget(self, action: #selector(self.didTapSecondaryButton), for: .touchUpInside)
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
                                                  constant: UX.contentStackTopPadding),
            contentStackView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor,
                                                     constant: -UX.contentStackBottomPadding),
            contentStackView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor,
                                                      constant: UX.contentStackHorizontalPadding),
            contentStackView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor,
                                                       constant: -UX.contentStackHorizontalPadding),
        ])

        contentStackView.setCustomSpacing(UX.buttonAdjustedVerticalSpacing, after: bodyLabel)
        contentStackView.setCustomSpacing(UX.disclaimerAdjustedSpacing, after: disclaimerStackView)
        contentStackView.setCustomSpacing(UX.buttonAdjustedVerticalSpacing, after: mainButton)
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

        let learnMoreButtonViewModel = LinkButtonViewModel(
            title: viewModel.learnMoreButtonText,
            a11yIdentifier: viewModel.learnMoreButtonA11yId,
            font: FXFontStyles.Regular.subheadline.scaledFont(),
            contentInsets: UX.learnMoreInsets
        )
        learnMoreButton.configure(viewModel: learnMoreButtonViewModel)

        let termsOfUseButtonViewModel = LinkButtonViewModel(
            title: viewModel.termsOfUseButtonText,
            a11yIdentifier: viewModel.termsOfUseButtonA11yId,
            font: FXFontStyles.Regular.footnote.scaledFont(),
            contentInsets: UX.termsOfUseButtonInsets
        )
        termsOfUseButton.configure(viewModel: termsOfUseButtonViewModel)

        let privacyButtonViewModel = LinkButtonViewModel(
            title: viewModel.privacyPolicyButtonText,
            a11yIdentifier: viewModel.privacyPolicyButtonA11yId,
            font: FXFontStyles.Regular.footnote.scaledFont(),
            contentInsets: UX.privacyButtonInsets
        )
        privacyPolicyButton.configure(viewModel: privacyButtonViewModel)

        let buttonViewModel = PrimaryRoundedButtonViewModel(
            title: viewModel.mainButtonText,
            a11yIdentifier: viewModel.mainButtonA11yId
        )
        mainButton.configure(viewModel: buttonViewModel)

        let secondaryButtonViewModel = LinkButtonViewModel(
            title: viewModel.secondaryButtonText,
            a11yIdentifier: viewModel.secondaryButtonA11yId,
            font: FXFontStyles.Regular.footnote.scaledFont(),
            contentInsets: UX.secondaryButtonInsets,
            contentHorizontalAlignment: .center
        )
        secondaryButton.configure(viewModel: secondaryButtonViewModel)

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
        learnMoreButton.applyTheme(theme: theme)
        termsOfUseButton.applyTheme(theme: theme)
        privacyPolicyButton.applyTheme(theme: theme)
        mainButton.applyTheme(theme: theme)
        secondaryButton.applyTheme(theme: theme)
    }
}
