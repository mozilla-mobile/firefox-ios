/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@objc
class TransitionOptions {
    var container: UIView? = nil
    var moving: UIView? = nil
    var fromView: UIViewController? = nil
    var toView: UIViewController? = nil
    var duration: NSTimeInterval? = nil
}

@objc
protocol Transitionable : class {
    func transitionablePreShow(transitionable: Transitionable, options: TransitionOptions)
    func transitionablePreHide(transitionable: Transitionable, options: TransitionOptions)
    func transitionableWillHide(transitionable: Transitionable, options: TransitionOptions)
    func transitionableWillShow(transitionable: Transitionable, options: TransitionOptions)
    func transitionableWillComplete(transitionable: Transitionable, options: TransitionOptions)
}

@objc
class TransitionManager: NSObject, UIViewControllerAnimatedTransitioning  {
    private let show: Bool
    init(show: Bool) {
        self.show = show
    }


    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

        let fromView = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toView = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!

        let container = transitionContext.containerView()

        if show {
            container.insertSubview(toView.view, aboveSubview: fromView.view)
        }

        var options = TransitionOptions()
        options.container = container
        options.fromView = fromView
        options.toView = toView
        options.duration = transitionDuration(transitionContext)

        if let to = toView as? Transitionable {
            if let from = fromView as? Transitionable {
                to.transitionableWillHide(to, options: options)
                from.transitionableWillShow(from, options: options)

                let duration = self.transitionDuration(transitionContext)

                to.transitionablePreShow(to, options: options)
                from.transitionablePreHide(from, options: options)

                UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                        to.transitionableWillShow(to, options: options)
                        from.transitionableWillHide(from, options: options)
                    }, completion: { finished in
                        to.transitionableWillComplete(to, options: options)
                        from.transitionableWillComplete(from, options: options)
                        transitionContext.completeTransition(true)
                })

            }
        }
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.4
    }
}
