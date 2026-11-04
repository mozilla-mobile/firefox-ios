// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// The presenting view stays in the window below the transition container, so to slide it over Quick
/// Answers the animator keeps a snapshot of the Quick Answers view behind it and hides the original.
/// While `isActive` it handles both directions, otherwise they are handed to `fallback`, or to the
/// system when `fallback` is nil.
final class ReturnToBrowserTransitionAnimator: NSObject,
                                               UIViewControllerTransitioningDelegate,
                                               UIViewControllerAnimatedTransitioning {
    private struct UX {
        static let springDuration: TimeInterval = 0.55
        static let springDamping: CGFloat = 0.82
        static let reverseDuration: TimeInterval = 0.4
        static let reverseDamping: CGFloat = 1.0
    }

    private let isActive: () -> Bool
    let fallback: UIViewControllerTransitioningDelegate?

    init(isActive: @escaping () -> Bool, fallback: UIViewControllerTransitioningDelegate?) {
        self.isActive = isActive
        self.fallback = fallback
    }

    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        guard isActive() else {
            return fallback?.animationController?(forPresented: presented, presenting: presenting, source: source)
        }
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        guard isActive() else {
            return fallback?.animationController?(forDismissed: dismissed)
        }
        return self
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isPresenting(transitionContext) ? UX.reverseDuration : UX.springDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if isPresenting(transitionContext) {
            animatePresentation(transitionContext)
        } else {
            animateDismissal(transitionContext)
        }
    }

    // MARK: - Presentation
    private func animatePresentation(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedController = transitionContext.viewController(forKey: .to),
              let presentingView = transitionContext.viewController(forKey: .from)?.view
        else {
            transitionContext.completeTransition(false)
            return
        }
        let containerView = transitionContext.containerView
        let toView: UIView = transitionContext.view(forKey: .to) ?? presentedController.view
        containerView.addSubview(toView)
        toView.frame = transitionContext.finalFrame(for: presentedController)
        toView.layoutIfNeeded()

        guard transitionContext.isAnimated,
              let snapshot = toView.snapshotView(afterScreenUpdates: true)
        else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        snapshot.frame = presentingView.frame
        presentingView.superview?.insertSubview(snapshot, belowSubview: presentingView)
        toView.alpha = 0.0

        let animator = UIViewPropertyAnimator(duration: UX.reverseDuration, dampingRatio: UX.reverseDamping) {
            presentingView.transform = CGAffineTransform(translationX: 0.0, y: containerView.bounds.height)
        }
        animator.addCompletion { _ in
            toView.alpha = 1.0
            presentingView.transform = .identity
            snapshot.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        animator.startAnimation()
    }

    // MARK: - Dismissal
    private func animateDismissal(_ transitionContext: UIViewControllerContextTransitioning) {
        guard transitionContext.isAnimated,
              let fromView = transitionContext.view(forKey: .from),
              let presentingView = transitionContext.viewController(forKey: .to)?.view,
              let snapshot = fromView.snapshotView(afterScreenUpdates: false)
        else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }
        snapshot.frame = presentingView.frame
        presentingView.superview?.insertSubview(snapshot, belowSubview: presentingView)
        fromView.alpha = 0.0
        presentingView.transform = CGAffineTransform(
            translationX: 0.0,
            y: transitionContext.containerView.bounds.height
        )

        let animator = UIViewPropertyAnimator(duration: UX.springDuration, dampingRatio: UX.springDamping) {
            presentingView.transform = .identity
        }
        animator.addCompletion { _ in
            snapshot.removeFromSuperview()
            fromView.alpha = 1.0
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        animator.startAnimation()
    }

    // MARK: - Helpers
    private func isPresenting(_ transitionContext: UIViewControllerContextTransitioning?) -> Bool {
        return transitionContext?.viewController(forKey: .to)?.isBeingPresented ?? false
    }
}
