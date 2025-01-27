// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class BackForwardListAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var presenting = false
    let animationDuration = 0.4

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let screens = (
            from: transitionContext.viewController(forKey: .from)!,
            to: transitionContext.viewController(forKey: .to)!
        )

        let screensFrom = screens.from as? BackForwardListViewController
        let screensTo = screens.to as? BackForwardListViewController
        guard let backForwardViewController = !self.presenting ? screensFrom : screensTo else { return }

        var bottomViewController = !self.presenting ? screens.to as UIViewController : screens.from as UIViewController

        if let navController = bottomViewController as? UINavigationController {
            bottomViewController = navController.viewControllers.last ?? bottomViewController
        }

        if let browserViewController = bottomViewController as? BrowserViewController {
            animateWithBackForward(
                backForwardViewController,
                browserViewController: browserViewController,
                transitionContext: transitionContext
            )
        }
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
}

extension BackForwardListAnimator: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
}

extension BackForwardListAnimator {
    fileprivate func animateWithBackForward(
        _ backForward: BackForwardListViewController,
        browserViewController bvc: BrowserViewController,
        transitionContext: UIViewControllerContextTransitioning
    ) {
        let containerView = transitionContext.containerView

        if presenting {
            backForward.view.frame = bvc.view.frame
            backForward.view.alpha = 0
            containerView.addSubview(backForward.view)
            backForward.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                backForward.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                backForward.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                backForward.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                backForward.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            ])
            backForward.view.layoutIfNeeded()

            UIView.animate(
                withDuration: transitionDuration(using: transitionContext),
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.3,
                options: [],
                animations: { () in
                    backForward.view.alpha = 1
                    backForward.tableViewHeightAnchor?.constant = backForward.tableHeight
                    backForward.view.layoutIfNeeded()
                }, completion: { (completed) in
                    transitionContext.completeTransition(completed)
                })
        } else {
            UIView.animate(
                withDuration: transitionDuration(using: transitionContext),
                delay: 0,
                usingSpringWithDamping: 1.2,
                initialSpringVelocity: 0.0,
                options: [],
                animations: { () in
                    backForward.view.alpha = 0
                    backForward.tableViewHeightAnchor?.constant = 0
                    backForward.view.layoutIfNeeded()
                }, completion: { (completed) in
                    backForward.view.removeFromSuperview()
                    transitionContext.completeTransition(completed)
                })
        }
    }
}
