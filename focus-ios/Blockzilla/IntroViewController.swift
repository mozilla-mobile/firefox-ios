/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Foundation
import Telemetry

class IntroViewController: UIViewController {

    let pageControl = PageControl()
    let skipButton = UIButton()
    private let backgroundDark = GradientBackgroundView()
    private let backgroundBright = GradientBackgroundView(alpha: 0.8)

    var isBright: Bool = false {
        didSet {
            backgroundDark.animateHidden(isBright, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
            backgroundBright.animateHidden(!isBright, duration: UIConstants.layout.urlBarTransitionAnimationDuration)
        }
    }

    var pageViewController: ScrollViewController = ScrollViewController() {
        didSet {
            pageViewController.scrollViewControllerDelegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        view.addSubview(backgroundDark)

        backgroundBright.isHidden = true
        backgroundBright.alpha = 0
        view.addSubview(backgroundBright)

        backgroundDark.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        backgroundBright.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        pageViewController = ScrollViewController()
        pageControl.delegate = pageViewController
        addChild(pageViewController)
        view.addSubview(pageViewController.view)

        view.addSubview(pageControl.stack)
        view.addSubview(skipButton)

        pageControl.backgroundColor = .clear
        pageControl.isUserInteractionEnabled = false
        pageControl.stack.snp.makeConstraints { make in
            make.top.equalTo(pageViewController.view.snp.centerY).offset(UIConstants.layout.introScreenHeight/2 + UIConstants.layout.pagerCenterOffsetFromScrollViewBottom).priority(.high)
            make.centerX.equalTo(self.view)
            make.bottom.lessThanOrEqualTo(self.view).offset(UIConstants.layout.introViewPageControlOffset).priority(.required)
        }

        skipButton.backgroundColor = .clear
        skipButton.setTitle(UIConstants.strings.SkipIntroButtonTitle, for: .normal)
        skipButton.titleLabel?.font = .footnote14
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.sizeToFit()
        skipButton.accessibilityIdentifier = "IntroViewController.button"
        skipButton.addTarget(self, action: #selector(IntroViewController.didTapSkipButton), for: .touchUpInside)

        skipButton.snp.makeConstraints { make in
            make.bottom.equalTo(pageViewController.view.snp.centerY).offset(-UIConstants.layout.introScreenHeight/2 - UIConstants.layout.pagerCenterOffsetFromScrollViewBottom).priority(.high)
            make.leading.equalTo(self.view.snp.centerX).offset(-UIConstants.layout.introScreenWidth/2)
            make.leading.top.greaterThanOrEqualTo(self.view).offset(UIConstants.layout.introViewSkipButtonOffset).priority(.required)
        }
    }

    @objc func didTapSkipButton() {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.onboarding, value: "skip")
        backgroundDark.removeFromSuperview()
        backgroundBright.removeFromSuperview()
        dismiss(animated: true, completion: nil)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return (UIDevice.current.userInterfaceIdiom == .phone) ? .portrait : .allButUpsideDown
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension IntroViewController: ScrollViewControllerDelegate {
    func scrollViewController(scrollViewController: ScrollViewController, didDismissSlideDeck bool: Bool) {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.onboarding, value: "finish")
        backgroundDark.removeFromSuperview()
        backgroundBright.removeFromSuperview()
        dismiss(animated: true, completion: nil)
    }

    func scrollViewController(scrollViewController: ScrollViewController, didUpdatePageCount count: Int) {
        pageControl.numberOfPages = count
    }

    func scrollViewController(scrollViewController: ScrollViewController, didUpdatePageIndex index: Int) {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.show, object: TelemetryEventObject.onboarding, value: String(index))
        pageControl.currentPage = index
        if index == pageControl.numberOfPages - 1 {
            isBright = true
        } else {
            isBright = false
        }
    }
}
