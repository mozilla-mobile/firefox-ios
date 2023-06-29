// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol PasswordManagerFlowDelegate: AnyObject {}

class PasswordManagerCoordinator: BaseCoordinator, PasswordManagerFlowDelegate {
    let profile: Profile

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

    func showPasswordManager() {}

    func showPasswordOnboarding() {}

    func finishPasswordManagerFlow() {}
}
