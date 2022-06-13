// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Storage
import Shared
import UIKit

/// The Home Tab Banner is the card that appears at the top of the FIrefox Homepage.
/// 
/// The HomeTabBanner is one UI surface that is being targeted for experimentation with `GleanPlumb` AKA Messaging.
/// When there are GleanPlumbMessages, the card will get populated with that data. Otherwise, we'll continue showing the
/// default browser message AKA the evergreen.
class HomeTabBanner: UIView, GleanPlumbMessageManagable {

    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.HomeTabBanner
    typealias BannerCopy = String.FirefoxHomepage.HomeTabBanner.EvergreenMessage

    struct UX {
        static let cardSize = CGSize(width: 360, height: 224)
        static let logoSize = CGSize(width: 64, height: 64)
        static let learnHowButtonSize: CGSize = CGSize(width: 304, height: 44)
        static let textSpacing: CGFloat = 10
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

    private var heightConstraint: NSLayoutConstraint?
    private var maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude

    public var dismissClosure: (() -> Void)?
    var message: GleanPlumbMessage?

    // UI
    private lazy var bannerTitle: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title3,
                                                                       maxSize: UX.bannerTitleMaxFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor.theme.homeTabBanner.textColor
    }

    private lazy var descriptionText: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline,
                                                                   maxSize: UX.descriptionTextMaxFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = UIColor.theme.homeTabBanner.textColor
    }

    private lazy var ctaButton: UIButton = .build { [weak self] button in
        button.backgroundColor = UIColor.Photon.Blue50
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .body,
                                                                                    maxSize: UX.buttonMaxFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.layer.masksToBounds = true
        button.accessibilityIdentifier = a11y.ctaButton
        button.addTarget(self, action: #selector(self?.handleCTA), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: UX.buttonEdgeSpacing,
                                                bottom: 0, right: UX.buttonEdgeSpacing)
        button.makeDynamicHeightSupport()
    }

    private lazy var image: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.logo)
        imageView.contentMode = .scaleAspectFit
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

    private lazy var scrollView: FadeScrollView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()

        message = messagingManager.getNextMessage(for: .newTabCard)
        if let message = message {
            applyGleanMessage(message)
        } else {
            applyDefaultCard()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    private func setupLayout() {
        cardView.addSubviews(ctaButton, image, textStackView, dismissButton)
        containerView.addSubview(cardView)
        scrollView.addSubview(containerView)
        addSubview(scrollView)

        let frameGuide = scrollView.frameLayoutGuide
        let contentGuide = scrollView.contentLayoutGuide

        NSLayoutConstraint.activate([
            // Constraints that set the size and position of the scroll view relative to its superview
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Constraints that set the size of the scrollable content area inside the scrollview
            frameGuide.leadingAnchor.constraint(equalTo: leadingAnchor),
            frameGuide.topAnchor.constraint(equalTo: topAnchor),
            frameGuide.trailingAnchor.constraint(equalTo: trailingAnchor),
            frameGuide.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            contentGuide.widthAnchor.constraint(equalTo: frameGuide.widthAnchor),

            cardView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: UX.standardSpacing),
            cardView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -UX.bottomCardSafeSpace),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: UX.standardSpacing),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -UX.standardSpacing),
            cardView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cardView.widthAnchor.constraint(equalToConstant: UX.cardSize.width),

            image.centerYAnchor.constraint(equalTo: textStackView.centerYAnchor),
            image.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.standardSpacing),
            image.widthAnchor.constraint(equalToConstant: UX.logoSize.width),
            image.heightAnchor.constraint(equalToConstant: UX.logoSize.height),

            textStackView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor),
            textStackView.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: UX.standardSpacing),
            textStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.standardSpacing),
            textStackView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -UX.standardSpacing),

            dismissButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: UX.dismissButtonSpacing),
            dismissButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.dismissButtonSpacing),
            dismissButton.heightAnchor.constraint(equalToConstant: UX.dismissButtonSize.height),
            dismissButton.widthAnchor.constraint(equalToConstant: UX.dismissButtonSize.width),

            ctaButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: UX.standardSpacing),
            ctaButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -UX.standardSpacing),
            ctaButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -UX.standardSpacing),
            ctaButton.heightAnchor.constraint(greaterThanOrEqualToConstant: UX.learnHowButtonSize.height),
        ])

        heightConstraint = heightAnchor.constraint(equalToConstant: 999)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Set the view height based on card height, needed since we have dynamic height
        // of a scroll view in a stack view
        guard cardView.frame.height != 0 else { return }

        let idealHeight = cardView.frame.height + UX.standardSpacing + UX.bottomCardSafeSpace
        let newHeight = min(maxHeight, idealHeight)

        heightConstraint?.constant = newHeight
        heightConstraint?.isActive = true
    }

    // Currently limiting the banner height so user can still access the collection view (on bigger font sizes)
    // If banner content is greater than max threshold, the banner will scroll
    func adjustMaxHeight(_ maxHeight: CGFloat) {
        self.maxHeight = maxHeight
    }

    func applyTheme() {
        cardView.backgroundColor = UIColor.theme.homeTabBanner.backgroundColor
        bannerTitle.textColor = UIColor.theme.homeTabBanner.textColor
        descriptionText.textColor = UIColor.theme.homeTabBanner.textColor
        dismissButton.imageView?.tintColor = UIColor.theme.homeTabBanner.textColor
        backgroundColor = .clear
    }

    // MARK: - Message setup

    /// Default card (evergreen message) is applied when there's no GleanPlumbMessage available
    private func applyDefaultCard() {
        bannerTitle.text = BannerCopy.HomeTabBannerTitle
        descriptionText.text = BannerCopy.HomeTabBannerDescription
        ctaButton.setTitle(BannerCopy.HomeTabBannerButton, for: .normal)

        TelemetryWrapper.recordEvent(category: .information, method: .view, object: .homeTabBannerEvergreen)
    }

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
        messagingManager.onMessageDisplayed(message)
    }

    // MARK: Actions

    @objc private func dismissCard() {
        self.dismissClosure?()

        guard let message = message else {
            /// If we're here, that means we've shown the evergreen. Handle it as we always did.
            UserDefaults.standard.set(true, forKey: PrefsKeys.DidDismissDefaultBrowserMessage)
            TelemetryWrapper.gleanRecordEvent(category: .action, method: .tap, object: .dismissDefaultBrowserCard)

            return
        }

        messagingManager.onMessageDismissed(message)
    }

    /// The surface needs to handle CTAs a certain way when there's a message OR the evergreen.
    @objc func handleCTA() {
        self.dismissClosure?()

        guard let message = message else {
            /// If we're here, that means we've shown the evergreen. Handle it as we always did.
            BrowserViewController.foregroundBVC().presentDBOnboardingViewController(true)
            TelemetryWrapper.gleanRecordEvent(category: .action, method: .tap, object: .goToSettingsDefaultBrowserCard)

            /// The evergreen needs to be treated like the other messages - once interacted with, don't show it.
            UserDefaults.standard.set(true, forKey: PrefsKeys.DidDismissDefaultBrowserMessage)

            // Set default browser onboarding did show to true so it will not show again after user clicks this button
            UserDefaults.standard.set(true, forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)

            return
        }

        messagingManager.onMessagePressed(message)
    }
}
