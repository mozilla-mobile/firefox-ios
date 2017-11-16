/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

struct IntroViewControllerUX {
    static let Width = 375
    static let Height = 667
    static let SyncButtonTopPadding = 5
    static let MinimumFontScale: CGFloat = 0.5

    static let CardSlides = ["tour-Welcome", "tour-Search", "tour-Private", "tour-Mail", "tour-Sync"]
    static let NumberOfCards = CardSlides.count

    static let PagerCenterOffsetFromScrollViewBottom = UIScreen.main.bounds.width <= 320 ? 20 : 30

    static let StartBrowsingButtonTitle = NSLocalizedString("Start Browsing", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    static let StartBrowsingButtonColor = UIColor(rgb: 0x4990E2)
    static let StartBrowsingButtonHeight = 56
    static let SignInButtonTitle = NSLocalizedString("Sign in to Firefox", tableName: "Intro", comment: "See http://mzl.la/1T8gxwo")
    static let SignInButtonColor = UIColor(rgb: 0x45A1FF)
    static let SignInButtonHeight = 60
    static let SignInButtonWidth = 290

    static let CardTextLineHeight = UIScreen.main.bounds.width <= 320 ? CGFloat(2) : CGFloat(6)
    static let CardTextWidth = UIScreen.main.bounds.width <= 320 ? 240 : 280
    static let CardTitleHeight = 50
    
    static let CardTitleWelcome = NSLocalizedString("Intro.Slides.Welcome.Title", tableName: "Intro", value: "Thanks for choosing Firefox!", comment: "Title for the first panel 'Welcome' in the First Run tour.")
    static let CardTitleSearch = NSLocalizedString("Intro.Slides.Search.Title", tableName: "Intro", value: "Your search, your way", comment: "Title for the second  panel 'Search' in the First Run tour.")
    static let CardTitlePrivate = NSLocalizedString("Intro.Slides.Private.Title", tableName: "Intro", value: "Browse like no one’s watching", comment: "Title for the third panel 'Private Browsing' in the First Run tour.")
    static let CardTitleMail = NSLocalizedString("Intro.Slides.Mail.Title", tableName: "Intro", value: "You’ve got mail… options", comment: "Title for the fourth panel 'Mail' in the First Run tour.")
    static let CardTitleSync = NSLocalizedString("Intro.Slides.Sync.Title", tableName: "Intro", value: "Pick up where you left off", comment: "Title for the fifth panel 'Sync' in the First Run tour.")
    
    static let CardTextWelcome = NSLocalizedString("Intro.Slides.Welcome.Description", tableName: "Intro", value: "A modern mobile browser from Mozilla, the non-profit committed to a free and open web.", comment: "Description for the 'Welcome' panel in the First Run tour.")
    static let CardTextSearch = NSLocalizedString("Intro.Slides.Search.Description", tableName: "Intro", value: "Searching for something different? Choose another default search engine (or add your own) in Settings.", comment: "Description for the 'Favorite Search Engine' panel in the First Run tour.")
    static let CardTextPrivate = NSLocalizedString("Intro.Slides.Private.Description", tableName: "Intro", value: "Tap the mask icon to slip into Private Browsing mode.", comment: "Description for the 'Private Browsing' panel in the First Run tour.")
    static let CardTextMail = NSLocalizedString("Intro.Slides.Mail.Description", tableName: "Intro", value: "Use any email app — not just Mail — with Firefox.", comment: "Description for the 'Mail' panel in the First Run tour.")
    static let CardTextSync = NSLocalizedString("Intro.Slides.Sync.Description", tableName: "Intro", value: "Use Sync to find the bookmarks, passwords, and other things you save to Firefox on all your devices.", comment: "Description for the 'Sync' panel in the First Run tour.")

    static let FadeDuration = 0.25
}

let IntroViewControllerSeenProfileKey = "IntroViewControllerSeen"

protocol IntroViewControllerDelegate: class {
    func introViewControllerDidFinish(_ introViewController: IntroViewController, requestToLogin: Bool)
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

    fileprivate var scrollView: IntroOverlayScrollView!

    var slideVerticalScaleFactor: CGFloat = 1.0

    override func viewDidLoad() {
        view.backgroundColor = UIColor.white

        // scale the slides down for iPhone 4S
        if view.frame.height <=  480 {
            slideVerticalScaleFactor = 1.33
            slideVerticalScaleFactor = 1.33 //4S
        } else if view.frame.height <= 568 {
            slideVerticalScaleFactor = 1.15 //SE
        }

        for slideName in IntroViewControllerUX.CardSlides {
            slides.append(UIImage(named: slideName)!)
        }

        startBrowsingButton = UIButton()
        startBrowsingButton.backgroundColor = UIColor.clear
        startBrowsingButton.setTitle(IntroViewControllerUX.StartBrowsingButtonTitle, for: UIControlState())
        startBrowsingButton.setTitleColor(IntroViewControllerUX.StartBrowsingButtonColor, for: UIControlState())
        startBrowsingButton.addTarget(self, action: #selector(IntroViewController.SELstartBrowsing), for: UIControlEvents.touchUpInside)
        startBrowsingButton.accessibilityIdentifier = "IntroViewController.startBrowsingButton"

        view.addSubview(startBrowsingButton)
        startBrowsingButton.snp.makeConstraints { (make) -> Void in
            if #available(iOS 11.0, *) {
                make.left.right.bottom.equalTo(self.view.safeAreaLayoutGuide)
            } else {
                make.left.right.bottom.equalTo(self.view)
            }
            make.height.equalTo(IntroViewControllerUX.StartBrowsingButtonHeight)
        }

        scrollView = IntroOverlayScrollView()
        scrollView.backgroundColor = UIColor.clear
        scrollView.accessibilityLabel = NSLocalizedString("Intro Tour Carousel", comment: "Accessibility label for the introduction tour carousel")
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentSize = CGSize(width: scaledWidthOfSlide * CGFloat(IntroViewControllerUX.NumberOfCards), height: scaledHeightOfSlide)
        scrollView.accessibilityIdentifier = "IntroViewController.scrollView"
        view.addSubview(scrollView)

        slideContainer = UIView()
        for i in 0..<IntroViewControllerUX.NumberOfCards {
            let imageView = UIImageView(frame: CGRect(x: CGFloat(i)*scaledWidthOfSlide, y: 0, width: scaledWidthOfSlide, height: scaledHeightOfSlide))
            imageView.image = slides[i]
            slideContainer.addSubview(imageView)
        }

        scrollView.addSubview(slideContainer)
        scrollView.snp.makeConstraints { (make) -> Void in
            make.left.right.top.equalTo(self.view)
            make.bottom.equalTo(startBrowsingButton.snp.top)
        }
        self.view.layoutIfNeeded()
        self.scrollView.layoutIfNeeded()
        
        pageControl = UIPageControl()
        pageControl.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.3)
        pageControl.currentPageIndicatorTintColor = UIColor.black
        pageControl.numberOfPages = IntroViewControllerUX.NumberOfCards
        pageControl.accessibilityIdentifier = "IntroViewController.pageControl"
        pageControl.addTarget(self, action: #selector(IntroViewController.changePage), for: UIControlEvents.valueChanged)

        view.addSubview(pageControl)
        pageControl.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.scrollView)
            make.centerY.equalTo(self.startBrowsingButton.snp.top).offset(-IntroViewControllerUX.PagerCenterOffsetFromScrollViewBottom)
        }

        func addCard(title: String, text: String, introView: UIView) {
            self.introViews.append(introView)
            
            let titleLabel = UILabel()
            titleLabel.numberOfLines = 2
            titleLabel.adjustsFontSizeToFitWidth = true
            titleLabel.minimumScaleFactor = IntroViewControllerUX.MinimumFontScale
            titleLabel.textAlignment = NSTextAlignment.center
            titleLabel.text = title
            titleLabels.append(titleLabel)
            introView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make ) -> Void in
                make.top.equalTo(introView).offset(20)
                make.centerX.equalTo(introView)
                make.height.equalTo(IntroViewControllerUX.CardTitleHeight)
                make.width.equalTo(IntroViewControllerUX.CardTextWidth)
            }
            
            let textLabel = UILabel()
            textLabel.numberOfLines = 5
            textLabel.attributedText = attributedStringForLabel(text)
            textLabel.adjustsFontSizeToFitWidth = true
            textLabel.minimumScaleFactor = IntroViewControllerUX.MinimumFontScale
            textLabel.lineBreakMode = .byTruncatingTail
            textLabels.append(textLabel)
            introView.addSubview(textLabel)
            textLabel.snp.makeConstraints({ (make) -> Void in
                make.top.equalTo(titleLabel.snp.bottom).offset(20)
                make.centerX.equalTo(introView)
                make.width.equalTo(IntroViewControllerUX.CardTextWidth)
            })
        }
        addCard(title: IntroViewControllerUX.CardTitleWelcome, text: IntroViewControllerUX.CardTextWelcome, introView: UIView())
        addCard(title: IntroViewControllerUX.CardTitleSearch, text: IntroViewControllerUX.CardTextSearch, introView: UIView())
        addCard(title: IntroViewControllerUX.CardTitlePrivate, text: IntroViewControllerUX.CardTextPrivate, introView: UIView())
        addCard(title: IntroViewControllerUX.CardTitleMail, text: IntroViewControllerUX.CardTextMail, introView: UIView())

        // Sync card, with sign in to sync button.
        signInButton = UIButton()
        signInButton.backgroundColor = IntroViewControllerUX.SignInButtonColor
        signInButton.setTitle(IntroViewControllerUX.SignInButtonTitle, for: UIControlState())
        signInButton.setTitleColor(UIColor.white, for: UIControlState())
        signInButton.clipsToBounds = true
        signInButton.addTarget(self, action: #selector(IntroViewController.SELlogin), for: UIControlEvents.touchUpInside)
        signInButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(IntroViewControllerUX.SignInButtonHeight)
        }
        
        let syncCardView = UIView()
        // introViews.append(syncCardView)
        addCard(title: IntroViewControllerUX.CardTitleSync, text: IntroViewControllerUX.CardTextSync, introView: syncCardView)

        syncCardView.addSubview(signInButton)
        syncCardView.bringSubview(toFront: signInButton)
        signInButton.snp.makeConstraints { (make) -> Void in
            make.centerX.equalTo(syncCardView)
            make.width.equalTo(IntroViewControllerUX.CardTextWidth) // TODO Talk to UX about small screen sizes
            make.bottom.equalTo(syncCardView)
        }

        // We need a reference to the sync pages textlabel so we can adjust the constraints
        if let index = introViews.index(of: syncCardView), index < textLabels.count {
            let syncTextLabel = textLabels[index]
            syncTextLabel.snp.makeConstraints { make in
                make.bottom.equalTo(signInButton.snp.top).offset(-IntroViewControllerUX.SyncButtonTopPadding)
            }
        }
        // Add all the cards to the view, make them invisible with zero alpha
        for introView in introViews {
            introView.alpha = 0
            self.view.addSubview(introView)
            introView.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.slideContainer.snp.bottom)
                make.bottom.equalTo(self.startBrowsingButton.snp.top)
                make.left.right.equalTo(self.view)
            }
        }

        // Make whole screen scrollable by bringing the scrollview to the top
        view.bringSubview(toFront: scrollView)
        view.sendSubview(toBack: pageControl)
        scrollView?.bringSubview(toFront: syncCardView)
        signInButton.superview?.bringSubview(toFront: signInButton)

        // Activate the first card
        setActiveIntroView(introViews[0], forPage: 0)
        setupDynamicFonts()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(SELDynamicFontChanged(_:)), name: NotificationDynamicFontChanged, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NotificationDynamicFontChanged, object: nil)
    }

    func SELDynamicFontChanged(_ notification: Notification) {
        guard notification.name == NotificationDynamicFontChanged else { return }
        setupDynamicFonts()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollView.snp.remakeConstraints { (make) -> Void in
            make.left.right.top.equalTo(self.view)
            make.bottom.equalTo(self.startBrowsingButton.snp.top)
        }

        for i in 0..<IntroViewControllerUX.NumberOfCards {
            if let imageView = slideContainer.subviews[i] as? UIImageView {
                imageView.frame = CGRect(x: CGFloat(i)*scaledWidthOfSlide, y: 0, width: scaledWidthOfSlide, height: scaledHeightOfSlide)
                imageView.contentMode = UIViewContentMode.scaleAspectFit
            }
        }
        slideContainer.frame = CGRect(x: 0, y: 0, width: scaledWidthOfSlide * CGFloat(IntroViewControllerUX.NumberOfCards), height: scaledHeightOfSlide)
        scrollView.contentSize = CGSize(width: slideContainer.frame.width, height: slideContainer.frame.height)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // This actually does the right thing on iPad where the modally
        // presented version happily rotates with the iPad orientation.
        return UIInterfaceOrientationMask.portrait
    }

    func SELstartBrowsing() {
        LeanplumIntegration.sharedInstance.track(eventName: .dismissedOnboarding)
        delegate?.introViewControllerDidFinish(self, requestToLogin: false)
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
        delegate?.introViewControllerDidFinish(self, requestToLogin: true)
    }

    fileprivate var accessibilityScrollStatus: String {
        let number = NSNumber(value: pageControl.currentPage + 1)
        return String(format: NSLocalizedString("Introductory slide %@ of %@", tableName: "Intro", comment: "String spoken by assistive technology (like VoiceOver) stating on which page of the intro wizard we currently are. E.g. Introductory slide 1 of 3"), NumberFormatter.localizedString(from: number, number: .decimal), NumberFormatter.localizedString(from: NSNumber(value: IntroViewControllerUX.NumberOfCards), number: .decimal))
    }

    func changePage() {
        let swipeCoordinate = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: swipeCoordinate, y: 0), animated: true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Need to add this method so that when forcibly dragging, instead of letting deceleration happen, should also calculate what card it's on.
        // This especially affects sliding to the last or first slides.
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // Need to add this method so that tapping the pageControl will also change the card texts.
        // scrollViewDidEndDecelerating waits until the end of the animation to calculate what card it's on.
        scrollViewDidEndDecelerating(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        setActiveIntroView(introViews[page], forPage: page)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maximumHorizontalOffset = scrollView.frame.width
        let currentHorizontalOffset = scrollView.contentOffset.x

        var percentageOfScroll = currentHorizontalOffset / maximumHorizontalOffset
        percentageOfScroll = percentageOfScroll > 1.0 ? 1.0 : percentageOfScroll
        let whiteComponent = UIColor.white.components
        let grayComponent = UIColor(rgb: 0xF2F2F2).components
        
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = page
        
        let newRed   = (1.0 - percentageOfScroll) * whiteComponent.red   + percentageOfScroll * grayComponent.red
        let newGreen = (1.0 - percentageOfScroll) * whiteComponent.green + percentageOfScroll * grayComponent.green
        let newBlue  = (1.0 - percentageOfScroll) * whiteComponent.blue  + percentageOfScroll * grayComponent.blue
        let newColor =  UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
        slideContainer.backgroundColor = newColor
    }

    fileprivate func setActiveIntroView(_ newIntroView: UIView, forPage page: Int) {
        if introView != newIntroView {
            UIView.animate(withDuration: IntroViewControllerUX.FadeDuration, animations: { () -> Void in
                self.introView?.alpha = 0
                self.introView = newIntroView
                newIntroView.alpha = 1.0
                if page == 0 {
                    self.startBrowsingButton.alpha = 0
                } else {
                    self.startBrowsingButton.alpha = 1
                }
            }, completion: { _ in
                if page == (IntroViewControllerUX.NumberOfCards - 1) {
                    self.scrollView.signinButton = self.signInButton
                } else {
                    self.scrollView.signinButton = nil
                }
            })
        }
    }

    fileprivate var scaledWidthOfSlide: CGFloat {
        return view.frame.width
    }

    fileprivate var scaledHeightOfSlide: CGFloat {
        return (view.frame.width / slides[0].size.width) * slides[0].size.height / slideVerticalScaleFactor
    }

    fileprivate func attributedStringForLabel(_ text: String) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = IntroViewControllerUX.CardTextLineHeight
        paragraphStyle.alignment = .center

        let string = NSMutableAttributedString(string: text)
        string.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSRange(location: 0, length: string.length))
        return string
    }
    
    fileprivate func setupDynamicFonts() {
        startBrowsingButton.titleLabel?.font = UIFont(name: "FiraSans-Regular", size: DynamicFontHelper.defaultHelper.IntroStandardFontSize)
        signInButton.titleLabel?.font = UIFont(name: "FiraSans-Regular", size: DynamicFontHelper.defaultHelper.IntroBigFontSize)

        for titleLabel in titleLabels {
            titleLabel.font = UIFont(name: "FiraSans-Medium", size: DynamicFontHelper.defaultHelper.IntroBigFontSize)
        }

        for label in textLabels {
            label.font = UIFont(name: "FiraSans-UltraLight", size: DynamicFontHelper.defaultHelper.IntroStandardFontSize)
        }
    }
}

fileprivate class IntroOverlayScrollView: UIScrollView {
    weak var signinButton: UIButton?

    fileprivate override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let signinFrame = signinButton?.frame {
            let convertedFrame = convert(signinFrame, from: signinButton?.superview)
            if convertedFrame.contains(point) {
                return false
            }
        }

        return CGRect(origin: self.frame.origin, size: CGSize(width: self.contentSize.width, height: self.frame.size.height)).contains(point)
    }
}

extension UIColor {
    var components:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}
