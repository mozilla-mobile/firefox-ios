// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Storage
import Shared
import UIKit

struct HomeTabBannerUX {
    static let cardSize = CGSize(width: 360, height: 224)
    static let logoSize = CGSize(width: 64, height: 64)
    static let learnHowButtonSize: CGSize = CGSize(width: 304, height: 44)
}

/// The DefaultBrowserCard is one UI surface that is being targeted for experimentation with `GleanPlumb` AKA Messaging.

class HomeTabBanner: UIView, MessagingManagable {
    
    // MARK: - Properties
    
    public var dismissClosure: (() -> Void)?
    var message: Message?
    
    // UI
    private lazy var title: UILabel = .build { label in
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

    private lazy var CTAButton: UIButton = .build { [weak self] button in
        button.backgroundColor = UIColor.Photon.Blue50
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.accessibilityIdentifier = "Home.learnMoreDefaultBrowserbutton"
        button.addTarget(self, action: #selector(self?.handleCTA), for: .touchUpInside)
    }

    private lazy var image: UIImageView = .build { imageView in
        imageView.image = UIImage(named: "splash")
        imageView.contentMode = .scaleAspectFit
    }

    private lazy var dismissButton: UIButton = .build { [weak self] button in
        button.setImage(UIImage(named: "nav-stop")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.tintColor = UIColor.theme.defaultBrowserCard.textColor
        button.addTarget(self, action: #selector(self?.dismissCard), for: .touchUpInside)
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
        
        cardView.addSubviews(CTAButton, image, title, descriptionText, dismissButton)
        containerView.addSubview(cardView)
        scrollView.addSubview(containerView)
        addSubview(scrollView)

        let frameGuide = scrollView.frameLayoutGuide
        let contentGuide = scrollView.contentLayoutGuide
        
        NSLayoutConstraint.activate([
            // Constraints that set the size and position of the scroll view relative to its superview
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

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
            cardView.widthAnchor.constraint(equalToConstant: HomeTabBannerUX.cardSize.width),
            cardView.heightAnchor.constraint(equalToConstant: HomeTabBannerUX.cardSize.height),
            
            image.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 48),
            image.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            image.widthAnchor.constraint(equalToConstant: HomeTabBannerUX.logoSize.width),
            image.heightAnchor.constraint(equalToConstant: HomeTabBannerUX.logoSize.height),

            title.topAnchor.constraint(equalTo: image.topAnchor, constant: -16),
            title.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),

            descriptionText.topAnchor.constraint(equalTo: title.bottomAnchor),
            descriptionText.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            descriptionText.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            descriptionText.bottomAnchor.constraint(greaterThanOrEqualTo: CTAButton.topAnchor, constant: -16),

            dismissButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            dismissButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            dismissButton.heightAnchor.constraint(equalToConstant: 16),
            dismissButton.widthAnchor.constraint(equalToConstant: 16),

            CTAButton.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            CTAButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            CTAButton.widthAnchor.constraint(equalToConstant: HomeTabBannerUX.learnHowButtonSize.width),
            CTAButton.heightAnchor.constraint(equalToConstant: HomeTabBannerUX.learnHowButtonSize.height)
        ])
    }
    
    private func applyMessage() {
        guard let message = message else {
            /// No messages to display, so resort to this card's default behavior.
            title.text = String.DefaultBrowserCardTitle
            descriptionText.text = String.DefaultBrowserCardDescription
            CTAButton.setTitle(String.DefaultBrowserCardButton, for: .normal)
            
            return
        }
        
        title.text = message.messageData.title ?? String.DefaultBrowserCardTitle
        descriptionText.text = message.messageData.text
        CTAButton.setTitle(message.messageData.buttonLabel ?? String.DefaultBrowserCardButton, for: .normal)
        
        /// Begin the process of updating message metadata.
        messagingManager.onMessageDisplayed(message: message)
    }
    
    @objc private func dismissCard() {
        self.dismissClosure?()
        
        
        /// Handle user dismissal of message.
        guard let message = message else { return }
        messagingManager.onMessageDismissed(message: message)
        
        
//        UserDefaults.standard.set(true, forKey: "DidDismissDefaultBrowserCard")
//        TelemetryWrapper.gleanRecordEvent(category: .action, method: .tap, object: .dismissDefaultBrowserCard)
        
    }
    
    /// The surface needs to handle CTAs a certain way.
    @objc private func handleCTA() {
        guard let message = message else { return }
        
        
        
        /// Substitute here before
//        message.action
        
        messagingManager.onMessagePressed(message: message)
        
    }
    
    func applyTheme() {
        cardView.backgroundColor = UIColor.theme.defaultBrowserCard.backgroundColor
        title.textColor = UIColor.theme.defaultBrowserCard.textColor
        descriptionText.textColor = UIColor.theme.defaultBrowserCard.textColor
        dismissButton.imageView?.tintColor = UIColor.theme.defaultBrowserCard.textColor
        containerView.backgroundColor = .clear
        backgroundColor = .clear
    }
}
