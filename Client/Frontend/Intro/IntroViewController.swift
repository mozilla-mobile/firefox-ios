/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

struct IntroViewControllerUX {
    static let Width = 375
    static let Height = 667

    static let CardSlides = ["organize", "customize", "share", "choose", "sync"]
    static let NumberOfCards = CardSlides.count

    static let PagerCenterOffsetFromScrollViewBottom = 30

    static let StartBrowsingButtonTitle = NSLocalizedString("Start Browsing", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    static let StartBrowsingButtonColor = UIColor(rgb: 0x363B40)
    static let StartBrowsingButtonHeight = 56

    static let SignInButtonTitle = NSLocalizedString("Sign in to Firefox", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    static let SignInButtonColor = UIColor(red: 0.259, green: 0.49, blue: 0.831, alpha: 1.0)
    static let SignInButtonHeight = 46
    static let SignInButtonCornerRadius = CGFloat(4)

    static let CardTextLineHeight = CGFloat(6)

    static let CardTitleOrganize = NSLocalizedString("Organize", tableName: "Intro", comment: "Title for one of the panels in the First Run tour.")
    static let CardTitleCustomize = NSLocalizedString("Customize", tableName: "Intro", comment: "Title for one of the panels in the First Run tour.")
    static let CardTitleShare = NSLocalizedString("Share", tableName: "Intro", comment: "Title for one of the panels in the First Run tour.")
    static let CardTitleChoose = NSLocalizedString("Choose", tableName: "Intro", comment: "Title for one of the panels in the First Run tour.")
    static let CardTitleSync = NSLocalizedString("Sync your Devices.", tableName: "Intro", comment: "Title for one of the panels in the First Run tour.")

    static let CardTextOrganize = NSLocalizedString("Easily switch between open pages with tabs.", tableName: "Intro", comment: "Description for the 'Organize' panel in the First Run tour.")
    static let CardTextCustomize = NSLocalizedString("Personalize your default search engine and more in Settings.", tableName: "Intro", comment: "Description for the 'Customize' panel in the First Run tour.")
    static let CardTextShare = NSLocalizedString("Use the share sheet to send links from other apps to Firefox.", tableName: "Intro", comment: "Description for the 'Share' panel in the First Run tour.")
    static let CardTextChoose = NSLocalizedString("Tap, hold and move the Firefox icon into your dock for easy access.", tableName: "Intro", comment: "Description for the 'Choose' panel in the First Run tour.")

    static let Card1ImageLabel = NSLocalizedString("The Show Tabs button is next to the Address and Search text field and displays the current number of open tabs.", tableName: "Intro", comment: "Accessibility label for the UI element used to display the number of open tabs, and open the tab tray.")
    static let Card2ImageLabel = NSLocalizedString("The Settings button is at the beginning of the Tabs Tray.", tableName: "Intro", comment: "Accessibility label for the Settings button in the tab tray.")
    static let Card3ImageLabel = NSLocalizedString("Firefox and the cloud", tableName: "Intro", comment: "Accessibility label for the image displayed in the 'Sync' panel of the First Run tour.")

    static let CardTextSyncOffsetFromCenter = 25
    static let Card3ButtonOffsetFromCenter = -10

    static let FadeDuration = 0.25

    static let BackForwardButtonEdgeInset = 20

    static let Card1Color = UIColor(rgb: 0xFFC81E)
    static let Card2Color = UIColor(rgb: 0x41B450)
    static let Card3Color = UIColor(rgb: 0x0096DD)
}

let IntroViewControllerSeenProfileKey = "IntroViewControllerSeen"

protocol IntroViewControllerDelegate: class {
    func introViewControllerDidFinish(introViewController: IntroViewController)
    func introViewControllerDidRequestToLogin(introViewController: IntroViewController)
}

class IntroViewController: UIViewController, UIScrollViewDelegate {
    weak var delegate: IntroViewControllerDelegate?

    var slides = [UIImage]()
    var cards = [UIImageView]()
    var introViews = [UIView]()
    var titleLabels = [UILabel]()
    var textLabels = [UILabel]()

    var startBrowsingButton: UIButton!
    var introView: UIView?
    var slideContainer: UIView!
    var pageControl: UIPageControl!
    var backButton: UIButton!
    var forwardButton: UIButton!
    var signInButton: UIButton!

    private var scrollView: IntroOverlayScrollView!

    var slideVerticalScaleFactor: CGFloat = 1.0

    override func viewDidLoad() {
        view.backgroundColor = UIColor.whiteColor()

        // scale the slides down for iPhone 4S
        if view.frame.height <=  480 {
            slideVerticalScaleFactor = 1.33
        }

        for slideName in IntroViewControllerUX.CardSlides {
            slides.append(UIImage(named: slideName)!)
        }

        startBrowsingButton = UIButton()
        startBrowsingButton.backgroundColor = IntroViewControllerUX.StartBrowsingButtonColor
        startBrowsingButton.setTitle(IntroViewControllerUX.StartBrowsingButtonTitle, forState: UIControlState.Normal)
        startBrowsingButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        startBrowsingButton.addTarget(self, action: #selector(IntroViewController.SELstartBrowsing), forControlEvents: UIControlEvents.TouchUpInside)
        startBrowsingButton.accessibilityIdentifier = "IntroViewController.startBrowsingButton"

        view.addSubview(startBrowsingButton)
        startBrowsingButton.snp_makeConstraints { (make) -> Void in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(IntroViewControllerUX.StartBrowsingButtonHeight)
        }

        scrollView = IntroOverlayScrollView()
        scrollView.backgroundColor = UIColor.clearColor()
        scrollView.accessibilityLabel = NSLocalizedString("Intro Tour Carousel", comment: "Accessibility label for the introduction tour carousel")
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentSize = CGSize(width: scaledWidthOfSlide * CGFloat(IntroViewControllerUX.NumberOfCards), height: scaledHeightOfSlide)
        view.addSubview(scrollView)

        slideContainer = UIView()
        slideContainer.backgroundColor = IntroViewControllerUX.Card1Color
        for i in 0..<IntroViewControllerUX.NumberOfCards {
            let imageView = UIImageView(frame: CGRect(x: CGFloat(i)*scaledWidthOfSlide, y: 0, width: scaledWidthOfSlide, height: scaledHeightOfSlide))
            imageView.image = slides[i]
            slideContainer.addSubview(imageView)
        }

        scrollView.addSubview(slideContainer)
        scrollView.snp_makeConstraints { (make) -> Void in
            make.left.right.top.equalTo(self.view)
            make.bottom.equalTo(startBrowsingButton.snp_top)
        }

        pageControl = UIPageControl()
        pageControl.pageIndicatorTintColor = UIColor.blackColor().colorWithAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
        pageControl.numberOfPages = IntroViewControllerUX.NumberOfCards
        pageControl.accessibilityIdentifier = "pageControl"
        pageControl.addTarget(self, action: #selector(IntroViewController.changePage), forControlEvents: UIControlEvents.ValueChanged)

        view.addSubview(pageControl)
        pageControl.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.scrollView)
            make.centerY.equalTo(self.startBrowsingButton.snp_top).offset(-IntroViewControllerUX.PagerCenterOffsetFromScrollViewBottom)
        }


        func addCard(text: String, title: String) {
            let introView = UIView()
            self.introViews.append(introView)
            self.addLabelsToIntroView(introView, text: text, title: title)
        }

        addCard(IntroViewControllerUX.CardTextOrganize, title: IntroViewControllerUX.CardTitleOrganize)
        addCard(IntroViewControllerUX.CardTextCustomize, title: IntroViewControllerUX.CardTitleCustomize)
        addCard(IntroViewControllerUX.CardTextShare, title: IntroViewControllerUX.CardTitleShare)
        addCard(IntroViewControllerUX.CardTextChoose, title: IntroViewControllerUX.CardTitleChoose)


        // Sync card, with sign in to sync button.

        signInButton = UIButton()
        signInButton.backgroundColor = IntroViewControllerUX.SignInButtonColor
        signInButton.setTitle(IntroViewControllerUX.SignInButtonTitle, forState: .Normal)
        signInButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        signInButton.layer.cornerRadius = IntroViewControllerUX.SignInButtonCornerRadius
        signInButton.clipsToBounds = true
        signInButton.addTarget(self, action: #selector(IntroViewController.SELlogin), forControlEvents: UIControlEvents.TouchUpInside)
        signInButton.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(IntroViewControllerUX.SignInButtonHeight)
        }

        let syncCardView =  UIView()
        addViewsToIntroView(syncCardView, view: signInButton, title: IntroViewControllerUX.CardTitleSync)
        introViews.append(syncCardView)

        // Add all the cards to the view, make them invisible with zero alpha

        for introView in introViews {
            introView.alpha = 0
            self.view.addSubview(introView)
            introView.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(self.slideContainer.snp_bottom)
                make.bottom.equalTo(self.startBrowsingButton.snp_top)
                make.left.right.equalTo(self.view)
            }
        }

        // Make whole screen scrollable by bringing the scrollview to the top
        view.bringSubviewToFront(scrollView)
        view.bringSubviewToFront(pageControl)


        // Activate the first card
        setActiveIntroView(introViews[0], forPage: 0)

        setupDynamicFonts()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(IntroViewController.SELDynamicFontChanged(_:)), name: NotificationDynamicFontChanged, object: nil)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
    }

    func SELDynamicFontChanged(notification: NSNotification) {
        guard notification.name == NotificationDynamicFontChanged else { return }
        setupDynamicFonts()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollView.snp_remakeConstraints { (make) -> Void in
            make.left.right.top.equalTo(self.view)
            make.bottom.equalTo(self.startBrowsingButton.snp_top)
        }

        for i in 0..<IntroViewControllerUX.NumberOfCards {
            if let imageView = slideContainer.subviews[i] as? UIImageView {
                imageView.frame = CGRect(x: CGFloat(i)*scaledWidthOfSlide, y: 0, width: scaledWidthOfSlide, height: scaledHeightOfSlide)
                imageView.contentMode = UIViewContentMode.ScaleAspectFit
            }
        }
        slideContainer.frame = CGRect(x: 0, y: 0, width: scaledWidthOfSlide * CGFloat(IntroViewControllerUX.NumberOfCards), height: scaledHeightOfSlide)
        scrollView.contentSize = CGSize(width: slideContainer.frame.width, height: slideContainer.frame.height)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func shouldAutorotate() -> Bool {
        return false
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        // This actually does the right thing on iPad where the modally
        // presented version happily rotates with the iPad orientation.
        return UIInterfaceOrientationMask.Portrait
    }

    func SELstartBrowsing() {
        delegate?.introViewControllerDidFinish(self)
    }

    func SELback() {
        if introView == introViews[1] {
            setActiveIntroView(introViews[0], forPage: 0)
            scrollView.scrollRectToVisible(scrollView.subviews[0].frame, animated: true)
            pageControl.currentPage = 0
        } else if introView == introViews[2] {
            setActiveIntroView(introViews[1], forPage: 1)
            scrollView.scrollRectToVisible(scrollView.subviews[1].frame, animated: true)
            pageControl.currentPage = 1
        }
    }

    func SELforward() {
        if introView == introViews[0] {
            setActiveIntroView(introViews[1], forPage: 1)
            scrollView.scrollRectToVisible(scrollView.subviews[1].frame, animated: true)
            pageControl.currentPage = 1
        } else if introView == introViews[1] {
            setActiveIntroView(introViews[2], forPage: 2)
            scrollView.scrollRectToVisible(scrollView.subviews[2].frame, animated: true)
            pageControl.currentPage = 2
        }
    }

    func SELlogin() {
		delegate?.introViewControllerDidRequestToLogin(self)
    }

    private var accessibilityScrollStatus: String {
        return String(format: NSLocalizedString("Introductory slide %@ of %@", tableName: "Intro", comment: "String spoken by assistive technology (like VoiceOver) stating on which page of the intro wizard we currently are. E.g. Introductory slide 1 of 3"), NSNumberFormatter.localizedStringFromNumber(pageControl.currentPage+1, numberStyle: .DecimalStyle), NSNumberFormatter.localizedStringFromNumber(IntroViewControllerUX.NumberOfCards, numberStyle: .DecimalStyle))
    }

    func changePage() {
        let swipeCoordinate = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPointMake(swipeCoordinate, 0), animated: true)
    }

    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        // Need to add this method so that tapping the pageControl will also change the card texts.
        // scrollViewDidEndDecelerating waits until the end of the animation to calculate what card it's on.
        scrollViewDidEndDecelerating(scrollView)
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        setActiveIntroView(introViews[page], forPage: page)
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let maximumHorizontalOffset = scrollView.contentSize.width - CGRectGetWidth(scrollView.frame)
        let currentHorizontalOffset = scrollView.contentOffset.x

        var percentage = currentHorizontalOffset / maximumHorizontalOffset
        var startColor: UIColor, endColor: UIColor

        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = page

        if(percentage < 0.5) {
            startColor = IntroViewControllerUX.Card1Color
            endColor = IntroViewControllerUX.Card2Color
            percentage = percentage * 2
        } else {
            startColor = IntroViewControllerUX.Card2Color
            endColor = IntroViewControllerUX.Card3Color
            percentage = (percentage - 0.5) * 2
        }

        slideContainer.backgroundColor = colorForPercentage(percentage, start: startColor, end: endColor)
    }

    private func colorForPercentage(percentage: CGFloat, start: UIColor, end: UIColor) -> UIColor {
        let s = start.components
        let e = end.components
        let newRed   = (1.0 - percentage) * s.red   + percentage * e.red
        let newGreen = (1.0 - percentage) * s.green + percentage * e.green
        let newBlue  = (1.0 - percentage) * s.blue  + percentage * e.blue
        return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }

    private func setActiveIntroView(newIntroView: UIView, forPage page: Int) {
        if introView != newIntroView {
            UIView.animateWithDuration(IntroViewControllerUX.FadeDuration, animations: { () -> Void in
                self.introView?.alpha = 0
                self.introView = newIntroView
                newIntroView.alpha = 1.0
            }, completion: { _ in
                if page == (IntroViewControllerUX.NumberOfCards - 1) {
                    self.scrollView.signinButton = self.signInButton
                } else {
                    self.scrollView.signinButton = nil
                }
            })
        }
    }

    private var scaledWidthOfSlide: CGFloat {
        return view.frame.width
    }

    private var scaledHeightOfSlide: CGFloat {
        return (view.frame.width / slides[0].size.width) * slides[0].size.height / slideVerticalScaleFactor
    }

    private func attributedStringForLabel(text: String) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = IntroViewControllerUX.CardTextLineHeight
        paragraphStyle.alignment = .Center

        let string = NSMutableAttributedString(string: text)
        string.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, string.length))
        return string
    }

    private func addLabelsToIntroView(introView: UIView, text: String, title: String = "") {
        let label = UILabel()

        label.numberOfLines = 0
        label.attributedText = attributedStringForLabel(text)
        textLabels.append(label)

        addViewsToIntroView(introView, view: label, title: title)
    }

    private func addViewsToIntroView(introView: UIView, view: UIView, title: String = "") {
        introView.addSubview(view)
        view.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(introView)
            make.width.equalTo(self.view.frame.width <= 320 ? 240 : 280) // TODO Talk to UX about small screen sizes
        }

        if !title.isEmpty {
            let titleLabel = UILabel()
            titleLabel.numberOfLines = 0
            titleLabel.textAlignment = NSTextAlignment.Center
            titleLabel.text = title
            titleLabels.append(titleLabel)
            introView.addSubview(titleLabel)
            titleLabel.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(introView)
                make.bottom.equalTo(view.snp_top)
                make.centerX.equalTo(introView)
                make.width.equalTo(self.view.frame.width <= 320 ? 240 : 280) // TODO Talk to UX about small screen sizes
            }
        }

    }

    private func setupDynamicFonts() {
        startBrowsingButton.titleLabel?.font = UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.IntroBigFontSize)
        signInButton.titleLabel?.font = UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.IntroStandardFontSize, weight: UIFontWeightMedium)

        for titleLabel in titleLabels {
            titleLabel.font = UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.IntroBigFontSize, weight: UIFontWeightBold)
        }

        for label in textLabels {
            label.font = UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.IntroStandardFontSize)
        }
    }
}

private class IntroOverlayScrollView: UIScrollView {
    weak var signinButton: UIButton?

    private override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if let signinFrame = signinButton?.frame {
            let convertedFrame = convertRect(signinFrame, fromView: signinButton?.superview)
            if CGRectContainsPoint(convertedFrame, point) {
                return false
            }
        }

        return CGRectContainsPoint(CGRect(origin: self.frame.origin, size: CGSize(width: self.contentSize.width, height: self.frame.size.height)), point)
    }
}

extension UIColor {
    var components:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r,g,b,a)
    }
}
