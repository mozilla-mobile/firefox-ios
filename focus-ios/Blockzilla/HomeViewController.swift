/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Onboarding

protocol HomeViewControllerDelegate: AnyObject {
    func homeViewControllerDidTapShareTrackers(_ controller: HomeViewController, sender: UIButton)
    func homeViewControllerDidTapTip(_ controller: HomeViewController, tip: TipManager.Tip)
    func homeViewControllerDidTouchEmptyArea(_ controller: HomeViewController)
}

class HomeViewController: UIViewController {
    weak var delegate: HomeViewControllerDelegate?
    private lazy var tipView: UIView = {
        let tipView = UIView()
        tipView.translatesAutoresizingMaskIntoConstraints = false
        return tipView
    }()

    private lazy var textLogo: UIImageView = {
        let textLogo = UIImageView()
        textLogo.image = AppInfo.isKlar ? #imageLiteral(resourceName: "img_klar_wordmark") : #imageLiteral(resourceName: "img_focus_wordmark")
        textLogo.contentMode = .scaleAspectFit
        textLogo.translatesAutoresizingMaskIntoConstraints = false
        return textLogo
    }()

    private let tipManager: TipManager
    private lazy var tipsViewController = TipsPageViewController(
        tipManager: tipManager,
        tipTapped: didTap(tip:),
        tapOutsideAction: dismissKeyboard
    )

    var onboardingEventsHandler: OnboardingEventsHandling!
    let toolbar: HomeViewToolbar = {
        let toolbar = HomeViewToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        return toolbar
    }()

    var tipViewConstraints: [NSLayoutConstraint] = []
    var textLogoTopConstraints: [NSLayoutConstraint] = []

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

        NSLayoutConstraint.activate([
            textLogo.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            textLogo.topAnchor.constraint(equalTo: self.view.centerYAnchor, constant: UIConstants.layout.textLogoOffset),
            textLogo.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: UIConstants.layout.textLogoMargin),
            textLogo.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -UIConstants.layout.textLogoMargin)
        ])

        tipViewConstraints = [
            tipView.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: UIConstants.layout.tipViewBottomOffset),
            tipView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tipView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            tipView.heightAnchor.constraint(equalToConstant: UIConstants.layout.tipViewHeight)
        ]
        NSLayoutConstraint.activate(tipViewConstraints)

        NSLayoutConstraint.activate([
            toolbar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor)
        ])

        refreshTipsDisplay()
        install(tipsViewController, on: tipView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshTipsDisplay() {
        tipsViewController.setupPageController(
            with: .showEmpty(
                controller: ShareTrackersViewController(
                    trackerTitle: tipManager.shareTrackersDescription(),
                    shareTap: { [weak self] sender in
                        guard let self = self else { return }
                        self.delegate?.homeViewControllerDidTapShareTrackers(self, sender: sender)
                    }
                )))
    }

    @objc
    private func rotated() {
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

    func updateUI(urlBarIsActive: Bool, isBrowsing: Bool = false) {
        toolbar.isHidden = urlBarIsActive

        NSLayoutConstraint.deactivate(tipViewConstraints)
        tipViewConstraints = [
            tipView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            tipView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            tipView.heightAnchor.constraint(equalToConstant: UIConstants.layout.tipViewHeight),
            tipView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        ]
        if isBrowsing {
            tipViewConstraints.append(tipView.heightAnchor.constraint(equalToConstant: 0))
        }
        if urlBarIsActive {
            tipViewConstraints.append(tipView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor))
        } else {
            tipViewConstraints.append(tipView.bottomAnchor.constraint(equalTo: toolbar.topAnchor, constant: UIConstants.layout.tipViewBottomOffset))
        }
        NSLayoutConstraint.activate(tipViewConstraints)

        if UIScreen.main.bounds.height ==  UIConstants.layout.iPhoneSEHeight {
            NSLayoutConstraint.deactivate(textLogoTopConstraints)
            textLogoTopConstraints = [self.textLogo.topAnchor.constraint(equalTo: self.view.centerYAnchor, constant: urlBarIsActive ? UIConstants.layout.textLogoOffsetSmallDevice : UIConstants.layout.textLogoOffset)]
            NSLayoutConstraint.activate(textLogoTopConstraints)
        }
    }

    private func didTap(tip: TipManager.Tip) {
        delegate?.homeViewControllerDidTapTip(self, tip: tip)
    }

    private func dismissKeyboard() {
        delegate?.homeViewControllerDidTouchEmptyArea(self)
    }
}
