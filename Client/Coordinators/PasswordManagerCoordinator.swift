// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol PasswordManagerCoordinatorDelegate: AnyObject {
    func settingsOpenURLInNewTab(_ url: URL)
    func didFinishPasswordManager(from coordinator: PasswordManagerCoordinator)
}

protocol PasswordManagerFlowDelegate: AnyObject {
    func continueFromOnboarding()
    func showDevicePassCode()
    func pressedPasswordDetail(model: PasswordDetailViewControllerModel)
    func pressedAddPassword(completion: @escaping (LoginEntry) -> Void)
    func openURL(url: URL)
}

class PasswordManagerCoordinator: BaseCoordinator,
                                  PasswordManagerFlowDelegate {
    let profile: Profile
    weak var passwordManager: PasswordManagerListViewController?
    weak var parentCoordinator: PasswordManagerCoordinatorDelegate?

    init(router: Router, profile: Profile) {
        self.profile = profile
        super.init(router: router)
    }

    func start(with shouldShowOnboarding: Bool) {
        if shouldShowOnboarding {
            showPasswordOnboarding()
        } else {
            showPasswordManager()
        }
    }

    func showPasswordManager() {
        let viewController = PasswordManagerListViewController(profile: profile)
        viewController.coordinator = self
        router.push(viewController)
        passwordManager = viewController
    }

    func showPasswordOnboarding() {
        let viewController = PasswordManagerOnboardingViewController()
        viewController.coordinator = self
        router.push(viewController)
    }

    func showDevicePassCode() {
        let passcodeViewController = DevicePasscodeRequiredViewController()
        passcodeViewController.profile = profile
        router.push(passcodeViewController)
    }

    // MARK: - PasswordManagerFlowDelegate

    func continueFromOnboarding() {
        showPasswordManager()

        // Remove the onboarding from the navigation stack so that we go straight back to settings
        guard let navigationController = router.navigationController as? UINavigationController else { return }
        navigationController.viewControllers.removeAll(where: { viewController in
            type(of: viewController) == PasswordManagerOnboardingViewController.self
        })
    }

    func pressedPasswordDetail(model: PasswordDetailViewControllerModel) {
        let viewController = PasswordDetailViewController(viewModel: model)
        viewController.coordinator = self
        router.push(viewController)
    }

    func pressedAddPassword(completion: @escaping (LoginEntry) -> Void) {
        let viewController = AddCredentialViewController(didSaveAction: completion)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .formSheet
        passwordManager?.present(navigationController, animated: true)
    }

    func openURL(url: URL) {
        parentCoordinator?.settingsOpenURLInNewTab(url)
        parentCoordinator?.didFinishPasswordManager(from: self)
    }
}
