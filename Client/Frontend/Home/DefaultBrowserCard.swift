// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Storage
import Shared

class DefaultBrowserCard: UIView {
    
    // MARK: - Properties
    
    public var dismissClosure: (() -> Void)?
    
    // UI
    private lazy var title: UILabel = .build { label in
        label.text = String.DefaultBrowserCardTitle
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = UIColor.theme.defaultBrowserCard.textColor
    }
    private lazy var descriptionText: UILabel = .build { label in
        label.text = String.DefaultBrowserCardDescription
        label.numberOfLines = 4
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor.theme.defaultBrowserCard.textColor
    }
    private lazy var learnHowButton: UIButton = .build { [weak self] button in
        button.setTitle(String.PrivateBrowsingLearnMore, for: .normal) // TODO update string
        button.backgroundColor = UIColor.Photon.Blue50
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.accessibilityIdentifier = "Home.learnMoreDefaultBrowserbutton"
        button.addTarget(self, action: #selector(self?.showOnboarding), for: .touchUpInside)
    }
    private lazy var image: UIImageView = .build { imageView in
        imageView.image = UIImage(named: "splash")
        imageView.contentMode = .scaleAspectFit
    }
    private lazy var closeButton: UIButton = .build { [weak self] button in
        button.setImage(UIImage(named: "nav-stop")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.tintColor = UIColor.theme.defaultBrowserCard.textColor
        button.addTarget(self, action: #selector(self?.dismissCard), for: .touchUpInside)
    }
    private lazy var background: UIView = .build { view in
        view.backgroundColor = UIColor.theme.defaultBrowserCard.backgroundColor
        view.layer.cornerRadius = 12
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
    
    private func setupLayout() {
        background.addSubviews(learnHowButton, image, title, descriptionText, closeButton)
        addSubview(background)
        
        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            background.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            background.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            background.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            background.heightAnchor.constraint(equalToConstant: 224),
            
            image.topAnchor.constraint(equalTo: background.topAnchor, constant: 48),
            image.leadingAnchor.constraint(equalTo: background.leadingAnchor, constant: 16),
            image.widthAnchor.constraint(equalToConstant: 64),
            image.heightAnchor.constraint(equalToConstant: 64),
            
            title.topAnchor.constraint(equalTo: image.topAnchor, constant: -16),
            title.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            
            descriptionText.topAnchor.constraint(equalTo: title.bottomAnchor),
            descriptionText.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            descriptionText.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -12),
            
            closeButton.topAnchor.constraint(equalTo: background.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: background.trailingAnchor, constant: -16),
            closeButton.heightAnchor.constraint(equalToConstant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            
            learnHowButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            learnHowButton.bottomAnchor.constraint(equalTo: background.bottomAnchor, constant: -16),
            learnHowButton.widthAnchor.constraint(equalToConstant: 304),
            learnHowButton.heightAnchor.constraint(equalToConstant: 44)
        ])

    }
    
    @objc private func dismissCard() {
        self.dismissClosure?()
        UserDefaults.standard.set(true, forKey: "DidDismissDefaultBrowserCard")
        TelemetryWrapper.gleanRecordEvent(category: .action, method: .tap, object: .dismissDefaultBrowserCard)
    }
    
    @objc private func showOnboarding() {
        BrowserViewController.foregroundBVC().presentDBOnboardingViewController(true)
        TelemetryWrapper.gleanRecordEvent(category: .action, method: .tap, object: .goToSettingsDefaultBrowserCard)
        
        // Set default browser onboarding did show to true so it will not show again after user clicks this button
        UserDefaults.standard.set(true, forKey: PrefsKeys.KeyDidShowDefaultBrowserOnboarding)
    }
    
    func applyTheme() {
        background.backgroundColor = UIColor.theme.defaultBrowserCard.backgroundColor
        title.textColor = UIColor.theme.defaultBrowserCard.textColor
        descriptionText.textColor = UIColor.theme.defaultBrowserCard.textColor
        closeButton.imageView?.tintColor = UIColor.theme.defaultBrowserCard.textColor
        backgroundColor = UIColor.theme.homePanel.topSitesBackground
    }
}
