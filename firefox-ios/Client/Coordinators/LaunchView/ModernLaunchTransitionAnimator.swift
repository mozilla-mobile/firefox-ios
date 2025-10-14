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
        static let initialAlpha: CGFloat = 0.0
        static let finalAlpha: CGFloat = 1.0
        static let fadeDelay: TimeInterval = 0.0
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

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toViewController)

        if isDismissing {
        } else {
        }

        toViewController.view.frame = finalFrame
        containerView.addSubview(toViewController.view)

        UIView.animate(
            withDuration: UX.totalDuration,
            delay: UX.fadeDelay,
            options: [.curveEaseIn],
            animations: {
            self.fadeOutLaunchScreenLoader(fromViewController)
            },
        completion: { finished in
            transitionContext.completeTransition(finished)
        })
    }

    private func fadeOutLaunchScreenLoader(_ viewController: UIViewController) {
        if let modernLaunchVC = viewController as? ModernLaunchScreenViewController {
            modernLaunchVC.fadeOutLoader()
        }
    }
}
