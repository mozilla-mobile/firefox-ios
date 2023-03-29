// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockRouter: NSObject, Router {
    var navigationController: NavigationController
    var rootViewController: UIViewController?

    init(navigationController: NavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    var presentCalled = 0
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        presentCalled += 1
    }

    var dismissCalled = 0
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        dismissCalled += 1
    }

    var pushCalled = 0
    func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        pushCalled += 1
    }

    var popViewControllerCalled = 0
    func popViewController(animated: Bool) {
        popViewControllerCalled += 1
    }

    var setRootViewControllerCalled = 0
    func setRootViewController(_ viewController: UIViewController, hideBar: Bool) {
        setRootViewControllerCalled += 1
    }

    var popToRootModuleCalled = 0
    func popToRootViewController(animated: Bool) {
        popToRootModuleCalled += 1
    }
}
