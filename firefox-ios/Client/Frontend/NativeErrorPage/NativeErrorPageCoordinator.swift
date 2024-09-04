// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol NativeErrorPageCoordinatorDelegate: AnyObject {
    func dismissFlow()
}

final class NativeErrorPageCoordinator: BaseCoordinator, FeatureFlaggable, NativeErrorPageCoordinatorDelegate {
    weak var parentCoordinator: ParentCoordinatorDelegate?
    private let tabManager: TabManager
    private var windowUUID: WindowUUID { return tabManager.windowUUID }
    private let model: ErrorPageModel
    private let browserViewController: BrowserViewController
    private var overlayManager: OverlayModeManager

    init(model: ErrorPageModel,
         router: Router,
         browserViewController: BrowserViewController,
         tabManager: TabManager,
         overlayManager: OverlayModeManager) {
        self.tabManager = tabManager
        self.browserViewController = browserViewController
        self.model = model
        self.overlayManager = overlayManager
        super.init(router: router)
    }

    func start() {
        let nativeErrorPageViewController = NativeErrorPageViewController(
            model: model,
            windowUUID: windowUUID,
            overlayManager: overlayManager
        )
        nativeErrorPageViewController.coordinator = self
        router.setRootViewController(nativeErrorPageViewController, hideBar: false)

        // TODO: Embed Native Page in BrowserVC,
        // Causing Black Screen, could be similar to ContentContainer.removePreviousContent()

        //        guard browserViewController.embedContent(nativeErrorPageViewController) else {
//            logger.log("Unable to embed private homepage", level: .debug, category: .coordinator)
//            return
//        }
     }

    func dismissFlow() {
        router.dismiss(animated: true, completion: nil)
        parentCoordinator?.didFinish(from: self)
    }
}
