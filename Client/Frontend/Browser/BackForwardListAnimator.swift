/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class BackForwardListAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var presenting: Bool = false
    let animationDuration = 0.4
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let screens = (from: transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!, to: transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!)
        
        guard let backForwardViewController = !self.presenting ? screens.from as? BackForwardListViewController : screens.to as? BackForwardListViewController else {
            return
        }
        
        var bottomViewController = !self.presenting ? screens.to as UIViewController : screens.from as UIViewController
        
        if let navController = bottomViewController as? UINavigationController {
            bottomViewController = navController.viewControllers.last ?? bottomViewController
        }
        
        if let browserViewController = bottomViewController as? BrowserViewController {
            animateWithBackForward(backForwardViewController, browserViewController: browserViewController, transitionContext: transitionContext)
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
}

extension BackForwardListAnimator: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
}

extension BackForwardListAnimator {
    fileprivate func animateWithBackForward(_ backForward: BackForwardListViewController, browserViewController bvc: BrowserViewController, transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        if presenting {
            backForward.view.frame = bvc.view.frame
            backForward.view.alpha = 0
            containerView.addSubview(backForward.view)
            backForward.view.snp.updateConstraints { make in
                make.edges.equalTo(containerView)
            }
            backForward.view.layoutIfNeeded()
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: [], animations: { () -> Void in
                backForward.view.alpha = 1
                backForward.tableView.snp.updateConstraints { make in
                    make.height.equalTo(backForward.tableHeight)
                }
                backForward.view.layoutIfNeeded()
                }, completion: { (completed) -> Void in
                    transitionContext.completeTransition(completed)
            })
            
        } else {
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 1.2, initialSpringVelocity: 0.0, options: [], animations: { () -> Void in
                backForward.view.alpha = 0
                backForward.tableView.snp.updateConstraints { make in
                    make.height.equalTo(0)
                }
                backForward.view.layoutIfNeeded()
                }, completion: { (completed) -> Void in
                    backForward.view.removeFromSuperview()
                    transitionContext.completeTransition(completed)
            })
        }
    }
}
