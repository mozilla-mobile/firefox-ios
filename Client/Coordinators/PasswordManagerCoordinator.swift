// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol PasswordManagerFlowDelegate: AnyObject {
    func continueFromOnboarding()
    func pressedPasswordDetail(model: PasswordDetailViewControllerModel)
    func pressedAddPassword(completion: @escaping (LoginEntry) -> Void)
}

class PasswordManagerCoordinator: BaseCoordinator, PasswordManagerFlowDelegate {
    let profile: Profile
    weak var passwordManager: PasswordManagerListViewController?
    weak var settingsDelegate: SettingsDelegate?

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
//        let navigationHandler: (_ url: URL?) -> Void = { [weak self] url in
////            guard let url = url else { return }
////            self?.settingsOpenURLInNewTab(url)
////            self?.didFinish()
//        }
//
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

    func finishPasswordManagerFlow() {}

    // MARK: - PasswordManagerFlowDelegate

    func continueFromOnboarding() {
        showPasswordManager()
    }

    func pressedPasswordDetail(model: PasswordDetailViewControllerModel) {
        let viewController = PasswordDetailViewController(viewModel: model)
        viewController.settingsDelegate = settingsDelegate
        router.push(viewController)
    }

    func pressedAddPassword(completion: @escaping (LoginEntry) -> Void) {
        let viewController = AddCredentialViewController(didSaveAction: completion)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .formSheet
        passwordManager?.present(navigationController, animated: true)
    }
}
