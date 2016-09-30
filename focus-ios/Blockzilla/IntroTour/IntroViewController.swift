/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

protocol IntroViewControllerDelegate: class {
    func introViewControllerWillDismiss(_ introViewController: IntroViewController)
}

class IntroViewController: UIViewController, UIScrollViewDelegate, IntroSlideFinishDelegate {
    weak var delegate: IntroViewControllerDelegate?

    fileprivate let detector = BlockerEnabledDetector.makeInstance()

    fileprivate var pageControl: UIPageControl!
    fileprivate var scrollView: UIScrollView!
    fileprivate let finishSlide = IntroSlideFinish()
    fileprivate let skipButton = UIButton()

    override func viewDidLoad() {
        view.backgroundColor = UIConstants.Colors.Background

        let welcomeSlide = IntroSlideWelcome()
        let howToSlide = IntroSlideHowTo()
        finishSlide.delegate = self
        let introSlides = [welcomeSlide, howToSlide, finishSlide]

        let titleView = TitleView()
        view.addSubview(titleView)

        skipButton.setTitle(NSLocalizedString("Skip", comment: "Button at top of the last intro screen when the app is not enabled"), for: UIControlState())
        skipButton.setTitleColor(UIConstants.Colors.FocusBlue, for: UIControlState())
        skipButton.setTitleColor(UIConstants.Colors.ButtonHighlightedColor, for: UIControlState.highlighted)
        skipButton.addTarget(self, action: #selector(IntroViewController.skipClicked(_:)), for: UIControlEvents.touchUpInside)
        skipButton.titleLabel?.font = UIConstants.Fonts.DefaultFontSemibold
        skipButton.isHidden = true
        view.addSubview(skipButton)

        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)

        let slideStack = UIStackView()
        scrollView.addSubview(slideStack)

        pageControl = UIPageControl()
        pageControl.pageIndicatorTintColor = UIConstants.Colors.DefaultFont.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = UIConstants.Colors.DefaultFont
        pageControl.numberOfPages = introSlides.count
        pageControl.addTarget(self, action: #selector(IntroViewController.changePage(_:)), for: UIControlEvents.valueChanged)
        view.addSubview(pageControl)

        titleView.snp.makeConstraints { make in
            make.top.equalTo(self.view).offset(20)
            make.centerX.equalTo(self.view)
        }

        skipButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleView)
            make.trailing.equalTo(self.view).offset(UIConstants.Layout.NavigationDoneOffset)
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleView.snp.bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }

        slideStack.snp.makeConstraints { make in
            make.edges.equalTo(self.scrollView)
        }

        for slide in introSlides {
            slideStack.addArrangedSubview(slide)
            slide.snp.makeConstraints { make in
                make.size.equalTo(self.scrollView)
            }
        }

        pageControl.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottom).offset(-15)
        }

        updateEnabledState()

        NotificationCenter.default.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }

    fileprivate func updateEnabledState() {
        updateSkipButton()
        finishSlide.enabledState = IntroSlideFinish.EnabledState.checking
        detector.detectEnabled(view) { enabled in
            if enabled {
                self.finishSlide.enabledState = IntroSlideFinish.EnabledState.enabled
            } else {
                self.finishSlide.enabledState = IntroSlideFinish.EnabledState.disabled
            }
            self.updateSkipButton()
        }
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            let pageXOffset = CGFloat(self.pageControl.currentPage) * self.scrollView.frame.size.width
            self.scrollView.setContentOffset(CGPoint(x: pageXOffset, y: 0), animated: false)
        }, completion: nil)
    }

    @objc func applicationDidBecomeActive(_ sender: UIApplication) {
        updateEnabledState()
    }

    @objc func changePage(_ sender: UIPageControl) {
        let pageXOffset = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: pageXOffset, y: 0), animated: true)
        updateSkipButton()
    }

    @objc func skipClicked(_ sender: UIButton) {
        delegate?.introViewControllerWillDismiss(self)
        dismiss(animated: true, completion: nil)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Update the page control indicator when swiping between slides.
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = page
        updateSkipButton()
    }

    fileprivate func updateSkipButton() {
        let hidden = pageControl.currentPage < 2 || finishSlide.enabledState == IntroSlideFinish.EnabledState.enabled
        skipButton.animateHidden(hidden, duration: 0.2)
    }

    func introSlideFinishDidPressGetStarted(_ introSlideFinish: IntroSlideFinish) {
        delegate?.introViewControllerWillDismiss(self)
        dismiss(animated: true, completion: nil)
    }
}
