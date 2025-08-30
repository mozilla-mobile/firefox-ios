// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Custom transition animator for modern launch screen to onboarding/ToS transitions
class ModernLaunchTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    // MARK: - UX Constants
    private enum UX {
        static let totalDuration: TimeInterval = 0.6
        static let fadeOutDurationRatio = 0.4
        static let fadeInDurationRatio = 0.6
        static let initialAlpha: CGFloat = 0.0
        static let finalAlpha: CGFloat = 1.0
        static let fadeOutDelay: TimeInterval = 0
        static let fadeInDelay: TimeInterval = 0
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

        toViewController.view.frame = finalFrame
        toViewController.view.alpha = UX.initialAlpha
        containerView.addSubview(toViewController.view)

        fadeOutLaunchScreenLoader(fromViewController) {
            // Once the loader fade-out completes, start the fade-in animation
            UIView.animate(
                withDuration: UX.totalDuration * UX.fadeInDurationRatio,
                delay: UX.fadeInDelay,
                options: [.curveEaseIn],
                animations: {
                    toViewController.view.alpha = UX.finalAlpha
                }
            ) { finished in
                transitionContext.completeTransition(finished)
            }
        }
    }

    private func fadeOutLaunchScreenLoader(_ viewController: UIViewController, completion: @escaping () -> Void) {
        if let modernLaunchVC = viewController as? ModernLaunchScreenViewController {
            modernLaunchVC.fadeOutLoader(completion: completion)
        } else {
            // If it's not a ModernLaunchScreenViewController, just call the completion immediately
            completion()
        }
    }
}
