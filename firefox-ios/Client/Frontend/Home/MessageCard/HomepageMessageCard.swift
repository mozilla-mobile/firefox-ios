// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Shared
import UIKit

/// The Home Tab Banner is the card that appears at the top of the Firefox Homepage.
/// 
/// The HomeTabBanner is one UI surface that is being targeted for experimentation with `GleanPlumb` AKA Messaging.
/// When there are GleanPlumbMessages, the card will get populated with that data. Otherwise, we'll continue showing the
/// default browser message AKA the evergreen.
class HomepageMessageCardCell: UICollectionViewCell, ReusableCell {
    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.HomeTabBanner
    typealias BannerCopy = String.FirefoxHomepage.HomeTabBanner.EvergreenMessage

    struct UX {
        static let cardSizeMaxWidth: CGFloat = 360
        static let textSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 12
        static let dismissButtonSize = CGSize(width: 16, height: 16)
        static let dismissButtonSpacing: CGFloat = 12
        static let standardSpacing: CGFloat = 16
        static let topCardSafeSpace: CGFloat = 16
        static let bottomCardSafeSpace: CGFloat = 32
    }

    // MARK: - Properties
    private var viewModel: HomepageMessageCardViewModel?
    private var kvoToken: NSKeyValueObservation?

    // MARK: - UI

    private lazy var titleContainerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var bannerTitle: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = FXFontStyles.Regular.headline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = a11y.titleLabel
    }

    private lazy var descriptionText: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = a11y.descriptionLabel
    }

    private lazy var ctaButton: PrimaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.handleCTA), for: .touchUpInside)
    }

    private lazy var dismissButton: UIButton = .build { [weak self] button in
        button.setImage(
            UIImage(named: StandardImageIdentifiers.Large.cross)?.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
        button.addTarget(self, action: #selector(self?.dismissCard), for: .touchUpInside)
        button.accessibilityLabel = BannerCopy.HomeTabBannerCloseAccessibility
    }

    private lazy var textStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = UX.textSpacing
    }

    private lazy var cardView: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
        observeCardViewBounds()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        kvoToken?.invalidate()
    }

    func configure(viewModel: HomepageMessageCardViewModel, theme: Theme) {
        self.viewModel = viewModel

        if let message = viewModel.getMessage(for: .newTabCard) {
            applyGleanMessage(message)
        }

        applyTheme(theme: theme)
        ctaButton.applyTheme(theme: theme)
    }

    // MARK: - Layout

    private func setupLayout() {
        titleContainerView.addSubviews(bannerTitle)
        textStackView.addArrangedSubview(titleContainerView)
        textStackView.addArrangedSubview(descriptionText)

        cardView.addSubviews(ctaButton, textStackView, dismissButton)
        contentView.addSubview(cardView)

        NSLayoutConstraint.activate(
            [
                cardView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
                cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
                cardView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
                cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                cardView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                cardView.widthAnchor.constraint(equalToConstant: UX.cardSizeMaxWidth).priority(.defaultHigh),

                textStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: UX.standardSpacing),
                textStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.standardSpacing),
                textStackView.trailingAnchor.constraint(
                    equalTo: cardView.trailingAnchor,
                    constant: -UX.standardSpacing
                ),
                textStackView.bottomAnchor.constraint(
                    equalTo: ctaButton.topAnchor,
                    constant: -UX.standardSpacing
                ),

                bannerTitle.topAnchor.constraint(equalTo: titleContainerView.topAnchor),
                bannerTitle.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor),
                bannerTitle.trailingAnchor.constraint(
                    equalTo: titleContainerView.trailingAnchor,
                    constant: -UX.standardSpacing
                ),
                bannerTitle.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor),

                dismissButton.topAnchor.constraint(equalTo: textStackView.topAnchor),
                dismissButton.trailingAnchor.constraint(
                    equalTo: cardView.trailingAnchor,
                    constant: -UX.standardSpacing
                ),
                dismissButton.heightAnchor.constraint(equalToConstant: UX.dismissButtonSize.height),
                dismissButton.widthAnchor.constraint(equalToConstant: UX.dismissButtonSize.width),

                ctaButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.standardSpacing),
                ctaButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.standardSpacing),
                ctaButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -UX.standardSpacing),
            ]
        )
    }

    // Observing cardView bounds change to set the shadow correctly because initially
    // the view bounds is incorrect causing weird shadow effect
    private func observeCardViewBounds() {
        kvoToken = cardView.observe(\.bounds, options: .new) { [weak self] _, _ in
            self?.updateShadowPath()
        }
    }

    private func setupShadow(theme: Theme) {
        cardView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        cardView.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        cardView.layer.shadowOpacity = HomepageViewModel.UX.shadowOpacity
        cardView.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
        updateShadowPath()
    }

    private func updateShadowPath() {
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds,
                                                 cornerRadius: UX.cornerRadius).cgPath
    }

    // MARK: - Message setup

    /// Apply message data, including handling of cases where certain parts of the message are missing.
    private func applyGleanMessage(_ message: GleanPlumbMessage) {
        if let buttonLabel = message.buttonLabel {
            let buttonViewModel = PrimaryRoundedButtonViewModel(
                title: buttonLabel,
                a11yIdentifier: a11y.ctaButton
            )
            ctaButton.configure(viewModel: buttonViewModel)
        } else {
            ctaButton.removeFromSuperview()
            let cardTapped = UITapGestureRecognizer(target: self, action: #selector(handleCTA))

            cardView.addGestureRecognizer(cardTapped)
            cardView.isUserInteractionEnabled = true
        }

        if let title = message.title {
            bannerTitle.text = title
        } else {
            textStackView.removeArrangedView(titleContainerView)
        }

        descriptionText.text = message.text
    }

    // MARK: Actions
    @objc
    private func dismissCard() {
        viewModel?.handleMessageDismiss()
    }

    /// The surface needs to handle CTAs a certain way when there's a message.
    @objc
    func handleCTA() {
        viewModel?.handleMessagePressed()
    }
}

// MARK: - Notifiable
extension HomepageMessageCardCell: Blurrable {
    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            cardView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            cardView.removeVisualEffectView()
            cardView.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}

// MARK: - ThemeApplicable
extension HomepageMessageCardCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        bannerTitle.textColor = theme.colors.textPrimary
        descriptionText.textColor = theme.colors.textPrimary
        dismissButton.imageView?.tintColor = theme.colors.textPrimary
        backgroundColor = .clear

        adjustBlur(theme: theme)
    }
}
