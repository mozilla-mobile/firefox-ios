// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockNavigationController: NavigationController {
    var transitionCoordinator: UIViewControllerTransitionCoordinator?
    var presentedViewController: UIViewController?
    var viewControllers: [UIViewController] = []
    var delegate: UINavigationControllerDelegate?
    var isNavigationBarHidden = false
    var fromViewController: UIViewController?
    var topViewController: UIViewController?

    var presentCalled = 0
    var dismissCalled = 0
    var pushCalled = 0
    var popViewCalled = 0
    var popToViewControllerCalled = 0

    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentCalled += 1
        presentedViewController = viewControllerToPresent
    }

    func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissCalled += 1
    }

    func pushViewController(_ viewController: UIViewController, animated: Bool) {
        pushCalled += 1
        presentedViewController = viewController
        topViewController = viewController
        viewControllers.append(viewController)
    }

    func popViewController(animated: Bool) -> UIViewController? {
        popViewCalled += 1
        viewControllers.removeLast()
        return presentedViewController
    }

    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        self.viewControllers = viewControllers
    }

    func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        popToViewControllerCalled += 1

        // Simulate popping everything above the target
        guard let index = viewControllers.firstIndex(of: viewController),
              index < viewControllers.count - 1 else {
            return nil
        }

        let popped = Array(viewControllers[(index + 1)...])
        viewControllers.removeSubrange((index + 1)...)
        return popped
    }
}
