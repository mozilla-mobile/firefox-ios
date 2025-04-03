// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class DefaultRouter: NSObject, Router {
    var completions: [UIViewController: () -> Void]

    var rootViewController: UIViewController? {
        return navigationController.viewControllers.first
    }

    var isPresenting: Bool {
        return navigationController.presentedViewController != nil
    }

    var navigationController: NavigationController

    init(navigationController: NavigationController) {
        self.navigationController = navigationController
        self.completions = [:]
        super.init()
        self.navigationController.delegate = self
    }

    func present(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        if let completion = completion {
            completions[viewController] = completion
        }

        viewController.presentationController?.delegate = self
        navigationController.present(viewController, animated: animated, completion: nil)
    }

    func present(_ viewController: UIViewController,
                 animated: Bool,
                 customTransition: UIViewControllerTransitioningDelegate?,
                 presentationStyle: UIModalPresentationStyle = .fullScreen) {
        viewController.modalPresentationStyle = presentationStyle

        if let transition = customTransition {
            viewController.transitioningDelegate = transition
        }

        navigationController.present(viewController, animated: animated, completion: nil)
    }

    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        // Make sure we remove reference to the presentedViewController completions
        if let topController = navigationController.presentedViewController {
            completions.removeValue(forKey: topController)
        }
        navigationController.dismiss(animated: animated, completion: completion)
    }

    func push(_ viewController: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        if let completion = completion {
            completions[viewController] = completion
        }

        navigationController.pushViewController(viewController, animated: animated)
    }

    func popViewController(animated: Bool = true) {
        if let controller = navigationController.popViewController(animated: animated) {
            runCompletion(for: controller)
        }
    }

    func setRootViewController(_ viewController: UIViewController, hideBar: Bool = false, animated: Bool = false) {
        // Call all completions so all coordinators can be deallocated
        completions.forEach { $0.value() }
        navigationController.setViewControllers([viewController], animated: animated)
        navigationController.isNavigationBarHidden = hideBar
    }

    private func runCompletion(for controller: UIViewController) {
        guard let completion = completions[controller] else { return }
        completion()
        completions.removeValue(forKey: controller)
    }

    // MARK: - UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        checkNavigationCompletion(for: navigationController)
    }

    func checkNavigationCompletion(for navigationController: NavigationController) {
        // Read the view controller we’re moving from, then check whether our view controller array already contains
        // that view controller. If it does it means we’re pushing a different view controller on top rather than
        // popping it, so exit. Otherwise run the completion of that popped view controller.
        guard let fromViewController = navigationController.fromViewController,
              !navigationController.viewControllers.contains(fromViewController)
        else { return }

        runCompletion(for: fromViewController)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        runCompletion(for: presentationController.presentedViewController)
    }
}
