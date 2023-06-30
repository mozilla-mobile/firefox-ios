// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import Shared

protocol EnhancedTrackingProtectionCoordinatorDelegate: AnyObject {
    func didFinishEnhancedTrackingProtection(from coordinator: EnhancedTrackingProtectionCoordinator)
}

class EnhancedTrackingProtectionCoordinator: BaseCoordinator {
    private let profile: Profile
    private let tabManager: TabManager
    private let enhancedTrackingProtectionMenuVC: EnhancedTrackingProtectionMenuVC
    weak var parentCoordinator: EnhancedTrackingProtectionCoordinatorDelegate?

    init(router: Router,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve()
    ) {
        let tab = tabManager.selectedTab
        let url = tab?.url ?? URL(fileURLWithPath: "")
        let displayTitle = tab?.displayTitle ?? ""
        let contentBlockerStatus = tab?.contentBlocker?.status ?? .blocking
        let connectionSecure = tab?.webView?.hasOnlySecureContent ?? true
        let etpViewModel = EnhancedTrackingProtectionMenuVM(
            url: url,
            displayTitle: displayTitle,
            connectionSecure: connectionSecure,
            globalETPIsEnabled: FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs),
            contentBlockerStatus: contentBlockerStatus)

        self.enhancedTrackingProtectionMenuVC = EnhancedTrackingProtectionMenuVC(viewModel: etpViewModel)
        self.profile = profile
        self.tabManager = tabManager
        super.init(router: router)
    }

    func start() {
        router.push(enhancedTrackingProtectionMenuVC)
    }

    func didFinish() {
        parentCoordinator?.didFinishEnhancedTrackingProtection(from: self)
    }
}
