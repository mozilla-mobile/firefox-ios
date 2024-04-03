// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Common

import struct MozillaAppServices.LoginEntry

protocol PasswordManagerCoordinatorDelegate: AnyObject, ParentCoordinatorDelegate {
    func settingsOpenURLInNewTab(_ url: URL)
    func didFinishPasswordManager(from: PasswordManagerCoordinator)
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
    let windowUUID: WindowUUID

    init(router: Router, profile: Profile, windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
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
        let viewController = PasswordManagerListViewController(profile: profile, windowUUID: windowUUID)
        viewController.coordinator = self
        router.push(viewController) { [weak self] in
            guard let self = self else { return }
            parentCoordinator?.didFinish(from: self)
        }
        passwordManager = viewController
    }

    func showPasswordOnboarding() {
        let viewController = PasswordManagerOnboardingViewController(windowUUID: windowUUID)
        viewController.coordinator = self
        router.push(viewController) { [weak self] in
            guard let self = self else { return }
            parentCoordinator?.didFinish(from: self)
        }
    }

    func showDevicePassCode() {
        let passcodeViewController = DevicePasscodeRequiredViewController(windowUUID: windowUUID)
        passcodeViewController.profile = profile
        passcodeViewController.parentType = .passwords
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
        let viewController = PasswordDetailViewController(viewModel: model, windowUUID: windowUUID)
        viewController.coordinator = self
        viewController.deleteHandler = { [weak self] in
            self?.passwordManager?.showToast()
        }
        router.push(viewController)
    }

    func pressedAddPassword(completion: @escaping (LoginEntry) -> Void) {
        let viewController = AddCredentialViewController(didSaveAction: completion, windowUUID: windowUUID)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .formSheet
        passwordManager?.present(navigationController, animated: true)
    }

    func openURL(url: URL) {
        parentCoordinator?.settingsOpenURLInNewTab(url)
        parentCoordinator?.didFinishPasswordManager(from: self)
    }
}
