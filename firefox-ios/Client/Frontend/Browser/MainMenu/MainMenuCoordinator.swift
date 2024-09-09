// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol MainMenuCoordinatorDelegate: AnyObject {
    // Define any coordinator delegate methods
}

class MainMenuCoordinator: BaseCoordinator, FeatureFlaggable {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    weak var navigationHandler: BrowserNavigationHandler?
    private let tabManager: TabManager

    init(
        router: Router,
        tabManager: TabManager
    ) {
        self.tabManager = tabManager
        super.init(router: router)
    }

    func startModal() {
        let viewController = createMainMenuViewController()

        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        router.present(viewController, animated: true)
    }

    func navigateTo(_ destination: MainMenuNavigationDestination, animated: Bool) {
        router.dismiss(animated: animated, completion: { [weak self] in
            guard let self else { return }

            switch destination {
            case .settings:
                self.navigationHandler?.show(settings: .general)
            }

            self.parentCoordinator?.didFinish(from: self)
        })
    }

    func dismissModal(animated: Bool) {
        router.dismiss(animated: animated, completion: nil)
        self.parentCoordinator?.didFinish(from: self)
    }

    private func createMainMenuViewController() -> MainMenuViewController {
        let mainMenuViewController = MainMenuViewController(
            windowUUID: tabManager.windowUUID,
            viewModel: MainMenuViewModel()
        )
        mainMenuViewController.coordinator = self
        return mainMenuViewController
    }
}
