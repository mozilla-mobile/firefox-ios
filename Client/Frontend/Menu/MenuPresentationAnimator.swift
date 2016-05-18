/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class MenuPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    var presenting: Bool = false

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let screens = (from: transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!, to: transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!)

        guard let menuViewController = !self.presenting ? screens.from as? MenuViewController : screens.to as? MenuViewController else {
            return
        }

        var bottomViewController = !self.presenting ? screens.to as UIViewController : screens.from as UIViewController

        // don't do anything special if it's a popover presentation
        if menuViewController.presentationStyle == .Popover {
            return
        }

        if let navController = bottomViewController as? UINavigationController {
            bottomViewController = navController.viewControllers.last ?? bottomViewController
        }

        if bottomViewController.isKindOfClass(BrowserViewController) {
            animateWithMenu(menuViewController, browserViewController: bottomViewController as! BrowserViewController, transitionContext: transitionContext)
        } else if bottomViewController.isKindOfClass(TabTrayController) {
            animateWithMenu(menuViewController, tabTrayController: bottomViewController as! TabTrayController, transitionContext: transitionContext)
        }
    }


    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return presenting ? 0.4 : 0.2
    }
}

extension MenuPresentationAnimator: UIViewControllerTransitioningDelegate {
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
}

extension MenuPresentationAnimator {
    private func animateWithMenu(menu: MenuViewController, browserViewController bvc: BrowserViewController, transitionContext: UIViewControllerContextTransitioning) {
        let leftViews: [UIView]?
        let rightViews: [UIView]?
        let sourceView: UIView?
        if let toolbar = bvc.toolbar {
            leftViews = [toolbar.backButton, toolbar.forwardButton]
            rightViews = [toolbar.stopReloadButton, toolbar.shareButton, toolbar.homePageButton]
            sourceView = toolbar.menuButton
        } else {
            sourceView = nil
            leftViews = nil
            rightViews = nil
        }

        self.animateWithMenu(menu, baseController: bvc, viewsToAnimateLeft: leftViews, viewsToAnimateRight: rightViews, sourceView: sourceView, withTransitionContext: transitionContext)
    }

    private func animateWithMenu(menu: MenuViewController, tabTrayController ttc: TabTrayController, transitionContext: UIViewControllerContextTransitioning) {
        animateWithMenu(menu, baseController: ttc, viewsToAnimateLeft: ttc.leftToolbarButtons, viewsToAnimateRight: ttc.rightToolbarButtons, sourceView: ttc.toolbar.menuButton, withTransitionContext: transitionContext)
    }

    private func animateWithMenu(menuController: MenuViewController, baseController: UIViewController, viewsToAnimateLeft: [UIView]?, viewsToAnimateRight: [UIView]?, sourceView: UIView?, withTransitionContext transitionContext: UIViewControllerContextTransitioning) {

        guard let container = transitionContext.containerView() else { return }

        let menuView = menuController.view
        menuView.frame = container.bounds
        let bottomView = baseController.view

        // Insert tab tray below the browser and force a layout so the collection view can get it's frame right
        if presenting {
            container.insertSubview(menuView, belowSubview: bottomView)
            menuView.layoutSubviews()
        }

        let vanishingPoint: CGPoint
        if let sourceView = sourceView {
            vanishingPoint = menuView.convertPoint(sourceView.center, fromView: sourceView.superview)
        } else {
            vanishingPoint = CGPoint(x: menuView.center.x, y: menuView.frame.size.height)
        }
        let minimisedFrame = CGRect(origin: vanishingPoint, size: CGSize.zero)

        let menuViewSnapshot: UIView
        if presenting {
            menuViewSnapshot = menuView.snapshotViewAfterScreenUpdates(true)
            menuViewSnapshot.frame = minimisedFrame
            menuViewSnapshot.alpha = 0
            menuView.backgroundColor = menuView.backgroundColor?.colorWithAlphaComponent(0.0)
            menuView.addSubview(menuViewSnapshot)
        } else {
            menuViewSnapshot = menuView.snapshotViewAfterScreenUpdates(false)
            menuViewSnapshot.frame = menuView.frame
            container.insertSubview(menuViewSnapshot, aboveSubview: menuView)
            menuView.hidden = true
        }

        let offstageValue = bottomView.bounds.size.width / 2
        let offstageLeft = CGAffineTransformMakeTranslation(-offstageValue, 0)
        let offstageRight = CGAffineTransformMakeTranslation(offstageValue, 0)

        if presenting {
            menuView.alpha = 0
            menuController.menuView.hidden = true
        } else {
            // move the buttons to their offstage positions
            viewsToAnimateLeft?.forEach { $0.transform = offstageLeft }
            viewsToAnimateRight?.forEach { $0.transform = offstageRight }
        }

        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {

            if (self.presenting) {
                menuViewSnapshot.alpha = 1
                menuViewSnapshot.frame = menuView.frame
                menuView.backgroundColor = menuView.backgroundColor?.colorWithAlphaComponent(0.4)
                menuView.alpha = 1
                // animate back and forward buttons off to the left
                viewsToAnimateLeft?.forEach { $0.transform = offstageLeft }
                // animate reload and share buttons off to the right
                viewsToAnimateRight?.forEach { $0.transform = offstageRight }
            }
            else {
                // animate back and forward buttons in from the left
                viewsToAnimateLeft?.forEach { $0.transform = CGAffineTransformIdentity }
                // animate reload and share buttons in from the right
                viewsToAnimateRight?.forEach { $0.transform = CGAffineTransformIdentity }
                menuViewSnapshot.frame = minimisedFrame
                menuViewSnapshot.alpha = 0
                menuView.alpha = 0
            }

            }, completion: { finished in
                menuViewSnapshot.removeFromSuperview()
                // tell our transitionContext object that we've finished animating
                menuController.menuView.hidden = !self.presenting
                transitionContext.completeTransition(true)
        })
    }
}
