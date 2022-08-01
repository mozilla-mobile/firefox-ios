// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Storage
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
        static let buttonHeight: CGFloat = 44
        static let textSpacing: CGFloat = 8
        static let cardCornerRadius: CGFloat = 12
        static let dismissButtonSize = CGSize(width: 16, height: 16)
        static let dismissButtonSpacing: CGFloat = 12
        static let standardSpacing: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 8
        static let bannerTitleMaxFontSize: CGFloat = 55
        static let descriptionTextMaxFontSize: CGFloat = 49
        static let buttonMaxFontSize: CGFloat = 53
        static let buttonEdgeSpacing: CGFloat = 16
        static let bottomCardSafeSpace: CGFloat = 8
    }

    // MARK: - Properties
    private var viewModel: HomepageMessageCardProtocol!

    // UI
    private lazy var bannerTitle: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .headline,
                                                                   maxSize: UX.bannerTitleMaxFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor.theme.homeTabBanner.textColor
    }

    private lazy var descriptionText: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                   maxSize: UX.descriptionTextMaxFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor.theme.homeTabBanner.textColor
    }

    private lazy var ctaButton: ActionButton = .build { [weak self] button in
        button.backgroundColor = UIColor.Photon.Blue50
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .body,
                                                                                    maxSize: UX.buttonMaxFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.layer.masksToBounds = true
        button.accessibilityIdentifier = a11y.ctaButton
        button.addTarget(self, action: #selector(self?.handleCTA), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: UX.buttonEdgeSpacing,
                                                bottom: 0, right: UX.buttonEdgeSpacing)
    }

    private lazy var dismissButton: UIButton = .build { [weak self] button in
        button.setImage(UIImage(named: ImageIdentifiers.xMark)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.tintColor = UIColor.theme.homeTabBanner.textColor
        button.addTarget(self, action: #selector(self?.dismissCard), for: .touchUpInside)
        button.accessibilityLabel = BannerCopy.HomeTabBannerCloseAccessibility
    }

    private lazy var textStackView: UIStackView = .build { [weak self] stackView in
        guard let self = self else { return }
        stackView.addArrangedSubview(self.bannerTitle)
        stackView.addArrangedSubview(self.descriptionText)
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
        stackView.spacing = UX.textSpacing
    }

    private lazy var cardView: UIView = .build { view in
        view.backgroundColor = UIColor.theme.homeTabBanner.backgroundColor
        view.layer.cornerRadius = UX.cardCornerRadius
        view.layer.masksToBounds = true
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewModel: HomepageMessageCardViewModel) {
        self.viewModel = viewModel

        if let message = viewModel.getMessage(for: .newTabCard) {
            applyGleanMessage(message)
        }
    }

    // MARK: - Layout

    private func setupLayout() {
        cardView.addSubviews(ctaButton, textStackView, dismissButton)
        addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardView.widthAnchor.constraint(equalToConstant: UX.cardSizeMaxWidth),

            textStackView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor),
            textStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.standardSpacing),
            textStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.standardSpacing),
            textStackView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -UX.standardSpacing),

            dismissButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: UX.dismissButtonSpacing),
            dismissButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.standardSpacing),
            dismissButton.heightAnchor.constraint(equalToConstant: UX.dismissButtonSize.height),
            dismissButton.widthAnchor.constraint(equalToConstant: UX.dismissButtonSize.width),

            ctaButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.standardSpacing),
            ctaButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.standardSpacing),
            ctaButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -UX.standardSpacing),
            ctaButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.buttonHeight),
        ])
    }

    func applyTheme() {
        cardView.backgroundColor = UIColor.theme.homeTabBanner.backgroundColor
        bannerTitle.textColor = UIColor.theme.homeTabBanner.textColor
        descriptionText.textColor = UIColor.theme.homeTabBanner.textColor
        dismissButton.imageView?.tintColor = UIColor.theme.homeTabBanner.textColor
        backgroundColor = .clear
    }

    // MARK: - Message setup

    /// Apply message data, including handling of cases where certain parts of the message are missing.
    private func applyGleanMessage(_ message: GleanPlumbMessage) {
        if let buttonLabel = message.data.buttonLabel {
            ctaButton.setTitle(buttonLabel, for: .normal)
        } else {
            ctaButton.removeFromSuperview()
            let cardTapped = UITapGestureRecognizer(target: self, action: #selector(handleCTA))

            cardView.addGestureRecognizer(cardTapped)
            cardView.isUserInteractionEnabled = true
        }

        if let title = message.data.title {
            bannerTitle.text = title
        } else {
            textStackView.removeArrangedView(bannerTitle)
        }

        descriptionText.text = message.data.text
        viewModel.handleMessageDisplayed()
    }

    // MARK: Actions
    @objc private func dismissCard() {
        viewModel.handleMessageDismiss()
    }

    /// The surface needs to handle CTAs a certain way when there's a message.
    @objc func handleCTA() {
        viewModel.handleMessagePressed()
    }
}
