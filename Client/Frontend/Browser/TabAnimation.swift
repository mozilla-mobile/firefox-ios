//
//  TabToBrowserAnimation.swift
//  Client
//
//  Created by Steph Leroux on 2015-05-22.
//  Copyright (c) 2015 Mozilla. All rights reserved.
//

import Foundation

@objc
class TabAnimation: NSObject, UIViewControllerAnimatedTransitioning  {
    private let show: Bool


    private let collectionView = tabTrayController.collectionView
    private let tabManager = tabTrayController.tabManager
    private let browser = tabManager.selectedTab!
    private let homePanelController = browserViewController.homePanelController
    privat elet header = browserViewController.header
        let addTabButton = tabTrayController.addTabButton
        let settingsButton = tabTrayController.settingsButton
        let addTabRight = tabTrayController.addTabRight
        let settingsLeft = tabTrayController.settingsLeft

    init(show: Bool) {
        self.show = show
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 6
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toView = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let container = transitionContext.containerView()

        if show {
            container.insertSubview(toView.view, aboveSubview: fromView.view)
        }

        var browserViewController: BrowserViewController!
        var tabTrayController: TabTrayController!
        if let bvc = fromView as? BrowserViewController, let tabTray = toView as? TabTrayController {
            browserViewController = bvc
            tabTrayController = tabTray
        } else if let tabTray = fromView as? TabTrayController, let bvc = toView as? BrowserViewController {
            browserViewController = bvc
            tabTrayController = tabTray
        }

        let collectionView = tabTrayController.collectionView
        let tabManager = tabTrayController.tabManager
        let browser = tabManager.selectedTab!
        let homePanelController = browserViewController.homePanelController
        let header = browserViewController.header
        let addTabButton = tabTrayController.addTabButton
        let settingsButton = tabTrayController.settingsButton
        let addTabRight = tabTrayController.addTabRight
        let settingsLeft = tabTrayController.settingsLeft

        if let bvc = fromView as? BrowserViewController, let tabTray = toView as? TabTrayController {
            showTabTrayController()
        } else if let tabTray = fromView as? TabTrayController, let bvc = toView as? BrowserViewController {
            showBrowserViewController()
        }
    }

    func showTabTrayController() {
        // Scroll to where we need to be in the collection view and take a snapshto if it to show for the
        // alpha + scale animation
        tabTray.view.layoutIfNeeded()
        collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: tabManager.selectedIndex, inSection: 0), atScrollPosition: .Top, animated: false)
        let originalCollectionViewFrame = collectionView.frame
        let attributes = collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: tabManager.selectedIndex, inSection: 0))
        let cellFrame = collectionView.convertRect(attributes.frame, toView: container)
        collectionView.transform = CGAffineTransformMakeScale(0.9, 0.9)

        // Add tab to view hierarchy for animation
        let tabView = self.tabViewFromBrowser(browser, frame: originalCollectionViewFrame)
        tabView.expanded = true
        tabView.backgroundColor = UIColor.redColor()
        container.addSubview(tabView)

        self.toggleWebviews(show: false, tabManager: tabManager)
        homePanelController?.view.hidden = true

        UIView.animateWithDuration(transitionDuration(transitionContext), animations: {
            // Animate nav buttons
            addTabRight?.updateOffset(-TabTrayControllerUX.NavButtonMargin)
            addTabButton.alpha = 1
            settingsLeft?.updateOffset(TabTrayControllerUX.NavButtonMargin)
            settingsButton.alpha = 1

            // Animate the tab view to shrink to it's cell position
            tabView.frame = cellFrame
            tabView.layer.cornerRadius = TabTrayControllerUX.CornerRadius
            tabView.expanded = false
            collectionView.transform = CGAffineTransformIdentity
            collectionView.alpha = 1

            let scale = cellFrame.size.width / header.frame.size.width

            // Since the scale will happen in the center of the frame, we move this so the centers of the two frames overlap.
            let tx = cellFrame.origin.x + cellFrame.width/2 - (header.frame.origin.x + header.frame.width/2)
            let ty = cellFrame.origin.y - header.frame.origin.y * scale * 2 // Move this up a little actually keeps it above the web page. I'm not sure what you want
            var transform = CGAffineTransformMakeTranslation(tx, ty)
            transform = CGAffineTransformScale(transform, scale, scale)
            header.transform = transform

        }, completion: { _ in
            tabView.removeFromSuperview()
            collectionView.alpha = 1

            homePanelController?.view.hidden = false
            bvc.stopTrackingAccessibilityStatus()

            transitionContext.completeTransition(true)
        })
    }

    func showBrowserViewController() {
        let attributes = collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: tabManager.selectedIndex, inSection: 0))
        let tabFrame = collectionView.convertRect(attributes.frame, toView: container)
        let tabView = tabViewFromBrowser(browser, frame: tabFrame)

        tabView.backgroundColor = UIColor.redColor()
        container.addSubview(tabView)

        toggleWebviews(show: false, tabManager: tabManager)
        bvc.homePanelController?.view.hidden = true

        UIView.animateWithDuration(transitionDuration(transitionContext), animations: {
            // Animate nav buttons
            addTabRight?.updateOffset(addTabButton.frame.size.width + TabTrayControllerUX.NavButtonMargin)
            addTabButton.alpha = 0
            settingsLeft?.updateOffset(-(settingsButton.frame.size.width + TabTrayControllerUX.NavButtonMargin))
            settingsButton.alpha = 0

            // Animate tab view to fill the screen
            tabView.frame = collectionView.frame
            tabView.layer.cornerRadius = 0
            tabView.expanded = true

            collectionView.transform = CGAffineTransformMakeScale(0.9, 0.9)
            collectionView.alpha = 0


    //        view.alpha = 1
//                footer.transform = CGAffineTransformIdentity
            header.transform = CGAffineTransformIdentity
        }, completion: { _ in
            tabView.removeFromSuperview()
            collectionView.alpha = 1

            self.toggleWebviews(show: true, tabManager: tabManager)
            homePanelController?.view.hidden = false
            bvc.startTrackingAccessibilityStatus()
            transitionContext.completeTransition(true)
    })
    }

    func toggleWebviews(#show: Bool, tabManager: TabManager) {
        for i in 0..<tabManager.count {
            if let tab = tabManager[i] {
                tab.webView.hidden = !show
            }
        }
    }

    private func tabViewFromBrowser(browser: Browser?, frame: CGRect) -> TabContentView {
        let tabView = TabContentView()
        tabView.background.image = browser?.screenshot
        tabView.titleText.text = browser?.displayTitle

        if let favIconUrlString = browser?.displayFavicon?.url {
            tabView.favicon.sd_setImageWithURL(NSURL(string: favIconUrlString))
        }

        tabView.frame = frame
        tabView.setNeedsLayout()
        return tabView
    }
}