// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Custom transition animator for modern launch screen to onboarding/ToS transitions
class ModernLaunchTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isDismissing: Bool

    init(isDismissing: Bool) {
        self.isDismissing = isDismissing
    }

    // MARK: - UX Constants
    private enum UX {
        static let totalDuration: TimeInterval = 0.4
        static let clearAlpha: CGFloat = 0.0
        static let midAlpha: CGFloat = 0.6
        static let opaqueAlpha: CGFloat = 1.0
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return UX.totalDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        if isDismissing {
            animateDismiss(
                using: transitionContext,
                fromController: fromViewController,
                toController: toViewController
            )
        } else {
            animatePresent(
                using: transitionContext,
                fromController: fromViewController,
                toController: toViewController
            )
        }
    }

    func animatePresent(
        using transitionContext: UIViewControllerContextTransitioning,
        fromController: UIViewController,
        toController: UIViewController
    ) {
        let fromSnapshot = fromController.view.snapshot
        let image = UIImageView(image: fromSnapshot)
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toController)
        let launchController = fromController as? ModernLaunchScreenViewController

        toController.view.frame = finalFrame
        toController.view.alpha = UX.midAlpha

        containerView.addSubview(toController.view)
        containerView.addSubview(image)
        image.pinToSuperview()

        UIView.animate(withDuration: UX.totalDuration) {
            toController.view.alpha = UX.opaqueAlpha
            launchController?.stopLoaderAnimation()
            image.alpha = UX.clearAlpha
        } completion: { _ in
            image.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }

    func animateDismiss(
        using transitionContext: UIViewControllerContextTransitioning,
        fromController: UIViewController,
        toController: UIViewController
    ) {
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toController)
        toController.view.frame = finalFrame
        let launchController = toController as? ModernLaunchScreenViewController

        containerView.addSubview(toController.view)
        containerView.addSubview(fromController.view)

        UIView.animate(withDuration: UX.totalDuration) {
            launchController?.startLoaderAnimation()
            fromController.view.alpha = UX.clearAlpha
        } completion: { _ in
            transitionContext.completeTransition(true)
            fromController.view.removeFromSuperview()
        }
    }
}
