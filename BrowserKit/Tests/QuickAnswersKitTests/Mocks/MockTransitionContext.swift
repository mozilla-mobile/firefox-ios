// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class MockTransitionContext: NSObject, UIViewControllerContextTransitioning {
    let containerView = UIView()
    var toViewController: UIViewController?
    var toView: UIView?
    var fromViewController: UIViewController?
    var fromView: UIView?
    var finalFrame: CGRect = .zero
    var completeTransitionCallCount = 0
    var lastDidComplete: Bool?

    var isAnimated = true
    var isInteractive: Bool { return false }
    var transitionWasCancelled: Bool { return false }
    var presentationStyle: UIModalPresentationStyle { return .custom }
    var targetTransform: CGAffineTransform { return .identity }

    func updateInteractiveTransition(_ percentComplete: CGFloat) {}
    func finishInteractiveTransition() {}
    func cancelInteractiveTransition() {}
    func pauseInteractiveTransition() {}

    func completeTransition(_ didComplete: Bool) {
        completeTransitionCallCount += 1
        lastDidComplete = didComplete
    }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        return key == .to ? toViewController : fromViewController
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        return key == .to ? toView : fromView
    }

    func initialFrame(for vc: UIViewController) -> CGRect {
        return .zero
    }

    func finalFrame(for vc: UIViewController) -> CGRect {
        return finalFrame
    }
}

final class MockPresentedViewController: UIViewController {
    var isBeingPresentedValue = true

    override var isBeingPresented: Bool {
        return isBeingPresentedValue
    }
}
