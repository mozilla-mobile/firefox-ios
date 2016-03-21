/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class MenuPagingViewController: UIViewController {

    private var contentOffsetStart:CGPoint?
    private var pageSize: CGSize = CGSizeZero

    var viewControllers = [MenuPageViewController]() {
        didSet {
            self.view.setNeedsLayout()
        }
    }

    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()

    private let containerView = UIView()

    var backgroundColor: UIColor = UIColor.clearColor() {
        didSet {
            self.view.backgroundColor = backgroundColor
        }
    }
    
    var tintColor: UIColor = UIColor.blackColor() {
        didSet {
            pageControl.pageIndicatorTintColor = tintColor.colorWithAlphaComponent(0.5)
            pageControl.currentPageIndicatorTintColor = tintColor
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        pageControl.numberOfPages = viewControllers.count
        pageControl.currentPage = 0
        pageControl.hidesForSinglePage = true
        pageControl.addTarget(self, action: "pageControlDidPage:", forControlEvents: UIControlEvents.ValueChanged)

        view.addSubview(pageControl)
        pageControl.snp_makeConstraints { make in
            make.bottom.equalTo(view)
            make.centerX.equalTo(view)
        }
        // Do any additional setup after loading the view.
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp_makeConstraints { make in
            make.top.right.left.equalTo(view)
            make.bottom.equalTo(pageControl.snp_top)
        }
    }

    override func viewWillLayoutSubviews() {
        pageSize = view.bounds.size

        pageControl.numberOfPages = viewControllers.count
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        super.viewWillLayoutSubviews()
        var maxPageHeight: CGFloat = 0.0
        for (index, page) in viewControllers.enumerate() {
            let pageView = page.view
            scrollView.addSubview(pageView)

            pageView.snp_makeConstraints { make in
                make.left.equalTo(CGFloat(index) * pageSize.width)
                make.top.equalTo(0)
                make.width.equalTo(pageSize.width)
                make.height.equalTo(pageView.bounds.height)
            }

            if maxPageHeight < page.height {
                maxPageHeight = page.height
            }
        }
        scrollView.contentSize = CGSizeMake(pageSize.width * CGFloat(viewControllers.count), 0)

        scrollView.snp_updateConstraints { make in
            make.height.equalTo(maxPageHeight)
        }
    }

    @objc func pageControlDidPage(sender: AnyObject) {
        let xOffset = pageSize.width * CGFloat(pageControl.currentPage)
        scrollView.setContentOffset(CGPointMake(xOffset,0) , animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MenuPagingViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let currentPage = floor((scrollView.contentOffset.x-pageSize.width/2)/pageSize.width)+1
        pageControl.currentPage = Int(currentPage)
    }
}
