/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol HomeViewDelegate: class {
    func homeViewDidPressSettings(homeView: HomeView)
    func shareTrackerStatsButtonTapped()
}

class HomeView: UIView {
    weak var delegate: HomeViewDelegate?
    private(set) var settingsButton: UIButton! = nil
    private let description1 = SmartLabel()
    private let description2 = SmartLabel()
    private let trackerStatsView = UIView()
    private let trackerStatsLabel = SmartLabel()
    
    init() {
        super.init(frame: CGRect.zero)

        let wordmark = AppInfo.config.wordmark
        let textLogo = UIImageView(image: wordmark)
        addSubview(textLogo)

        description1.textColor = .white
        description1.font = UIConstants.fonts.homeLabel
        description1.textAlignment = .center
        description1.text = UIConstants.strings.homeLabel1
        description1.numberOfLines = 0
        addSubview(description1)

        description2.textColor = .white
        description2.font = UIConstants.fonts.homeLabel
        description2.textAlignment = .center
        description2.text = UIConstants.strings.homeLabel2
        description2.numberOfLines = 0
        addSubview(description2)

        let settingsButton = UIButton()
        settingsButton.setImage(#imageLiteral(resourceName: "icon_settings"), for: .normal)
        settingsButton.addTarget(self, action: #selector(didPressSettings), for: .touchUpInside)
        settingsButton.accessibilityLabel = UIConstants.strings.browserSettings
        settingsButton.accessibilityIdentifier = "HomeView.settingsButton"
        addSubview(settingsButton)
        self.settingsButton = settingsButton
        
        addSubview(trackerStatsView)
        trackerStatsView.isHidden = true
        
        let shieldLogo = UIImageView(image: #imageLiteral(resourceName: "tracking_protection"))
        shieldLogo.tintColor = UIColor.white
        trackerStatsView.addSubview(shieldLogo)
        
        trackerStatsLabel.font = UIConstants.fonts.shareTrackerStatsLabel
        trackerStatsLabel.textColor = UIConstants.colors.defaultFont
        trackerStatsLabel.numberOfLines = 0
        trackerStatsLabel.minimumScaleFactor = 0.65
        trackerStatsView.addSubview(trackerStatsLabel)
        
        let trackerStatsShareButton = UIButton()
        trackerStatsShareButton.setTitleColor(UIConstants.colors.defaultFont, for: .normal)
        trackerStatsShareButton.titleLabel?.font = UIConstants.fonts.shareTrackerStatsLabel
        trackerStatsShareButton.titleLabel?.textAlignment = .center
        trackerStatsShareButton.setTitle(UIConstants.strings.share, for: .normal)
        trackerStatsShareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        trackerStatsShareButton.titleLabel?.numberOfLines = 0
        trackerStatsShareButton.layer.borderColor = UIConstants.colors.defaultFont.cgColor
        trackerStatsShareButton.layer.borderWidth = 1.0;
        trackerStatsShareButton.layer.cornerRadius = 4
        trackerStatsView.addSubview(trackerStatsShareButton)

        textLogo.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(snp.centerY).offset(-10)
        }

        description1.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(textLogo.snp.bottom).offset(25)
        }

        description2.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(description1.snp.bottom).offset(5)
        }

        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(self).offset(15)
            make.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            make.height.width.equalTo(24)
        }
        
        trackerStatsView.snp.makeConstraints { make in
            make.bottom.equalTo(self).offset(-24)
            make.height.equalTo(20)
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(280)
            make.width.lessThanOrEqualToSuperview().offset(-32)
        }
        
        trackerStatsLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(shieldLogo.snp.right).offset(8)
            make.right.equalTo(trackerStatsShareButton.snp.left).offset(-13)
            make.height.equalToSuperview()
        }
        
        shieldLogo.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
        
        trackerStatsShareButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.width.equalTo(80).priority(500)
            make.width.greaterThanOrEqualTo(50)
            make.height.equalTo(36)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didPressSettings() {
        delegate?.homeViewDidPressSettings(homeView: self)
    }
    
    func showTrackerStatsShareButton(text: String) {
        trackerStatsLabel.text = text
        trackerStatsLabel.sizeToFit()
        trackerStatsView.isHidden = false
        description1.isHidden = true
        description2.isHidden = true
    }
    
    func hideTrackerStatsShareButton() {
        trackerStatsView.isHidden = true
        description1.isHidden = false
        description2.isHidden = false
    }
    
    @objc private func shareTapped() {
        delegate?.shareTrackerStatsButtonTapped()
    }
    
    func setHighlightWhatsNew(shouldHighlight: Bool) {
        if shouldHighlight {
            settingsButton.setImage(UIImage(named: "preferences_updated"), for: .normal)
        } else {
            settingsButton.setImage(#imageLiteral(resourceName: "icon_settings"), for: .normal)
        }
    }
}
