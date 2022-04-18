/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Telemetry
import SnapKit
import Onboarding

protocol HomeViewControllerDelegate: AnyObject {
    func homeViewControllerDidTapShareTrackers(_ controller: HomeViewController, sender: UIButton)
    func homeViewControllerDidTapTip(_ controller: HomeViewController, tip: TipManager.Tip)
    func homeViewControllerDidTouchEmptyArea(_ controller: HomeViewController)
}

class HomeViewController: UIViewController {

    weak var delegate: HomeViewControllerDelegate?
    private let tipView = UIView()

    private lazy var textLogo: UIImageView = {
        let textLogo = UIImageView()
        textLogo.image = AppInfo.isKlar ? #imageLiteral(resourceName: "img_klar_wordmark") : #imageLiteral(resourceName: "img_focus_wordmark")
        textLogo.contentMode = .scaleAspectFit
        return textLogo
    }()

    private let tipManager: TipManager
    private lazy var tipsViewController = TipsPageViewController(
        tipManager: tipManager,
        tipTapped: didTap(tip:),
        tapOutsideAction: dismissKeyboard
    )

    public var tipViewTop: ConstraintItem { tipView.snp.top }

    var onboardingEventsHandler: OnboardingEventsHandler!
    let toolbar = HomeViewToolbar()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    init(tipManager: TipManager) {
        self.tipManager = tipManager
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        rotated()
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)

        self.view.addSubview(textLogo)
        self.view.addSubview(toolbar)
        self.view.addSubview(tipView)

        textLogo.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(self.view.snp.centerY).offset(UIConstants.layout.textLogoOffset)
            make.left.equalTo(self.view.snp.left).offset(UIConstants.layout.textLogoMargin)
            make.right.equalTo(self.view.snp.left).offset(-UIConstants.layout.textLogoMargin)
        }

        tipView.snp.makeConstraints { make in
            make.bottom.equalTo(toolbar.snp.top).inset(UIConstants.layout.tipViewBottomOffset)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(UIConstants.layout.tipViewHeight)
        }

        toolbar.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.trailing.equalTo(self.view.safeAreaLayoutGuide)
        }

        refreshTipsDisplay()
        install(tipsViewController, on: tipView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshTipsDisplay() {
        if let tip = tipManager.fetchFirstTip(), !onboardingEventsHandler.shouldShowNewOnboarding() {
            logTelemetry(for: tip)
            tipsViewController.setupPageController(with: .showTips)
        } else {
            tipsViewController.setupPageController(
                with: .showEmpty(
                    controller: ShareTrackersViewController(
                        trackerTitle: tipManager.shareTrackersDescription(),
                        shareTap: { [weak self] sender in
                            guard let self = self else { return }
                            self.delegate?.homeViewControllerDidTapShareTrackers(self, sender: sender)
                        }
                    )))
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.trackerStatsShareButton)
        }
    }

    @objc private func rotated() {
        if UIApplication.shared.orientation?.isLandscape == true {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // On iPad in landscape we only show the tips.
                hideTextLogo()
                showTips()
            } else {
                // On iPhone in landscape we show neither.
                hideTextLogo()
                hideTips()
            }
        } else {
            // In portrait on any form factor we show both.
            showTextLogo()
            showTips()
        }
    }

    private func hideTextLogo() {
        textLogo.isHidden = true
    }

    private func showTextLogo() {
        textLogo.isHidden = false
    }

    private func hideTips() {
        tipsViewController.view.isHidden = true
    }

    private func showTips() {
        tipsViewController.view.isHidden = false
    }

    func logTelemetry(for tip: TipManager.Tip) {

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

    func updateUI(urlBarIsActive: Bool, isBrowsing: Bool = false) {
        toolbar.isHidden = urlBarIsActive

        tipView.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(UIConstants.layout.tipViewHeight)

            if isBrowsing {
                make.height.equalTo(0)
            }
            if urlBarIsActive {
                make.bottom.equalToSuperview()
            } else {
                make.bottom.equalTo(toolbar.snp.top).inset(UIConstants.layout.tipViewBottomOffset)
            }
        }

        if UIScreen.main.bounds.height ==  UIConstants.layout.iPhoneSEHeight {
            textLogo.snp.updateConstraints{ make in
                make.top.equalTo(self.view.snp.centerY).offset(urlBarIsActive ?  UIConstants.layout.textLogoOffsetSmallDevice : UIConstants.layout.textLogoOffset)
            }
        }
    }

    private func didTap(tip: TipManager.Tip) {
        delegate?.homeViewControllerDidTapTip(self, tip : tip)
    }

    private func dismissKeyboard() {
        delegate?.homeViewControllerDidTouchEmptyArea(self)
    }
}
