// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class BrowserCoordinator: BaseCoordinator {
    var launchScreenManager: LaunchScreenManager
    var browserViewController: BrowserViewController

    init(router: Router,
         launchScreenManager: LaunchScreenManager,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve()) {
        self.launchScreenManager = launchScreenManager
        self.browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        super.init(router: router)
    }

    func start() {
        router.setRootViewController(browserViewController, hideBar: true, animated: true)

        if let launchType = launchScreenManager.getLaunchType(forType: .BrowserCoordinator) {
            startLaunch(with: launchType)
        }
    }

    // MARK: - Helper methods

    private func startLaunch(with launchType: LaunchType) {
        let launchCoordinator = LaunchCoordinator(router: router,
                                                  launchScreenManager: launchScreenManager)
        add(child: launchCoordinator)
        launchCoordinator.start(with: launchType) {
            self.router.dismiss(animated: true, completion: nil)
            self.remove(child: launchCoordinator)
        }
    }
}
