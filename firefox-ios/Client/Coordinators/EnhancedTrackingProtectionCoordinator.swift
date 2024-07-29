// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import Shared

protocol EnhancedTrackingProtectionCoordinatorDelegate: AnyObject {
    func didFinishEnhancedTrackingProtection(from coordinator: EnhancedTrackingProtectionCoordinator)
    func settingsOpenPage(settings: Route.SettingsSection)
}

class EnhancedTrackingProtectionCoordinator: BaseCoordinator,
                                             TrackingProtectionMenuDelegate,
                                             EnhancedTrackingProtectionMenuDelegate,
                                             FeatureFlaggable {
    private let profile: Profile
    private let tabManager: TabManager
    private let legacyEnhancedTrackingProtectionMenuVC: EnhancedTrackingProtectionMenuVC
    private let enhancedTrackingProtectionMenuVC: TrackingProtectionViewController
    weak var parentCoordinator: EnhancedTrackingProtectionCoordinatorDelegate?

    init(router: Router,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager
    ) {
        let tab = tabManager.selectedTab
        let url = tab?.url ?? URL(fileURLWithPath: "")
        let displayTitle = tab?.displayTitle ?? ""
        let contentBlockerStatus = tab?.contentBlocker?.status ?? .blocking
        let contentBlockerStats = tab?.contentBlocker?.stats
        let connectionSecure = tab?.webView?.hasOnlySecureContent ?? true
        let etpViewModel = TrackingProtectionModel(
            url: url,
            displayTitle: displayTitle,
            connectionSecure: connectionSecure,
            globalETPIsEnabled: FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs),
            contentBlockerStatus: contentBlockerStatus,
            contentBlockerStats: contentBlockerStats
        )

        self.enhancedTrackingProtectionMenuVC = TrackingProtectionViewController(viewModel: etpViewModel,
                                                                                 windowUUID: tabManager.windowUUID)
        let oldEtpViewModel = EnhancedTrackingProtectionMenuVM(
            url: url,
            displayTitle: displayTitle,
            connectionSecure: connectionSecure,
            globalETPIsEnabled: FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs),
            contentBlockerStatus: contentBlockerStatus
        )

        self.legacyEnhancedTrackingProtectionMenuVC = EnhancedTrackingProtectionMenuVC(viewModel: oldEtpViewModel,
                                                                                       windowUUID: tabManager.windowUUID)
        self.profile = profile
        self.tabManager = tabManager
        super.init(router: router)
        enhancedTrackingProtectionMenuVC.enhancedTrackingProtectionMenuDelegate = self
    }

    func start(sourceView: UIView) {
        let trackingProtectionRefactorStatus =
        featureFlags.isFeatureEnabled(.trackingProtectionRefactor, checking: .buildOnly)
        if trackingProtectionRefactorStatus {
            if UIDevice.current.userInterfaceIdiom == .phone {
                if let sheetPresentationController = enhancedTrackingProtectionMenuVC.sheetPresentationController {
                    sheetPresentationController.detents = [.medium(), .large()]
                    sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = true
                    sheetPresentationController.preferredCornerRadius = 12
                }
                router.present(enhancedTrackingProtectionMenuVC, animated: true, completion: nil)
            } else {
                enhancedTrackingProtectionMenuVC.asPopover = true
                if trackingProtectionRefactorStatus {
                    enhancedTrackingProtectionMenuVC.preferredContentSize = CGSize(width: 480, height: 517)
                }
                enhancedTrackingProtectionMenuVC.modalPresentationStyle = .popover
                enhancedTrackingProtectionMenuVC.popoverPresentationController?.sourceView = sourceView
                enhancedTrackingProtectionMenuVC.popoverPresentationController?.permittedArrowDirections = .up
                router.present(enhancedTrackingProtectionMenuVC, animated: true, completion: nil)
            }
        } else {
            if UIDevice.current.userInterfaceIdiom == .phone {
                legacyEnhancedTrackingProtectionMenuVC.modalPresentationStyle = .custom
                legacyEnhancedTrackingProtectionMenuVC.transitioningDelegate = self
            } else {
                legacyEnhancedTrackingProtectionMenuVC.asPopover = true
                legacyEnhancedTrackingProtectionMenuVC.modalPresentationStyle = .popover
                legacyEnhancedTrackingProtectionMenuVC.popoverPresentationController?.sourceView = sourceView
                legacyEnhancedTrackingProtectionMenuVC.popoverPresentationController?.permittedArrowDirections = .up
            }
            router.present(legacyEnhancedTrackingProtectionMenuVC, animated: true, completion: nil)
        }
    }

    // MARK: - EnhancedTrackingProtectionMenuDelegate
    func settingsOpenPage(settings: Route.SettingsSection) {
        parentCoordinator?.didFinishEnhancedTrackingProtection(from: self)
        parentCoordinator?.settingsOpenPage(settings: settings)
    }

    func didFinish() {
        parentCoordinator?.didFinishEnhancedTrackingProtection(from: self)
    }
}

extension EnhancedTrackingProtectionCoordinator: UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        let globalETPStatus = FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs)
        let slideOverPresentationController = SlideOverPresentationController(presentedViewController: presented,
                                                                              presenting: presenting,
                                                                              withGlobalETPStatus: globalETPStatus)
        slideOverPresentationController.enhancedTrackingProtectionMenuDelegate = self

        return slideOverPresentationController
    }
}
