// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// Each scene has it's own scene coordinator, which is the root coordinator for a scene.
class SceneCoordinator: BaseCoordinator, OpenURLDelegate {
    var browserCoordinator: BrowserCoordinator?
    var launchCoordinator: LaunchCoordinator?

    func start(with profile: Profile = AppContainer.shared.resolve()) {
        let launchHelper = LaunchManager(profile: profile, openURLDelegate: self)
        if launchHelper.canLaunchFromSceneCoordinator, let launchType = launchHelper.getLaunchType() {
            launchCoordinator = LaunchCoordinator(router: router)
            launchCoordinator?.start(with: launchType)
        } else {
            browserCoordinator = BrowserCoordinator(router: router)
            browserCoordinator?.start(launchHelper: launchHelper)
        }
    }

    // MARK: OpenURLDelegate

    func didRequestToOpenInNewTab(url: URL, isPrivate: Bool, selectNewTab: Bool) {
        // FXIOS-6030: openURL in new tab route
    }
}
