// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol SearchEngineSelectionCoordinatorDelegate: AnyObject {
    func showSettings(at destination: Route.SettingsSection)
}

class SearchEngineSelectionCoordinator: BaseCoordinator, FeatureFlaggable {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    weak var navigationHandler: SearchEngineSelectionCoordinatorDelegate?

    private let windowUUID: WindowUUID

    init(router: Router, windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        super.init(router: router)
    }

    func start() {
        router.setRootViewController(
            createSearchEngineSelectionViewController(),
            hideBar: true
        )
    }

    func navigateToSearchSettings(animated: Bool) {
        router.dismiss(animated: animated, completion: { [weak self] in
            guard let self else { return }

            self.navigationHandler?.showSettings(at: .search)

            self.parentCoordinator?.didFinish(from: self)
        })
    }

    func dismissModal(animated: Bool) {
        router.dismiss(animated: animated, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }

    // MARK: - Private helpers

    private func createSearchEngineSelectionViewController() -> SearchEngineSelectionViewController {
        let vc = SearchEngineSelectionViewController(windowUUID: windowUUID)
        vc.coordinator = self
        return vc
    }
}
