/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SnapKit
import Storage
import Shared

class DefaultBrowserCard: UIView {
    public var dismissClosure: (() -> Void)?
    lazy var title: UILabel = {
        let title = UILabel()
        title.text = String.DefaultBrowserCardTitle
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        title.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        title.textColor = UIColor.theme.defaultBrowserCard.textColor
        return title
    }()
    lazy var descriptionText: UILabel = {
        let descriptionText = UILabel()
        descriptionText.text = String.DefaultBrowserCardDescription
        descriptionText.numberOfLines = 0
        descriptionText.lineBreakMode = .byWordWrapping
        descriptionText.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        descriptionText.textColor = UIColor.theme.defaultBrowserCard.textColor
        return descriptionText
    }()
    lazy var learnHowButton: UIButton = {
        let button = UIButton()
        button.setTitle(String.PrivateBrowsingLearnMore, for: .normal) // TODO update string
        button.backgroundColor = UIColor.Photon.Blue50
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.accessibilityIdentifier = "Home.learnMoreDefaultBrowserbutton"
        return button
    }()
    lazy var image: UIImageView = {
        let imgView = UIImageView(image: #imageLiteral(resourceName: "splash"))
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "nav-stop")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.imageView?.tintColor = UIColor.theme.defaultBrowserCard.textColor
        return closeButton
    }()
    lazy var background: UIView = {
        let background = UIView()
        background.backgroundColor = UIColor.theme.defaultBrowserCard.backgroundColor
        background.layer.cornerRadius = 12
        background.layer.masksToBounds = true
        return background
    }()
    
    private var topView = UIView()
    private var labelView = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        topView.addSubview(labelView)
        topView.addSubview(image)
        
        background.addSubview(learnHowButton)
        background.addSubview(topView)
        background.addSubview(closeButton)
        
        labelView.axis = .vertical
        labelView.addArrangedSubview(title)
        labelView.addArrangedSubview(descriptionText)
        
        addSubview(background)
        
        setupConstraints()
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        background.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(20)
            make.right.bottom.equalToSuperview().offset(-20)
            make.height.greaterThanOrEqualTo(210)
        }
        topView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(learnHowButton.snp.top)
            make.height.greaterThanOrEqualTo(114)
        }
        image.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(18)
            make.right.equalTo(labelView.snp.left).offset(-18)
            make.height.width.equalTo(64)
            make.top.equalToSuperview().offset(45)
        }
        labelView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalTo(image.snp.right)
            make.width.lessThanOrEqualTo(223)
            make.bottom.equalTo(learnHowButton.snp.top).offset(-16)
            make.top.equalToSuperview().offset(30)
        }
        learnHowButton.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom).offset(16)
            make.bottom.right.equalToSuperview().offset(-16)
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(303)
            make.height.equalTo(44)
        }
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.height.width.equalTo(15)
        }
    }
    
    private func setupButtons() {
        closeButton.addTarget(self, action: #selector(dismissCard), for: .touchUpInside)
        learnHowButton.addTarget(self, action: #selector(showOnboarding), for: .touchUpInside)
    }
    
    @objc private func dismissCard() {
        self.dismissClosure?()
        UserDefaults.standard.set(true, forKey: "DidDismissDefaultBrowserCard")
        TelemetryWrapper.gleanRecordEvent(category: .action, method: .tap, object: .dismissDefaultBrowserCard)
        LeanPlumClient.shared.track(event: .dismissDefaultBrowserCard)
    }
    
    @objc private func showOnboarding() {
        BrowserViewController.foregroundBVC().presentDBOnboardingViewController(true)
        TelemetryWrapper.gleanRecordEvent(category: .action, method: .tap, object: .goToSettingsDefaultBrowserCard)
        LeanPlumClient.shared.track(event: .goToSettingsDefaultBrowserCard)
        
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
