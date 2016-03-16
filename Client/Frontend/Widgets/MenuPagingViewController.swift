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
        super.viewWillLayoutSubviews()
        pageSize = view.bounds.size

        pageControl.numberOfPages = viewControllers.count
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        var maxPageHeight: CGFloat = 0.0
        for (index, page) in viewControllers.enumerate() {
            let pageView = page.view
            // TODO: find a way to layout the pages using AutoLayout
            // if I don't do this, the width pageView has is full screen width
            // if I use constraints, view disappears.
            // there must be a way of doing this with AutoLayout but I can't figure it out.
            // If we can we get a lot for free.
            // 1. better adaptability for things like right->left languages
            // 2. more generic paging controller as it won't need access to height parameter of MenuPageViewController
            pageView.frame = CGRectMake(CGFloat(index) * pageSize.width, 0, pageSize.width, pageView.bounds.height)
            scrollView.addSubview(pageView)

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
