/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Foundation
import Telemetry

struct IntroViewControllerUX {
    static let Width = 302
    static let Height = UIScreen.main.bounds.width <= 320 ? 420 : 460
    static let MinimumFontScale: CGFloat = 0.5

    static let CardSlides = ["onboarding_1", "onboarding_2", "onboarding_3"]

    static let PagerCenterOffsetFromScrollViewBottom = UIScreen.main.bounds.width <= 320 ? 16 : 24

    static let StartBrowsingButtonColor = UIColor(rgb: 0x4990E2)
    static let StartBrowsingButtonHeight = 56

    static let CardTextLineHeight: CGFloat = UIScreen.main.bounds.width <= 320 ? 2 : 6
    static let CardTextWidth = UIScreen.main.bounds.width <= 320 ? 240 : 280
    static let CardTitleHeight = 50

    static let FadeDuration = 0.25
}

class IntroViewController: UIViewController {

    let pageControl = PageControl()
    let containerView = UIView()
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
            make.top.equalTo(pageViewController.view.snp.centerY).offset(IntroViewControllerUX.Height/2 + IntroViewControllerUX.PagerCenterOffsetFromScrollViewBottom).priority(.high)
            make.centerX.equalTo(self.view)
            make.bottom.lessThanOrEqualTo(self.view).offset(UIConstants.layout.introViewPageControlOffset).priority(.required)
        }

        skipButton.backgroundColor = .clear
        skipButton.setTitle(UIConstants.strings.SkipIntroButtonTitle, for: .normal)
        skipButton.titleLabel?.font = UIConstants.fonts.aboutText
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.sizeToFit()
        skipButton.accessibilityIdentifier = "IntroViewController.button"
        skipButton.addTarget(self, action: #selector(IntroViewController.didTapSkipButton), for: .touchUpInside)

        skipButton.snp.makeConstraints { make in
            make.bottom.equalTo(pageViewController.view.snp.centerY).offset(-IntroViewControllerUX.Height/2 - IntroViewControllerUX.PagerCenterOffsetFromScrollViewBottom).priority(.high)
            make.leading.equalTo(self.view.snp.centerX).offset(-IntroViewControllerUX.Width/2)
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
