// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockNavigationController: UIViewController, NavigationController {
    var viewControllers: [UIViewController] = []
    var delegate: UINavigationControllerDelegate?
    var isNavigationBarHidden: Bool = false
    var topViewController: UIViewController?
    var fromViewController: UIViewController?

    var presentCalled = 0
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentCalled += 1
        topViewController = viewControllerToPresent
    }

    var dismissCalled = 0
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissCalled += 1
    }

    var pushCalled = 0
    func pushViewController(_ viewController: UIViewController, animated: Bool) {
        pushCalled += 1
        topViewController = viewController
    }

    var popViewCalled = 0
    func popViewController(animated: Bool) -> UIViewController? {
        popViewCalled += 1
        return topViewController
    }

    var popToRootCalled = 0
    func popToRootViewController(animated: Bool) -> [UIViewController]? {
        popToRootCalled += 1
        if let topViewController = topViewController {
            return [topViewController]
        } else {
            return []
        }
    }

    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        self.viewControllers = viewControllers
    }
}
