// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

protocol MicrosurveyCoordinatorDelegate: AnyObject {
    func dismissFlow()
    func showPrivacy()
}

final class MicrosurveyCoordinator: BaseCoordinator, FeatureFlaggable, MicrosurveyCoordinatorDelegate {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    private let tabManager: TabManager
    private var windowUUID: WindowUUID { return tabManager.windowUUID }
    private let model: MicrosurveyModel

    init(model: MicrosurveyModel,
         router: Router,
         tabManager: TabManager) {
        self.tabManager = tabManager
        self.model = model
        super.init(router: router)
    }

    func start() {
        let microSurveyViewController = MicrosurveyViewController(model: model, windowUUID: windowUUID)
        microSurveyViewController.coordinator = self
        router.setRootViewController(microSurveyViewController, hideBar: true)
    }

    func dismissFlow() {
        router.dismiss(animated: true, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }

    func showPrivacy() {
        // TODO: FXIOS-8976 - Add to Support Utils
        guard let url = URL(string: "https://www.mozilla.org/privacy/firefox") else { return }
        tabManager.addTabsForURLs([url], zombie: false, shouldSelectTab: true)
        router.dismiss(animated: true, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }
}
