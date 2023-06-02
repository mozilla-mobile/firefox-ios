// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol NavigationController: UIViewController {
    var viewControllers: [UIViewController] { get }
    var delegate: UINavigationControllerDelegate? { get set }
    var isNavigationBarHidden: Bool { get set }
    var transitionCoordinator: UIViewControllerTransitionCoordinator? { get }
    var fromViewController: UIViewController? { get }
    var topPresentedViewController: UIViewController? { get }

    func pushViewController(_ viewController: UIViewController, animated: Bool)
    func popViewController(animated: Bool) -> UIViewController?
    func setViewControllers(_ viewControllers: [UIViewController], animated: Bool)
}

extension UINavigationController: NavigationController {
    var fromViewController: UIViewController? {
        return transitionCoordinator?.viewController(forKey: .from)
    }

    var topPresentedViewController: UIViewController? {
        return presentedViewController
    }
}
