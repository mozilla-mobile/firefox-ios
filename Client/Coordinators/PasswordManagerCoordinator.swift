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
    func pressedPasswordDetail(model: PasswordDetailViewControllerModel)
    func pressedAddPassword(completion: @escaping (LoginEntry) -> Void)
    func openURL(url: URL)
}

class PasswordManagerCoordinator: BaseCoordinator,
                                  PasswordManagerFlowDelegate {
    let profile: Profile
    private weak var passwordManager: PasswordManagerListViewController?
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

    // MARK: - PasswordManagerFlowDelegate

    func continueFromOnboarding() {
        showPasswordManager()
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
