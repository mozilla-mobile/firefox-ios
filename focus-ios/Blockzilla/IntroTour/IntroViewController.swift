/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

protocol IntroViewControllerDelegate: class {
    func introViewControllerWillDismiss(introViewController: IntroViewController)
}

class IntroViewController: UIViewController, UIScrollViewDelegate, IntroSlideFinishDelegate, IntroSlideHowToDelegate {
    weak var delegate: IntroViewControllerDelegate?

    private var pageControl: UIPageControl!
    private var scrollView: UIScrollView!
    private let enabledDetector = BlockerEnabledDetector()
    private let finishSlide = IntroSlideFinish()
    private let skipButton = UIButton()

    override func viewDidLoad() {
        view.backgroundColor = UIConstants.Colors.Background

        let welcomeSlide = IntroSlideWelcome()
        let howToSlide = IntroSlideHowTo()
        howToSlide.delegate = self
        finishSlide.delegate = self
        let introSlides = [welcomeSlide, howToSlide, finishSlide]

        let titleView = TitleView()
        view.addSubview(titleView)

        skipButton.setTitle(NSLocalizedString("Skip", comment: "Button at top of the last intro screen when Focus is not enabled"), forState: UIControlState.Normal)
        skipButton.setTitleColor(UIConstants.Colors.FocusBlue, forState: UIControlState.Normal)
        skipButton.setTitleColor(UIConstants.Colors.ButtonHighlightedColor, forState: UIControlState.Highlighted)
        skipButton.addTarget(self, action: "skipClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        skipButton.titleLabel?.font = UIConstants.Fonts.DefaultFontSemibold
        skipButton.hidden = true
        view.addSubview(skipButton)

        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)

        let slideStack = UIStackView()
        scrollView.addSubview(slideStack)

        pageControl = UIPageControl()
        pageControl.pageIndicatorTintColor = UIConstants.Colors.DefaultFont.colorWithAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = UIConstants.Colors.DefaultFont
        pageControl.numberOfPages = introSlides.count
        pageControl.addTarget(self, action: Selector("changePage:"), forControlEvents: UIControlEvents.ValueChanged)
        view.addSubview(pageControl)

        titleView.snp_makeConstraints { make in
            make.top.equalTo(self.view).offset(20)
            make.centerX.equalTo(self.view)
        }

        skipButton.snp_makeConstraints { make in
            make.centerY.equalTo(titleView)
            make.trailing.equalTo(self.view).offset(UIConstants.Layout.NavigationDoneOffset)
        }

        scrollView.snp_makeConstraints { make in
            make.top.equalTo(titleView.snp_bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }

        slideStack.snp_makeConstraints { make in
            make.edges.equalTo(self.scrollView)
        }

        for slide in introSlides {
            slideStack.addArrangedSubview(slide)
            slide.snp_makeConstraints { make in
                make.size.equalTo(self.scrollView)
            }
        }

        pageControl.snp_makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.snp_bottom).offset(-15)
        }

        updateEnabledState()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationDidBecomeActive:", name: UIApplicationDidBecomeActiveNotification, object: nil)
    }

    private func updateEnabledState() {
        updateSkipButton()
        finishSlide.enabledState = IntroSlideFinish.EnabledState.Checking
        enabledDetector.detectEnabled(view) { enabled in
            if enabled {
                self.finishSlide.enabledState = IntroSlideFinish.EnabledState.Enabled
            } else {
                self.finishSlide.enabledState = IntroSlideFinish.EnabledState.Disabled
            }
            self.updateSkipButton()
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition({ _ in
            let pageXOffset = CGFloat(self.pageControl.currentPage) * self.scrollView.frame.size.width
            self.scrollView.setContentOffset(CGPointMake(pageXOffset, 0), animated: false)
        }, completion: nil)
    }

    @objc func applicationDidBecomeActive(sender: UIApplication) {
        updateEnabledState()
    }

    @objc func changePage(sender: UIPageControl) {
        let pageXOffset = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPointMake(pageXOffset, 0), animated: true)
        updateSkipButton()
    }

    @objc func skipClicked(sender: UIButton) {
        delegate?.introViewControllerWillDismiss(self)
        dismissViewControllerAnimated(true, completion: nil)
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // Update the page control indicator when swiping between slides.
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = page
        updateSkipButton()
    }

    private func updateSkipButton() {
        let hidden = pageControl.currentPage < 2 || finishSlide.enabledState == IntroSlideFinish.EnabledState.Enabled
        skipButton.animateHidden(hidden, duration: 0.2)
    }

    func introSlideHowToDidPressSettings(introSlideHowTo: IntroSlideHowTo) {
        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
    }

    func introSlideFinishDidPressGetStarted(introSlideFinish: IntroSlideFinish) {
        delegate?.introViewControllerWillDismiss(self)
        dismissViewControllerAnimated(true, completion: nil)
    }

    func introSlideFinishDidPressOpenSettings(introSlideFinish: IntroSlideFinish) {
        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
    }
}