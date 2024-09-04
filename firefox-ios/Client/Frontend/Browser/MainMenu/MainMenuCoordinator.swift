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

    func dismissModal(animated: Bool) {
        router.dismiss(animated: animated, completion: nil)
        parentCoordinator?.didFinish(from: self)
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
