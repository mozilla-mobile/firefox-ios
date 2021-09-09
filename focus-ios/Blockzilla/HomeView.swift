/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Telemetry

protocol HomeViewDelegate: class {
    func shareTrackerStatsButtonTapped()
    func didTapTip(_ tip: TipManager.Tip)
}

class HomeView: UIView {
    weak var delegate: HomeViewDelegate?
    private let tipView = UIView()
    private let trackerStatsLabel = SmartLabel()
    private let tipTitleLabel = SmartLabel()
    private let tipDescriptionLabel = SmartLabel()
    private let pageControl = TipsPageControl()
    private let shieldLogo = UIImageView()
    private let textLogo = UIImageView()
    private let tipManager: TipManager

    let toolbar = HomeViewToolbar()
    let trackerStatsShareButton = UIButton()

    deinit {
        NotificationCenter.default.removeObserver(self)
        tipView.gestureRecognizers?.removeAll()
    }

    init(tipManager: TipManager) {
        self.tipManager = tipManager
        super.init(frame: CGRect.zero)
        rotated()
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        let swipeNext = UISwipeGestureRecognizer(target: self, action: #selector(HomeView.swipeNextTip))
        swipeNext.direction = .left
        tipView.addGestureRecognizer(swipeNext)
        
        let swipePrevious = UISwipeGestureRecognizer(target: self, action: #selector(HomeView.swipePreviousTip))
        swipePrevious.direction = .right
        tipView.addGestureRecognizer(swipePrevious)

        textLogo.image = AppInfo.isKlar ? #imageLiteral(resourceName: "img_klar_wordmark") : #imageLiteral(resourceName: "img_focus_wordmark")
        textLogo.contentMode = .scaleAspectFit
        addSubview(textLogo)

        addSubview(toolbar)

        addSubview(tipView)
        tipView.isHidden = true

        tipTitleLabel.textColor = UIConstants.colors.defaultFont
        tipTitleLabel.font = UIConstants.fonts.shareTrackerStatsLabel
        tipTitleLabel.numberOfLines = 0
        tipTitleLabel.minimumScaleFactor = UIConstants.layout.homeViewLabelMinimumScale
        tipView.addSubview(tipTitleLabel)

        tipDescriptionLabel.textColor = .accent
        tipDescriptionLabel.font = UIConstants.fonts.shareTrackerStatsLabel
        tipDescriptionLabel.numberOfLines = 0
        tipDescriptionLabel.minimumScaleFactor = UIConstants.layout.homeViewLabelMinimumScale
        tipView.addSubview(tipDescriptionLabel)
        
        pageControl.numberOfPages = tipManager.numberOfTips()
        addSubview(pageControl)
        

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
        trackerStatsShareButton.layer.borderWidth = 1.0
        trackerStatsShareButton.layer.cornerRadius = 4
        tipView.addSubview(trackerStatsShareButton)

        textLogo.snp.makeConstraints { make in
            make.centerX.equalTo(self)
            make.top.equalTo(snp.centerY).offset(UIConstants.layout.textLogoOffset)
            make.left.equalTo(self.snp.left).offset(UIConstants.layout.textLogoMargin)
            make.right.equalTo(self.snp.left).offset(-UIConstants.layout.textLogoMargin)
        }

        tipView.snp.makeConstraints { make in
            make.bottom.equalTo(toolbar.snp.top).offset(UIConstants.layout.shareTrackersBottomOffset)
            make.height.equalTo(UIConstants.layout.shareTrackersHeight)
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(280)
            make.width.lessThanOrEqualToSuperview().offset(-32)
        }
        
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(toolbar.snp.top).offset(-6)
        }
        
        tipDescriptionLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        tipTitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(tipDescriptionLabel.snp.top)
        }

        toolbar.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalTo(safeAreaLayoutGuide)
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

        if let tip = tipManager.fetchTip() {
            showTipView()
            hideTrackerStatsShareButton()
            showTextTip(tip)
            tipManager.currentTip = tip
        } else {
            showTipView()
            hideTextTip()
            showTrackerStatsShareButton(text: tipManager.shareTrackersDescription())
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.trackerStatsShareButton)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showTipView() {
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

    @objc private func rotated() {
        if UIApplication.shared.orientation?.isLandscape == true {
            hideTextLogo()
        } else {
            showTextLogo()
        }
    }

    private func hideTextLogo() {
        textLogo.isHidden = true
    }

    private func showTextLogo() {
        textLogo.isHidden = false
    }

    func showTextTip(_ tip: TipManager.Tip) {
        tipTitleLabel.text = tip.title
        tipTitleLabel.sizeToFit()
        tipTitleLabel.isHidden = false
        if let description = tip.description, tip.action != nil {
            tipDescriptionLabel.text = description
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
        guard let tip = tipManager.currentTip else { return }
        delegate?.didTapTip(tip)
    }
    
    @objc private func swipeNextTip() {
        if let nextTip = tipManager.getNextTip() {
            showTextTip(nextTip)
            pageControl.currentPage = tipManager.currentTipIndex()
        }
    }

    @objc private func swipePreviousTip() {
        if let previousTip = tipManager.getPreviousTip() {
            showTextTip(previousTip)
            pageControl.currentPage = tipManager.currentTipIndex()
        }
    }
}
