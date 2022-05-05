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

    struct UX {
        static let cardSize = CGSize(width: 360, height: 224)
        static let logoSize = CGSize(width: 64, height: 64)
        static let learnHowButtonSize: CGSize = CGSize(width: 304, height: 44)
    }

    // MARK: - Properties

    public var dismissClosure: (() -> Void)?
    var message: GleanPlumbMessage?

    // UI
    private lazy var bannerTitle: UILabel = .build { label in
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor.theme.defaultBrowserCard.textColor
    }

    private lazy var descriptionText: UILabel = .build { label in
        label.numberOfLines = 4
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor.theme.defaultBrowserCard.textColor
    }

    private lazy var ctaButton: UIButton = .build { [weak self] button in
        button.backgroundColor = UIColor.Photon.Blue50
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.accessibilityIdentifier = a11y.ctaButton
        button.addTarget(self, action: #selector(self?.handleCTA), for: .touchUpInside)
    }

    private lazy var image: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.logo)
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var dismissButton: UIButton = .build { [weak self] button in
        button.setImage(UIImage(named: ImageIdentifiers.xMark)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.tintColor = UIColor.theme.defaultBrowserCard.textColor
        button.addTarget(self, action: #selector(self?.dismissCard), for: .touchUpInside)
    }

    private lazy var textStackView: UIStackView = .build { [weak self] stackView in
        guard let self = self else { return }
        stackView.addArrangedSubview(self.bannerTitle)
        stackView.addArrangedSubview(self.descriptionText)
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = -16
    }

    private lazy var scrollView: UIScrollView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var containerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var cardView: UIView = .build { view in
        view.backgroundColor = UIColor.theme.defaultBrowserCard.backgroundColor
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.message = messagingManager.getNextMessage(for: .newTabCard)

        setupLayout()
        applyMessage()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

            cardView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            cardView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            cardView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -20),
            cardView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cardView.widthAnchor.constraint(equalToConstant: UX.cardSize.width),
            cardView.heightAnchor.constraint(equalToConstant: UX.cardSize.height),

            image.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 48),
            image.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            image.widthAnchor.constraint(equalToConstant: UX.logoSize.width),
            image.heightAnchor.constraint(equalToConstant: UX.logoSize.height),

            textStackView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor),
            textStackView.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 16),
            textStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            textStackView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -8),

            dismissButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 8),
            dismissButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            dismissButton.heightAnchor.constraint(equalToConstant: 16),
            dismissButton.widthAnchor.constraint(equalToConstant: 16),

            ctaButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            ctaButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -8),
            ctaButton.widthAnchor.constraint(equalToConstant: UX.learnHowButtonSize.width),
            ctaButton.heightAnchor.constraint(equalToConstant: UX.learnHowButtonSize.height)
        ])
    }

    /// Apply message data, including handling of cases where certain parts of the message are missing.
    private func applyMessage() {
        /// If no messages exist, continue using our evergreen message.
        guard let message = message else {
            bannerTitle.text = String.DefaultBrowserCardTitle
            descriptionText.text = String.DefaultBrowserCardDescription
            ctaButton.setTitle(String.DefaultBrowserCardButton, for: .normal)

            TelemetryWrapper.recordEvent(category: .information, method: .view, object: .homeTabBannerEvergreen)
            return
        }

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

    @objc private func dismissCard() {
        self.dismissClosure?()

        guard let message = message else {
            /// If we're here, that means we've shown the evergreen. Handle it as we always did.
            UserDefaults.standard.set(true, forKey: PrefsKeys.DidDismissDefaultBrowserCard)
            TelemetryWrapper.gleanRecordEvent(category: .action, method: .tap, object: .dismissDefaultBrowserCard)

            return
        }

        messagingManager.onMessageDismissed(message)
    }

    /// The surface needs to handle CTAs a certain way when there's a message OR the evergreen.
    @objc func handleCTA() {
        guard let message = message else {
            /// If we're here, that means we've shown the evergreen. Handle it as we always did.
            BrowserViewController.foregroundBVC().presentDBOnboardingViewController(true)
            TelemetryWrapper.gleanRecordEvent(category: .action, method: .tap, object: .goToSettingsDefaultBrowserCard)

            // Set default browser onboarding did show to true so it will not show again after user clicks this button
            UserDefaults.standard.set(true, forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)

            return
        }

        messagingManager.onMessagePressed(message)
    }

    func applyTheme() {
        cardView.backgroundColor = UIColor.theme.defaultBrowserCard.backgroundColor
        bannerTitle.textColor = UIColor.theme.defaultBrowserCard.textColor
        descriptionText.textColor = UIColor.theme.defaultBrowserCard.textColor
        dismissButton.imageView?.tintColor = UIColor.theme.defaultBrowserCard.textColor
        containerView.backgroundColor = .clear
        backgroundColor = .clear
    }
}
