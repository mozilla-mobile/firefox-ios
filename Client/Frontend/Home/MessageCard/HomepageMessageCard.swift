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
class HomepageMessageCardCell: BlurrableCollectionViewCell, ReusableCell {

    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.HomeTabBanner
    typealias BannerCopy = String.FirefoxHomepage.HomeTabBanner.EvergreenMessage

    struct UX {
        static let cardSizeMaxWidth: CGFloat = 360
        static let textSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 12
        static let dismissButtonSize = CGSize(width: 16, height: 16)
        static let dismissButtonSpacing: CGFloat = 12
        static let standardSpacing: CGFloat = 16
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let topCardSafeSpace: CGFloat = 16
        static let bottomCardSafeSpace: CGFloat = 32
        // Max font size
        static let bannerTitleFontSize: CGFloat = 16
        static let descriptionTextFontSize: CGFloat = 15
        static let buttonFontSize: CGFloat = 16
        // Shadow
        static let shadowRadius: CGFloat = 4
        static let shadowOffset: CGFloat = 4
        static let shadowOpacity: Float = 0.12
    }

    // MARK: - Properties
    private var viewModel: HomepageMessageCardViewModel?
    var notificationCenter: NotificationProtocol = NotificationCenter.default
    private var kvoToken: NSKeyValueObservation?

    // UI

    private lazy var titleContainerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var bannerTitle: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .headline,
                                                                   size: UX.bannerTitleFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = a11y.titleLabel
        label.textColor = UIColor.theme.homeTabBanner.textColor
    }

    private lazy var descriptionText: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   size: UX.descriptionTextFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = a11y.descriptionLabel
        label.textColor = UIColor.theme.homeTabBanner.textColor
    }

    private lazy var ctaButton: ActionButton = .build { [weak self] button in
        button.backgroundColor = UIColor.Photon.Blue50
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .body,
                                                                                    size: UX.buttonFontSize)

        button.layer.cornerRadius = UIFontMetrics.default.scaledValue(for: UX.cornerRadius)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = a11y.ctaButton
        button.addTarget(self, action: #selector(self?.handleCTA), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

    private lazy var dismissButton: UIButton = .build { [weak self] button in
        button.setImage(UIImage(named: ImageIdentifiers.xMark)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.tintColor = UIColor.theme.homeTabBanner.textColor
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
        view.backgroundColor = UIColor.theme.homeTabBanner.backgroundColor
        view.layer.cornerRadius = UX.cornerRadius
    }

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
        observeCardViewBounds()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged,
                                       .WallpaperDidChange])
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        kvoToken?.invalidate()
    }

    func configure(viewModel: HomepageMessageCardViewModel) {
        self.viewModel = viewModel

        if let message = viewModel.getMessage(for: .newTabCard) {
            applyGleanMessage(message)
        }

        applyTheme()
    }

    // MARK: - Layout

    private func setupLayout() {
        titleContainerView.addSubviews(bannerTitle)
        textStackView.addArrangedSubview(titleContainerView)
        textStackView.addArrangedSubview(descriptionText)

        cardView.addSubviews(ctaButton, textStackView, dismissButton)
        contentView.addSubview(cardView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.topCardSafeSpace),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.bottomCardSafeSpace),
            cardView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            cardView.widthAnchor.constraint(equalToConstant: UX.cardSizeMaxWidth).priority(.defaultHigh),

            textStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: UX.standardSpacing),
            textStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.standardSpacing),
            textStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.standardSpacing),
            textStackView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -UX.standardSpacing),

            bannerTitle.topAnchor.constraint(equalTo: titleContainerView.topAnchor),
            bannerTitle.leadingAnchor.constraint(equalTo: titleContainerView.leadingAnchor),
            bannerTitle.trailingAnchor.constraint(equalTo: titleContainerView.trailingAnchor, constant: -UX.standardSpacing),
            bannerTitle.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor),

            dismissButton.topAnchor.constraint(equalTo: textStackView.topAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.standardSpacing),
            dismissButton.heightAnchor.constraint(equalToConstant: UX.dismissButtonSize.height),
            dismissButton.widthAnchor.constraint(equalToConstant: UX.dismissButtonSize.width),

            ctaButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.standardSpacing),
            ctaButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.standardSpacing),
            ctaButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -UX.standardSpacing),
        ])
        addShadow()
    }

    // Observing cardView bounds change to set the shadow correctly because initially
    // the view bounds is incorrect causing weird shadow effect
    private func observeCardViewBounds() {
        kvoToken = cardView.observe(\.bounds, options: .new) { [weak self] _, _ in
            self?.updateShadowPath()
        }
    }

    private func addShadow() {
        cardView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        cardView.layer.shadowOffset = CGSize(width: 0.0, height: UX.shadowOffset)
        cardView.layer.shadowOpacity = UX.shadowOpacity
        cardView.layer.shadowRadius = UX.shadowRadius
        updateShadowPath()
    }

    private func updateShadowPath() {
        cardView.layer.shadowPath = UIBezierPath(roundedRect: cardView.bounds,
                                                 cornerRadius: UX.cornerRadius).cgPath
    }

    func applyTheme() {
        if shouldApplyWallpaperBlur {
            cardView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            cardView.removeVisualEffectView()
            cardView.backgroundColor = LegacyThemeManager.instance.current.homeTabBanner.backgroundColor
        }

        updateShadowPath()

        bannerTitle.textColor = LegacyThemeManager.instance.current.homeTabBanner.textColor
        descriptionText.textColor = LegacyThemeManager.instance.current.homeTabBanner.textColor
        dismissButton.imageView?.tintColor = LegacyThemeManager.instance.current.homeTabBanner.textColor
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
            textStackView.removeArrangedView(titleContainerView)
        }

        descriptionText.text = message.data.text
    }

    // MARK: Actions
    @objc private func dismissCard() {
        viewModel?.handleMessageDismiss()
    }

    /// The surface needs to handle CTAs a certain way when there's a message.
    @objc func handleCTA() {
        viewModel?.handleMessagePressed()
    }
}

// MARK: - Notifiable
extension HomepageMessageCardCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            switch notification.name {
            case .DisplayThemeChanged,
                    .WallpaperDidChange:
                self?.applyTheme()
            default: break
            }
        }
    }
}
