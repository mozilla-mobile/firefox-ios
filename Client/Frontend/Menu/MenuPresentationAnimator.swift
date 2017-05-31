/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class MenuPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    var presenting: Bool = false

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let screens = (from: transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!, to: transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!)

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
            animateWithMenu(menuViewController, browserViewController: bottomViewController as! BrowserViewController, transitionContext: transitionContext)
        } else if bottomViewController.isKind(of: TabTrayController.self) {
            animateWithMenu(menuViewController, tabTrayController: bottomViewController as! TabTrayController, transitionContext: transitionContext)
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
    fileprivate func animateWithMenu(_ menu: MenuViewController, browserViewController bvc: BrowserViewController, transitionContext: UIViewControllerContextTransitioning) {
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

    fileprivate func animateWithMenu(_ menu: MenuViewController, tabTrayController ttc: TabTrayController, transitionContext: UIViewControllerContextTransitioning) {
        animateWithMenu(menu, baseController: ttc, viewsToAnimateLeft: ttc.leftToolbarButtons, viewsToAnimateRight: ttc.rightToolbarButtons, sourceView: ttc.toolbar.menuButton, withTransitionContext: transitionContext)
    }

    fileprivate func animateWithMenu(_ menuController: MenuViewController, baseController: UIViewController, viewsToAnimateLeft: [UIView]?, viewsToAnimateRight: [UIView]?, sourceView: UIView?, withTransitionContext transitionContext: UIViewControllerContextTransitioning) {

        let container = transitionContext.containerView

        // If we don't have any views abort the animation since there isn't anything to animate.
        guard let menuView = menuController.view, let bottomView = baseController.view else {
            transitionContext.completeTransition(true)
            return
        }
        menuView.frame = container.bounds

        let bgView = UIView()
        bgView.frame = container.bounds

        if presenting {
            container.addSubview(menuView)
            container.insertSubview(bgView, belowSubview: menuView)
            menuView.layoutSubviews()
        }

        let vanishingPoint = CGPoint(x: menuView.frame.origin.x, y: menuView.frame.size.height)
        let minimisedFrame = CGRect(origin: vanishingPoint, size: menuView.frame.size)

        if presenting {
            menuView.frame = minimisedFrame
        }

        let offstageValue = bottomView.bounds.size.width / 2
        let offstageLeft = CGAffineTransform(translationX: -offstageValue, y: 0)
        let offstageRight = CGAffineTransform(translationX: offstageValue, y: 0)

        if presenting {
            bgView.backgroundColor = menuView.backgroundColor?.withAlphaComponent(0.0)
        } else {
            bgView.backgroundColor = menuView.backgroundColor?.withAlphaComponent(0.4)
            // move the buttons to their offstage positions
            viewsToAnimateLeft?.forEach { $0.transform = offstageLeft }
            viewsToAnimateRight?.forEach { $0.transform = offstageRight }
        }

        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {

            if self.presenting {
                menuView.frame = container.bounds
                bgView.backgroundColor = menuView.backgroundColor?.withAlphaComponent(0.4)
                // animate back and forward buttons off to the left
                viewsToAnimateLeft?.forEach { $0.transform = offstageLeft }
                // animate reload and share buttons off to the right
                viewsToAnimateRight?.forEach { $0.transform = offstageRight }
            } else {
                menuView.frame = minimisedFrame
                bgView.backgroundColor = menuView.backgroundColor?.withAlphaComponent(0.0)
                // animate back and forward buttons in from the left
                viewsToAnimateLeft?.forEach { $0.transform = CGAffineTransform.identity }
                // animate reload and share buttons in from the right
                viewsToAnimateRight?.forEach { $0.transform = CGAffineTransform.identity }
            }

            }, completion: { finished in
                bgView.removeFromSuperview()
                transitionContext.completeTransition(true)
        })
    }
}
