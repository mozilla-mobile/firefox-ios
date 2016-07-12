/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class MenuPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    var presenting: Bool = false

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let screens = (from: transitionContext.viewController(forKey: UITransitionContextFromViewControllerKey)!, to: transitionContext.viewController(forKey: UITransitionContextToViewControllerKey)!)

        guard let menuViewController = !self.presenting ? screens.from as? MenuViewController : screens.to as? MenuViewController else {
            return
        }

        var bottomViewController = !self.presenting ? screens.to as UIViewController : screens.from as UIViewController

        // don't do anything special if it's a popover presentation
        if menuViewController.presentationStyle == .popover {
            return
        }

        if let navController = bottomViewController as? UINavigationController {
            bottomViewController = navController.viewControllers.last ?? bottomViewController
        }

        if bottomViewController.isKind(of: BrowserViewController.self) {
            animate(withMenu: menuViewController, browserViewController: bottomViewController as! BrowserViewController, transitionContext: transitionContext)
        } else if bottomViewController.isKind(of: TabTrayController.self) {
            animate(withMenu: menuViewController, tabTrayController: bottomViewController as! TabTrayController, transitionContext: transitionContext)
        }
    }


    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return presenting ? 0.4 : 0.2
    }
}

extension MenuPresentationAnimator: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
}

extension MenuPresentationAnimator {
    private func animate(withMenu menu: MenuViewController, browserViewController bvc: BrowserViewController, transitionContext: UIViewControllerContextTransitioning) {
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

        self.animate(withMenu: menu, baseController: bvc, viewsToAnimateLeft: leftViews, viewsToAnimateRight: rightViews, sourceView: sourceView, withTransitionContext: transitionContext)
    }

    private func animate(withMenu menu: MenuViewController, tabTrayController ttc: TabTrayController, transitionContext: UIViewControllerContextTransitioning) {
        animate(withMenu: menu, baseController: ttc, viewsToAnimateLeft: ttc.leftToolbarButtons, viewsToAnimateRight: ttc.rightToolbarButtons, sourceView: ttc.toolbar.menuButton, withTransitionContext: transitionContext)
    }

    private func animate(withMenu menuController: MenuViewController, baseController: UIViewController, viewsToAnimateLeft: [UIView]?, viewsToAnimateRight: [UIView]?, sourceView: UIView?, withTransitionContext transitionContext: UIViewControllerContextTransitioning) {

        guard let container = transitionContext.containerView() else { return }

        let menuView = menuController.view
        menuView.frame = container.bounds
        let bottomView = baseController.view

        // Insert tab tray below the browser and force a layout so the collection view can get it's frame right
        if presenting {
            container.insertSubview(menuView, belowSubview: bottomView)
            menuView?.layoutSubviews()
        }

        let vanishingPoint: CGPoint
        if let sourceView = sourceView {
            vanishingPoint = (menuView?.convert(sourceView.center, from: sourceView.superview))!
        } else {
            vanishingPoint = CGPoint(x: (menuView?.center.x)!, y: (menuView?.frame.size.height)!)
        }
        let minimisedFrame = CGRect(origin: vanishingPoint, size: CGSize.zero)

        let menuViewSnapshot: UIView
        if presenting {
            menuViewSnapshot = (menuView?.snapshotView(afterScreenUpdates: true)!)!
            menuViewSnapshot.frame = minimisedFrame
            menuViewSnapshot.alpha = 0
            menuView?.backgroundColor = menuView?.backgroundColor?.withAlphaComponent(0.0)
            menuView?.addSubview(menuViewSnapshot)
        } else {
            menuViewSnapshot = (menuView?.snapshotView(afterScreenUpdates: false)!)!
            menuViewSnapshot.frame = (menuView?.frame)!
            container.insertSubview(menuViewSnapshot, aboveSubview: menuView)
            menuView?.isHidden = true
        }

        let offstageValue = (bottomView?.bounds.size.width)! / 2
        let offstageLeft = CGAffineTransform(translationX: -offstageValue, y: 0)
        let offstageRight = CGAffineTransform(translationX: offstageValue, y: 0)

        if presenting {
            menuView?.alpha = 0
            menuController.menuView.isHidden = true
        } else {
            // move the buttons to their offstage positions
            viewsToAnimateLeft?.forEach { $0.transform = offstageLeft }
            viewsToAnimateRight?.forEach { $0.transform = offstageRight }
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {

            if (self.presenting) {
                menuViewSnapshot.alpha = 1
                menuViewSnapshot.frame = (menuView?.frame)!
                menuView?.backgroundColor = menuView?.backgroundColor?.withAlphaComponent(0.4)
                menuView?.alpha = 1
                // animate back and forward buttons off to the left
                viewsToAnimateLeft?.forEach { $0.transform = offstageLeft }
                // animate reload and share buttons off to the right
                viewsToAnimateRight?.forEach { $0.transform = offstageRight }
            }
            else {
                // animate back and forward buttons in from the left
                viewsToAnimateLeft?.forEach { $0.transform = CGAffineTransform.identity }
                // animate reload and share buttons in from the right
                viewsToAnimateRight?.forEach { $0.transform = CGAffineTransform.identity }
                menuViewSnapshot.frame = minimisedFrame
                menuViewSnapshot.alpha = 0
                menuView?.alpha = 0
            }

            }, completion: { finished in
                menuViewSnapshot.removeFromSuperview()
                // tell our transitionContext object that we've finished animating
                menuController.menuView.isHidden = !self.presenting
                transitionContext.completeTransition(true)
        })
    }
}
