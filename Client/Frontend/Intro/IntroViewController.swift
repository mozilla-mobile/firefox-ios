/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Snap

protocol IntroViewControllerDelegate: class {
    func introViewControllerDidFinish(introViewController: IntroViewController)
}

class IntroViewController: UIViewController, UIScrollViewDelegate {
    weak var delegate: IntroViewControllerDelegate?

    var introSlides = [UIImage]()
    var introViews = [UIView]()

    var button: UIButton!
    var introView: UIView?
    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    var backButton: UIButton!
    var forwardButton: UIButton!
    var signInButton: UIButton!

    // TODO This is not correct. We are doing this here and not in viewDidLoad so that view.frame has been set, which we need to calculate the size of the images in the scrollview. There is probably a better way but for now this works.

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        view.backgroundColor = UIColor.whiteColor()

        introSlides.append(UIImage(named: "slide1")!)
        introSlides.append(UIImage(named: "slide2")!)
        introSlides.append(UIImage(named: "slide3")!)

        //

        button = UIButton()
        button.backgroundColor = UIColor(red: 0.302, green: 0.314, blue: 0.333, alpha: 1.0)
        button.setTitle("Start Browsing", forState: UIControlState.Normal)
        button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        button.addTarget(self, action: "SELstartBrowsing", forControlEvents: UIControlEvents.TouchUpInside)

        view.addSubview(button)
        button.snp_makeConstraints { (make) -> Void in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(66)
        }

        scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentSize = CGSize(width: scaledWidthOfSlide * CGFloat(introSlides.count), height: scaledHeightOfSlide)
        view.addSubview(scrollView)
        scrollView.snp_makeConstraints { (make) -> Void in
            make.left.right.top.equalTo(self.view)
            make.height.equalTo(self.scaledHeightOfSlide)
        }

        for (i, image) in enumerate(introSlides) {
            let imageView = UIImageView(frame: CGRect(x: CGFloat(i)*scaledWidthOfSlide, y: 0, width: scaledWidthOfSlide, height: scaledHeightOfSlide))
            imageView.image = image
            scrollView.addSubview(imageView)
        }

        pageControl = UIPageControl()
        pageControl.numberOfPages = introSlides.count

        view.addSubview(pageControl)
        pageControl.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(self.scrollView)
            make.centerY.equalTo(self.scrollView.snp_bottom).offset(-20)
        }

        //

        let introView1 = UIView()
        let label1 = UILabel()
        label1.numberOfLines = 0
        label1.textAlignment = NSTextAlignment.Center
        label1.text = NSLocalizedString("Browse the web with multiple tabs just like you’re used to.", tableName: "Intro", comment: "")
        label1.font = UIFont.systemFontOfSize(20)
        introView1.addSubview(label1)
        label1.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(introView1)
            make.width.equalTo(self.view.frame.width <= 320 ? 200 : 260) // TODO Would be nicer to do this with actual constraints
        }
        introViews.append(introView1)
        addForwardButtonToIntroView(introView1)

        let introView2 = UIView()
        let label2 = UILabel()
        label2.numberOfLines = 0
        label2.textAlignment = NSTextAlignment.Center
        label2.text = NSLocalizedString("Personalize your Firefox just the way you’d like in the Settings area.", tableName: "Intro", comment: "")
        label2.font = UIFont.systemFontOfSize(20)
        introView2.addSubview(label2)
        label2.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(introView2)
            make.width.equalTo(self.view.frame.width <= 320 ? 200 : 260) // TODO Would be nicer to do this with actual constraints
        }
        introViews.append(introView2)
        addBackButtonToIntroView(introView2)
        addForwardButtonToIntroView(introView2)

        let introView3 = UIView()
        let label3 = UILabel()
        label3.numberOfLines = 0
        label3.textAlignment = NSTextAlignment.Center
        label3.text = NSLocalizedString("Connect to Firefox Accounts anywhere you want.", tableName: "Intro", comment: "")
        label3.font = UIFont.systemFontOfSize(20)
        introView3.addSubview(label3)
        label3.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(introView3)
            make.bottom.equalTo(introView3.snp_centerY).offset(-20)
            make.width.equalTo(self.view.frame.width <= 320 ? 200 : 260) // TODO Would be nicer to do this with actual constraints
        }

        signInButton = UIButton()
        signInButton.backgroundColor = UIColor(red: 0.259, green: 0.49, blue: 0.831, alpha: 1.0)
        signInButton.setTitle(NSLocalizedString("Sign in to Firefox", tableName: "Intro", comment: ""), forState: .Normal)
        signInButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        signInButton.titleLabel?.font = UIFont.systemFontOfSize(20)
        signInButton.layer.cornerRadius = 10
        signInButton.clipsToBounds = true
        introView3.addSubview(signInButton)
        signInButton.snp_makeConstraints { (make) -> Void in
            make.centerX.equalTo(introView3)
            make.top.equalTo(introView3.snp_centerY).offset(10)
            make.height.equalTo(66)
            make.width.equalTo(self.view.frame.width <= 320 ? 200 : 260) // TODO Would be nicer to do this with actual constraints
        }

        //addBackButtonToIntroView(introView3)
        introViews.append(introView3)

        for introView in introViews {
            introView.alpha = 0
            self.view.addSubview(introView)
            introView.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(self.scrollView.snp_bottom)
                make.bottom.equalTo(self.button.snp_top)
                make.left.right.equalTo(self.view)
            }
        }

        // Activate the first slide

        setActiveIntroView(introViews[0])
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
        return UIInterfaceOrientation.Portrait.rawValue
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

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = page
        setActiveIntroView(introViews[page])
    }

    private func setActiveIntroView(newIntroView: UIView) {
        if introView != newIntroView {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
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
        return (view.frame.width / introSlides[0].size.width) * introSlides[0].size.height
    }

    private func addForwardButtonToIntroView(introView: UIView) {
        let button = UIButton()
        button.setImage(UIImage(named: "forward"), forState: .Normal)
        button.addTarget(self, action: "SELforward", forControlEvents: UIControlEvents.TouchUpInside)
        introView.addSubview(button)
        button.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(introView)
            make.right.equalTo(introView.snp_right).offset(-20)
        }
    }

    private func addBackButtonToIntroView(introView: UIView) {
        let button = UIButton()
        button.setImage(UIImage(named: "back"), forState: .Normal)
        button.addTarget(self, action: "SELback", forControlEvents: UIControlEvents.TouchUpInside)
        introView.addSubview(button)
        button.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(introView)
            make.left.equalTo(introView.snp_left).offset(20)
        }
    }
}
