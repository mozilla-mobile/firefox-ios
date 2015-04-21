/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

struct IntroViewControllerUX {
    static let Width = 375
    static let Height = 667

    static let NumberOfCards = 3

    static let PagerCenterOffsetFromScrollViewBottom = 20

    static let StartBrowsingButtonTitle = NSLocalizedString("Start Browsing", tableName: "Intro", comment: "")
    static let StartBrowsingButtonColor = UIColor(red: 0.302, green: 0.314, blue: 0.333, alpha: 1.0)
    static let StartBrowsingButtonHeight = 66
    static let StartBrowsingButtonFont = UIFont.systemFontOfSize(18)

    static let SignInButtonTitle = NSLocalizedString("Sign in to Firefox", tableName: "Intro", comment: "")
    static let SignInButtonColor = UIColor(red: 0.259, green: 0.49, blue: 0.831, alpha: 1.0)
    static let SignInButtonHeight = 66
    static let SignInButtonFont = UIFont.systemFontOfSize(20)
    static let SignInButtonCornerRadius = CGFloat(10)

    static let CardTextFont = UIFont.systemFontOfSize(20)

    static let Card1Text = NSLocalizedString("Browse the web with multiple tabs just like you’re used to.", tableName: "Intro", comment: "")

    static let Card2Text = NSLocalizedString("Personalize your Firefox just the way you’d like in the Settings area.", tableName: "Intro", comment: "")

    static let Card3Text = NSLocalizedString("Connect to Firefox Accounts anywhere you want.", tableName: "Intro", comment: "")
    static let Card3TextOffsetFromCenter = 10
    static let Card3ButtonOffsetFromCenter = 10

    static let FadeDuration = 0.25

    static let BackForwardButtonEdgeInset = 20
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

    var startBrowsingButton: UIButton!
    var introView: UIView?
    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    var backButton: UIButton!
    var forwardButton: UIButton!
    var signInButton: UIButton!

    override func viewDidLoad() {
        view.backgroundColor = UIColor.whiteColor()

        //

        for i in 0..<IntroViewControllerUX.NumberOfCards {
            slides.append(UIImage(named: "slide\(i+1)")!)
        }

        //

        startBrowsingButton = UIButton()
        startBrowsingButton.backgroundColor = IntroViewControllerUX.StartBrowsingButtonColor
        startBrowsingButton.setTitle(IntroViewControllerUX.StartBrowsingButtonTitle, forState: UIControlState.Normal)
        startBrowsingButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        startBrowsingButton.titleLabel?.font = IntroViewControllerUX.StartBrowsingButtonFont
        startBrowsingButton.addTarget(self, action: "SELstartBrowsing", forControlEvents: UIControlEvents.TouchUpInside)

        view.addSubview(startBrowsingButton)
        startBrowsingButton.snp_makeConstraints { (make) -> Void in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(IntroViewControllerUX.StartBrowsingButtonHeight)
        }

        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentSize = CGSize(width: scaledWidthOfSlide * CGFloat(IntroViewControllerUX.NumberOfCards), height: scaledHeightOfSlide)
        view.addSubview(scrollView)
        scrollView.snp_makeConstraints { (make) -> Void in
            make.left.right.top.equalTo(self.view)
            make.height.equalTo(self.scaledHeightOfSlide)
        }

        for i in 0..<IntroViewControllerUX.NumberOfCards {
            let imageView = UIImageView(frame: CGRect(x: CGFloat(i)*scaledWidthOfSlide, y: 0, width: scaledWidthOfSlide, height: scaledHeightOfSlide))
            imageView.image = slides[i]
            scrollView.addSubview(imageView)
        }

        pageControl = UIPageControl()
        pageControl.numberOfPages = IntroViewControllerUX.NumberOfCards

        view.addSubview(pageControl)
        pageControl.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.scrollView)
            make.centerY.equalTo(self.scrollView.snp_bottom).offset(-IntroViewControllerUX.PagerCenterOffsetFromScrollViewBottom)
        }

        // Card1

        let introView1 = UIView()
        introViews.append(introView1)
        addLabelToIntroView(introView1, text: IntroViewControllerUX.Card1Text)
        addForwardButtonToIntroView(introView1)

        // Card 2

        let introView2 = UIView()
        introViews.append(introView2)
        addLabelToIntroView(introView2, text: IntroViewControllerUX.Card2Text)
        addBackButtonToIntroView(introView2)
        addForwardButtonToIntroView(introView2)

        // Card 3

        let introView3 = UIView()
        let label3 = UILabel()
        label3.numberOfLines = 0
        label3.textAlignment = NSTextAlignment.Center
        label3.text = IntroViewControllerUX.Card3Text
        label3.font = IntroViewControllerUX.CardTextFont
        introView3.addSubview(label3)
        label3.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(introView3)
            make.bottom.equalTo(introView3.snp_centerY).offset(-IntroViewControllerUX.Card3TextOffsetFromCenter)
            make.width.equalTo(self.view.frame.width <= 320 ? 200 : 260) // TODO Talk to UX about small screen sizes
        }

        signInButton = UIButton()
        signInButton.backgroundColor = IntroViewControllerUX.SignInButtonColor
        signInButton.setTitle(IntroViewControllerUX.SignInButtonTitle, forState: .Normal)
        signInButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        signInButton.titleLabel?.font = IntroViewControllerUX.SignInButtonFont
        signInButton.layer.cornerRadius = IntroViewControllerUX.SignInButtonCornerRadius
        signInButton.clipsToBounds = true
        signInButton.addTarget(self, action: "SELlogin", forControlEvents: UIControlEvents.TouchUpInside)
        introView3.addSubview(signInButton)
        signInButton.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(introView3)
            make.top.equalTo(introView3.snp_centerY).offset(IntroViewControllerUX.Card3ButtonOffsetFromCenter)
            make.height.equalTo(IntroViewControllerUX.SignInButtonHeight)
            make.width.equalTo(self.view.frame.width <= 320 ? 200 : 260) // TODO Talk to UX about small screen sizes
        }

        introViews.append(introView3)

        // Add all the cards to the view, make them invisible with zero alpha

        for introView in introViews {
            introView.alpha = 0
            self.view.addSubview(introView)
            introView.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(self.scrollView.snp_bottom)
                make.bottom.equalTo(self.startBrowsingButton.snp_top)
                make.left.right.equalTo(self.view)
            }
        }

        // Activate the first card

        setActiveIntroView(introViews[0])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollView.snp_remakeConstraints { (make) -> Void in
            make.left.right.top.equalTo(self.view)
            make.height.equalTo(self.scaledHeightOfSlide)
        }

        for i in 0..<IntroViewControllerUX.NumberOfCards {
            if let imageView = scrollView.subviews[i] as? UIImageView {
                imageView.frame = CGRect(x: CGFloat(i)*scaledWidthOfSlide, y: 0, width: scaledWidthOfSlide, height: scaledHeightOfSlide)
            }
        }
        scrollView.contentSize = CGSize(width: scaledWidthOfSlide * CGFloat(IntroViewControllerUX.NumberOfCards), height: scaledHeightOfSlide)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func shouldAutorotate() -> Bool {
        return false
    }

    override func supportedInterfaceOrientations() -> Int {
        // This actually does the right thing on iPad where the modally
        // presented version happily rotates with the iPad orientation.
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    func SELstartBrowsing() {
        delegate?.introViewControllerDidFinish(self)
    }

    func SELback() {
        if introView == introViews[1] {
            setActiveIntroView(introViews[0])
            scrollView.scrollRectToVisible(scrollView.subviews[0].frame, animated: true)
            pageControl.currentPage = 0
        } else if introView == introViews[2] {
            setActiveIntroView(introViews[1])
            scrollView.scrollRectToVisible(scrollView.subviews[1].frame, animated: true)
            pageControl.currentPage = 1
        }
    }

    func SELforward() {
        if introView == introViews[0] {
            setActiveIntroView(introViews[1])
            scrollView.scrollRectToVisible(scrollView.subviews[1].frame, animated: true)
            pageControl.currentPage = 1
        } else if introView == introViews[1] {
            setActiveIntroView(introViews[2])
            scrollView.scrollRectToVisible(scrollView.subviews[2].frame, animated: true)
            pageControl.currentPage = 2
        }
    }

    func SELlogin() {
        delegate?.introViewControllerDidRequestToLogin(self)
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = page
        setActiveIntroView(introViews[page])
    }

    private func setActiveIntroView(newIntroView: UIView) {
        if introView != newIntroView {
            UIView.animateWithDuration(IntroViewControllerUX.FadeDuration, animations: { () -> Void in
                self.introView?.alpha = 0
                self.introView = newIntroView
                newIntroView.alpha = 1.0
            })
        }
    }

    private var scaledWidthOfSlide: CGFloat {
        return view.frame.width
    }

    private var scaledHeightOfSlide: CGFloat {
        return (view.frame.width / slides[0].size.width) * slides[0].size.height
    }

    private func addForwardButtonToIntroView(introView: UIView) {
        let button = UIButton()
        button.setImage(UIImage(named: "forward"), forState: .Normal)
        button.addTarget(self, action: "SELforward", forControlEvents: UIControlEvents.TouchUpInside)
        introView.addSubview(button)
        button.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(introView)
            make.right.equalTo(introView.snp_right).offset(-IntroViewControllerUX.BackForwardButtonEdgeInset)
        }
    }

    private func addBackButtonToIntroView(introView: UIView) {
        let button = UIButton()
        button.setImage(UIImage(named: "back"), forState: .Normal)
        button.addTarget(self, action: "SELback", forControlEvents: UIControlEvents.TouchUpInside)
        introView.addSubview(button)
        button.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(introView)
            make.left.equalTo(introView.snp_left).offset(IntroViewControllerUX.BackForwardButtonEdgeInset)
        }
    }

    private func addLabelToIntroView(introView: UIView, text: String) {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = NSTextAlignment.Center
        label.text = text
        label.font = IntroViewControllerUX.CardTextFont
        introView.addSubview(label)
        label.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(introView)
            make.width.equalTo(self.view.frame.width <= 320 ? 200 : 260) // TODO Talk to UX about small screen sizes
        }
    }
}
