/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Telemetry

protocol HomeViewDelegate: class {
    func shareTrackerStatsButtonTapped()
    func tipTapped()
}

class HomeView: UIView {
    weak var delegate: HomeViewDelegate?
    private let privateBrowsingDescription = SmartLabel()
    private let browseEraseRepeatTagline = SmartLabel()
    private let tipView = UIView()
    private let trackerStatsLabel = SmartLabel()
    private let tipTitleLabel = SmartLabel()
    private let tipDescriptionLabel = SmartLabel()
    private let shieldLogo = UIImageView()
    
    let toolbar = HomeViewToolbar()
    let trackerStatsShareButton = UIButton()
    
    init(tipManager: TipManager? = nil) {
        super.init(frame: CGRect.zero)
        
        let wordmark = AppInfo.config.wordmark
        let textLogo = UIImageView(image: wordmark)
        addSubview(textLogo)

        privateBrowsingDescription.textColor = .white
        privateBrowsingDescription.font = UIConstants.fonts.homeLabel
        privateBrowsingDescription.textAlignment = .center
        privateBrowsingDescription.text = UIConstants.strings.homeLabel1
        privateBrowsingDescription.numberOfLines = 0
        addSubview(privateBrowsingDescription)

        browseEraseRepeatTagline.textColor = .white
        browseEraseRepeatTagline.font = UIConstants.fonts.homeLabel
        browseEraseRepeatTagline.textAlignment = .center
        browseEraseRepeatTagline.text = UIConstants.strings.homeLabel2
        browseEraseRepeatTagline.numberOfLines = 0
        addSubview(browseEraseRepeatTagline)
        
        addSubview(toolbar)
        
        addSubview(tipView)
        tipView.isHidden = true
        
        tipTitleLabel.textColor = UIConstants.colors.defaultFont
        tipTitleLabel.font = UIConstants.fonts.shareTrackerStatsLabel
        tipTitleLabel.numberOfLines = 0
        tipTitleLabel.minimumScaleFactor = UIConstants.layout.homeViewLabelMinimumScale
        tipView.addSubview(tipTitleLabel)
        
        tipDescriptionLabel.textColor = UIConstants.colors.defaultFont
        tipDescriptionLabel.font = UIConstants.fonts.shareTrackerStatsLabel
        tipDescriptionLabel.numberOfLines = 0
        tipDescriptionLabel.minimumScaleFactor = UIConstants.layout.homeViewLabelMinimumScale
        tipView.addSubview(tipDescriptionLabel)

        shieldLogo.image = #imageLiteral(resourceName: "tracking_protection")
        shieldLogo.tintColor = UIColor.white
        tipView.addSubview(shieldLogo)
        
        trackerStatsLabel.font = UIConstants.fonts.shareTrackerStatsLabel
        trackerStatsLabel.textColor = UIConstants.colors.defaultFont
        trackerStatsLabel.numberOfLines = 0
        trackerStatsLabel.minimumScaleFactor = UIConstants.layout.homeViewLabelMinimumScale
        tipView.addSubview(trackerStatsLabel)
        
        trackerStatsShareButton.setTitleColor(UIConstants.colors.defaultFont, for: .normal)
        trackerStatsShareButton.titleLabel?.font = UIConstants.fonts.shareTrackerStatsLabel
        trackerStatsShareButton.titleLabel?.textAlignment = .center
        trackerStatsShareButton.setTitle(UIConstants.strings.share, for: .normal)
        trackerStatsShareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
        trackerStatsShareButton.titleLabel?.numberOfLines = 0
        trackerStatsShareButton.layer.borderColor = UIConstants.colors.defaultFont.cgColor
        trackerStatsShareButton.layer.borderWidth = 1.0;
        trackerStatsShareButton.layer.cornerRadius = 4
        tipView.addSubview(trackerStatsShareButton)

        textLogo.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(snp.centerY).offset(UIConstants.layout.textLogoOffset)
        }

        privateBrowsingDescription.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(textLogo.snp.bottom).offset(25)
        }

        browseEraseRepeatTagline.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(privateBrowsingDescription.snp.bottom).offset(UIConstants.layout.homeViewTextOffset)
        }
        
        tipView.snp.makeConstraints { make in
            make.bottom.equalTo(toolbar.snp.top).offset(UIConstants.layout.shareTrackersBottomOffset)
            make.height.equalTo(UIConstants.layout.shareTrackersHeight)
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(280)
            make.width.lessThanOrEqualToSuperview().offset(-32)
        }
        
        tipDescriptionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        tipTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(tipDescriptionLabel.snp.top).offset(-UIConstants.layout.homeViewTextOffset)
        }
        
        toolbar.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().priority(.required)
        }
        
        trackerStatsShareButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.right.equalToSuperview()
            make.width.equalTo(80).priority(500)
            make.width.greaterThanOrEqualTo(50)
            make.height.equalToSuperview()
        }
        
        trackerStatsLabel.snp.makeConstraints { make in
            make.centerY.equalTo(trackerStatsShareButton.snp.centerY)
            make.left.equalTo(shieldLogo.snp.right).offset(8)
            make.right.equalTo(trackerStatsShareButton.snp.left).offset(-13)
            make.height.equalToSuperview()
        }
        
        shieldLogo.snp.makeConstraints { make in
            make.centerY.equalTo(trackerStatsShareButton.snp.centerY)
            make.left.equalToSuperview()
        }
        
        if let tipManager = tipManager, let tip = tipManager.fetchTip() {
            showTipView()
            switch tip.identifier {
            case TipManager.TipKey.shareTrackersTip:
                hideTextTip()
                let numberOfTrackersBlocked = UserDefaults.standard.integer(forKey: BrowserViewController.userDefaultsTrackersBlockedKey)
                showTrackerStatsShareButton(text: String(format: tip.title, String(numberOfTrackersBlocked)))
                Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.trackerStatsShareButton)
            default:
                hideTrackerStatsShareButton()
                showTextTip(tip)
            }
            tipManager.currentTip = tip
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showTipView() {
        privateBrowsingDescription.isHidden = true
        browseEraseRepeatTagline.isHidden = true
        tipView.isHidden = false
    }
    
    func showTrackerStatsShareButton(text: String) {
        trackerStatsLabel.text = text
        trackerStatsLabel.sizeToFit()
        trackerStatsLabel.isHidden = false
        trackerStatsShareButton.isHidden = false
        shieldLogo.isHidden = false
    }
    
    func hideTrackerStatsShareButton() {
        shieldLogo.isHidden = true
        trackerStatsLabel.isHidden = true
        trackerStatsShareButton.isHidden = true
    }
    
    func showTextTip(_ tip: TipManager.Tip) {
        tipTitleLabel.text = tip.title
        tipTitleLabel.sizeToFit()
        tipTitleLabel.isHidden = false
        if let description = tip.description, tip.showVc {
            tipDescriptionLabel.attributedText = NSAttributedString(string: description, attributes:
                [.underlineStyle: NSUnderlineStyle.single.rawValue])
            tipDescriptionLabel.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(HomeView.tapTip))
            tipDescriptionLabel.addGestureRecognizer(tap)
        } else {
            tipDescriptionLabel.text = tip.description
            tipDescriptionLabel.isUserInteractionEnabled = false
        }
        tipDescriptionLabel.sizeToFit()
        tipDescriptionLabel.isHidden = false
        
        switch tip.identifier {
        case TipManager.TipKey.autocompleteTip:
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.autocompleteTip)
        case TipManager.TipKey.biometricTip:
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.biometricTip)
        case TipManager.TipKey.requestDesktopTip:
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.requestDesktopTip)
        case TipManager.TipKey.siriEraseTip:
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.siriEraseTip)
        case TipManager.TipKey.siriFavoriteTip:
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.siriFavoriteTip)
        case TipManager.TipKey.sitesNotWorkingTip:
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.sitesNotWorkingTip)
        default:
            break
        }
    }
    
    func hideTextTip() {
        tipTitleLabel.isHidden = true
        tipDescriptionLabel.isHidden = true
    }
    
    @objc private func shareTapped() {
        delegate?.shareTrackerStatsButtonTapped()
    }
    
    @objc private func tapTip() {
        delegate?.tipTapped()
    }
}
