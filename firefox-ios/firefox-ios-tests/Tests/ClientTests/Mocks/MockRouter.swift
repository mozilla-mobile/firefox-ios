// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockRouter: NSObject, Router {
    var navigationController: NavigationController
    var rootViewController: UIViewController?

    var isPresenting: Bool {
        return presentCalled != 0
    }

    var presentedViewController: UIViewController?
    var presentCalled = 0
    var presentCalledWithAnimation = 0
    var dismissCalled = 0
    var pushedViewController: UIViewController?
    var pushCalled = 0
    var popViewControllerCalled = 0
    var setRootViewControllerCalled = 0
    var savedCompletion: (() -> Void)?
    var isNavigationBarHidden = false

    init(navigationController: NavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        savedCompletion = completion
        presentedViewController = viewController
        presentCalled += 1
    }

    func present(_ viewController: UIViewController,
                 animated: Bool,
                 customTransition: UIViewControllerTransitioningDelegate?,
                 presentationStyle: UIModalPresentationStyle) {
        presentedViewController = viewController
        presentCalledWithAnimation += 1
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        savedCompletion = completion
        dismissCalled += 1
    }

    func push(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        savedCompletion = completion
        pushedViewController = viewController
        pushCalled += 1
    }

    func popViewController(animated: Bool) {
        popViewControllerCalled += 1
        savedCompletion?()
        savedCompletion = nil
    }

    func setRootViewController(_ viewController: UIViewController, hideBar: Bool, animated: Bool) {
        rootViewController = viewController
        setRootViewControllerCalled += 1
        isNavigationBarHidden = hideBar
    }
}
