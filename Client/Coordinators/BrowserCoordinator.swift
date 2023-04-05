// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class BrowserCoordinator: BaseCoordinator {
    var browserViewController: BrowserViewController

    init(router: Router,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve()) {
        self.browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        super.init(router: router)
    }

    func start(with launchType: LaunchType?) {
        router.setRootViewController(browserViewController, hideBar: true, animated: true)

        if let launchType = launchType, launchType.canLaunch(fromType: .BrowserCoordinator) {
            startLaunch(with: launchType)
        }
    }

    // MARK: - Helper methods

    private func startLaunch(with launchType: LaunchType) {
        let launchCoordinator = LaunchCoordinator(router: router)
        add(child: launchCoordinator)
        launchCoordinator.start(with: launchType) {
            self.router.dismiss(animated: true, completion: nil)
            self.remove(child: launchCoordinator)
        }
    }
}
