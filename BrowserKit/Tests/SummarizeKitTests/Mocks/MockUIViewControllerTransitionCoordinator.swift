// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class MockUIViewControllerTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {
    var isAnimated = false
    var presentationStyle: UIModalPresentationStyle = .none
    var initiallyInteractive = false
    var isInterruptible = false
    var isInteractive = false
    var isCancelled = false
    var transitionDuration: TimeInterval = 0
    var percentComplete: CGFloat = 0
    var completionVelocity: CGFloat = 0
    var completionCurve: UIView.AnimationCurve = .linear
    var containerView = UIView()
    var targetTransform: CGAffineTransform = .identity

    func animate(
        alongsideTransition animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)? = nil
    ) -> Bool {
        animation?(self)
        completion?(self)
        return true
    }

    func animateAlongsideTransition(
        in view: UIView?,
        animation: ((any UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((any UIViewControllerTransitionCoordinatorContext) -> Void)? = nil
    ) -> Bool {
        animation?(self)
        completion?(self)
        return true
    }

    func notifyWhenInteractionEnds(_ handler: @escaping (any UIViewControllerTransitionCoordinatorContext) -> Void) {
    }

    func notifyWhenInteractionChanges(_ handler: @escaping (any UIViewControllerTransitionCoordinatorContext) -> Void) {
    }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        return nil
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        return nil
    }
}
