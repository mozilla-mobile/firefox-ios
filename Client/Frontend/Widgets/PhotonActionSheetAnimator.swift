/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class PhotonActionSheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    var presenting: Bool = false
    let animationDuration = 0.4
    
    lazy var shadow: UIView = {
        let shadow = UIView()
        shadow.backgroundColor = UIColor(white: 0, alpha: 0.5)
        return shadow
    }()
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let screens = (from: transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!, to: transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!)
        
        guard let actionSheet = (self.presenting ? screens.to : screens.from) as? PhotonActionSheet else {
            return
        }
        
        let bottomViewController = (self.presenting ? screens.from : screens.to) as UIViewController
        animateWitVC(actionSheet, presentingVC: bottomViewController, transitionContext: transitionContext)
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
}

extension PhotonActionSheetAnimator: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
}

extension PhotonActionSheetAnimator {
    fileprivate func animateWitVC(_ actionSheet: PhotonActionSheet, presentingVC viewController: UIViewController, transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        if presenting {
            shadow.frame = containerView.bounds
            containerView.addSubview(shadow)
            actionSheet.view.frame = CGRect(origin: CGPoint(x: 0, y: containerView.frame.size.height), size: containerView.frame.size)
            self.shadow.alpha = 0
            containerView.addSubview(actionSheet.view)
            actionSheet.view.layoutIfNeeded()
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: [], animations: { () -> Void in
                self.shadow.alpha = 1
                actionSheet.view.frame = containerView.bounds
                actionSheet.view.layoutIfNeeded()
            }, completion: { (completed) -> Void in
                transitionContext.completeTransition(completed)
            })
            
        } else {
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, usingSpringWithDamping: 1.2, initialSpringVelocity: 0.0, options: [], animations: { () -> Void in
                self.shadow.alpha = 0
                actionSheet.view.frame = CGRect(origin: CGPoint(x: 0, y: containerView.frame.size.height), size: containerView.frame.size)
                actionSheet.view.layoutIfNeeded()
            }, completion: { (completed) -> Void in
                actionSheet.view.removeFromSuperview()
                self.shadow.removeFromSuperview()
                transitionContext.completeTransition(completed)
            })
        }
    }
}

