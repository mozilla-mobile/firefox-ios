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

    var presentCalled = 0
    var dismissCalled = 0
    var pushCalled = 0
    var popViewCalled = 0

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
    }

    func popViewController(animated: Bool) -> UIViewController? {
        popViewCalled += 1
        return presentedViewController
    }

    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        self.viewControllers = viewControllers
    }
}
