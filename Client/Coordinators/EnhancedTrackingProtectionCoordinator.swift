// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol EnhancedTrackingProtectionCoordinatorDelegate: AnyObject {
    func didFinishEnhancedTrackingProtection(from coordinator: EnhancedTrackingProtectionCoordinator)
}

class EnhancedTrackingProtectionCoordinator: BaseCoordinator {
    private let profile: Profile
    private let tab: Tab
    private let enhancedTrackingProtectionMenuVC: EnhancedTrackingProtectionMenuVC
    weak var parentCoordinator: EnhancedTrackingProtectionCoordinatorDelegate?
    init(
        router: Router,
        profile: Profile = AppContainer.shared.resolve(),
        tab: Tab = AppContainer.shared.resolve()
    ) {
        let etpViewModel = EnhancedTrackingProtectionMenuVM(tab: tab, profile: profile)
        self.enhancedTrackingProtectionMenuVC = EnhancedTrackingProtectionMenuVC(viewModel: etpViewModel)
        self.profile = profile
        self.tab = tab
        super.init(router: router)
    }
    func start() {
    }
}
