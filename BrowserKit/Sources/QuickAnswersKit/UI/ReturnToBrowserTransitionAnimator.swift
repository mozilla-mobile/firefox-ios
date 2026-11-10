// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Presenting slides the presenting view down to reveal Quick Answers, which scales up behind it.
/// Dismissing shrinks Quick Answers while the presenting view slides back up over it.
/// While `isActive` it handles both directions, otherwise they are handed to `fallback`, or to the
/// system when `fallback` is nil.
final class ReturnToBrowserTransitionAnimator: NSObject,
                                               UIViewControllerTransitioningDelegate,
                                               UIViewControllerAnimatedTransitioning {
    private struct UX {
        static let duration: TimeInterval = 0.4
        static let damping: CGFloat = 1.0
        static let stackedTransform = CGAffineTransform(scaleX: 0.92, y: 0.92)
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
        return UX.duration
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

        guard transitionContext.isAnimated else {
            transitionContext.completeTransition(true)
            return
        }
        let restorePresentingView = liftPresentingView(presentingView, above: toView, in: containerView)
        let contentView = transitionContentView(in: presentedController)
        contentView?.transform = UX.stackedTransform

        UIView.animate(
            withDuration: UX.duration,
            delay: 0.0,
            usingSpringWithDamping: UX.damping,
            initialSpringVelocity: 0.0
        ) {
            contentView?.transform = .identity
            presentingView.transform = CGAffineTransform(translationX: 0.0, y: containerView.bounds.height)
        } completion: { _ in
            restorePresentingView()
            transitionContext.completeTransition(true)
        }
    }

    // MARK: - Dismissal
    private func animateDismissal(_ transitionContext: UIViewControllerContextTransitioning) {
        guard transitionContext.isAnimated,
              let fromView = transitionContext.view(forKey: .from),
              let presentingView = transitionContext.viewController(forKey: .to)?.view
        else {
            transitionContext.completeTransition(true)
            return
        }
        let containerView = transitionContext.containerView
        let contentView = transitionContentView(in: transitionContext.viewController(forKey: .from))
        let restorePresentingView = liftPresentingView(presentingView, above: fromView, in: containerView)
        presentingView.transform = CGAffineTransform(translationX: 0.0, y: containerView.bounds.height)

        UIView.animate(
            withDuration: UX.duration,
            delay: 0.0,
            usingSpringWithDamping: UX.damping,
            initialSpringVelocity: 0.0
        ) {
            contentView?.transform = UX.stackedTransform
            presentingView.transform = .identity
        } completion: { _ in
            restorePresentingView()
            transitionContext.completeTransition(true)
        }
    }

    // MARK: - Helpers
    /// The presenting view lives below the transition container, so to slide it over Quick Answers it is
    /// moved into the container for the duration of the transition. Returns the closure that puts it back.
    private func liftPresentingView(
        _ presentingView: UIView,
        above view: UIView,
        in containerView: UIView
    ) -> () -> Void {
        let originalSuperview = presentingView.superview
        let originalIndex = originalSuperview?.subviews.firstIndex(of: presentingView) ?? 0
        let originalFrame = presentingView.frame
        presentingView.frame = containerView.bounds
        containerView.insertSubview(presentingView, aboveSubview: view)
        return {
            presentingView.transform = .identity
            presentingView.frame = originalFrame
            originalSuperview?.insertSubview(presentingView, at: originalIndex)
        }
    }

    private func transitionContentView(in controller: UIViewController?) -> UIView? {
        let rootController = (controller as? UINavigationController)?.viewControllers.first ?? controller
        return (rootController as? QuickAnswersViewController)?.transitionContentView
    }

    private func isPresenting(_ transitionContext: UIViewControllerContextTransitioning?) -> Bool {
        return transitionContext?.viewController(forKey: .to)?.isBeingPresented ?? false
    }
}
