// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// While the opt-in sheet is pending, transitions instantly. When presenting, the whole presentation is
/// hidden so the sheet slides up over the browser and the presented controller reveals itself afterwards.
/// Every other transition is handed to `fallback`, or to the system one when `fallback` is nil.
final class OptInTransitionAnimator: NSObject,
                                     UIViewControllerTransitioningDelegate,
                                     UIViewControllerAnimatedTransitioning {
    private let isOptInSheetPending: () -> Bool
    private let fallback: UIViewControllerTransitioningDelegate?
    /// The presentation container hidden while presenting, to be revealed once the opt-in sheet is up.
    private(set) weak var hiddenContainerView: UIView?

    init(isOptInSheetPending: @escaping () -> Bool, fallback: UIViewControllerTransitioningDelegate?) {
        self.isOptInSheetPending = isOptInSheetPending
        self.fallback = fallback
    }

    // MARK: - UIViewControllerTransitioningDelegate
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        guard isOptInSheetPending() else {
            return fallback?.animationController?(forPresented: presented, presenting: presenting, source: source)
        }
        return self
    }

    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        guard isOptInSheetPending() else {
            return fallback?.animationController?(forDismissed: dismissed)
        }
        return self
    }

    // MARK: - UIViewControllerAnimatedTransitioning
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.0
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let presentedController = transitionContext.viewController(forKey: .to),
           presentedController.isBeingPresented {
            let containerView = transitionContext.containerView
            // The container also holds the system chrome, like the form sheet dimming, so all of it stays hidden.
            containerView.isHidden = true
            hiddenContainerView = containerView
            // The form sheet wraps the controller's view to draw its card, so the wrapper is the one to add.
            let presentedView: UIView = transitionContext.view(forKey: .to) ?? presentedController.view
            presentedView.frame = transitionContext.finalFrame(for: presentedController)
            containerView.addSubview(presentedView)
        }
        transitionContext.completeTransition(true)
    }
}
