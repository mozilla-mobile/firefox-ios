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

protocol ETPCoordinatorSSLStatusDelegate: AnyObject {
    var showHasOnlySecureContentInTrackingPanel: Bool { get }
}

class EnhancedTrackingProtectionCoordinator: BaseCoordinator,
                                             TrackingProtectionMenuDelegate,
                                             EnhancedTrackingProtectionMenuDelegate,
                                             FeatureFlaggable {
    private struct UX {
        static let popoverPreferredSize = CGSize(width: 480, height: 540)
    }

    private let profile: Profile
    private let tabManager: TabManager
    private var legacyEnhancedTrackingProtectionMenuVC: EnhancedTrackingProtectionMenuVC?
    private var enhancedTrackingProtectionMenuVC: TrackingProtectionViewController?
    weak var parentCoordinator: EnhancedTrackingProtectionCoordinatorDelegate?
    private var trackingProtectionRefactorStatus: Bool {
        featureFlags.isFeatureEnabled(.trackingProtectionRefactor, checking: .buildOnly)
    }
    private var trackingProtectionNavController: UINavigationController?

    init(router: Router,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager,
         secureConnectionDelegate: ETPCoordinatorSSLStatusDelegate
    ) {
        let tab = tabManager.selectedTab
        let url = tab?.url ?? URL(fileURLWithPath: "")
        let displayTitle = tab?.displayTitle ?? ""
        let contentBlockerStatus = tab?.contentBlocker?.status ?? .blocking
        let contentBlockerStats = tab?.contentBlocker?.stats
        let connectionSecure = secureConnectionDelegate.showHasOnlySecureContentInTrackingPanel
        self.profile = profile
        self.tabManager = tabManager
        super.init(router: router)
        if self.trackingProtectionRefactorStatus {
            let etpViewModel = TrackingProtectionModel(
                url: url,
                displayTitle: displayTitle,
                connectionSecure: connectionSecure,
                globalETPIsEnabled: FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs),
                contentBlockerStatus: contentBlockerStatus,
                contentBlockerStats: contentBlockerStats,
                selectedTab: tabManager.selectedTab
            )

            enhancedTrackingProtectionMenuVC = TrackingProtectionViewController(viewModel: etpViewModel,
                                                                                profile: profile,
                                                                                windowUUID: tabManager.windowUUID)
            enhancedTrackingProtectionMenuVC?.enhancedTrackingProtectionMenuDelegate = self
            trackingProtectionNavController = UINavigationController(
                rootViewController: enhancedTrackingProtectionMenuVC ?? UIViewController()
            )
            trackingProtectionNavController?.isNavigationBarHidden = true
        } else {
            let oldEtpViewModel = EnhancedTrackingProtectionMenuVM(
                url: url,
                displayTitle: displayTitle,
                connectionSecure: connectionSecure,
                globalETPIsEnabled: FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs),
                contentBlockerStatus: contentBlockerStatus
            )

            legacyEnhancedTrackingProtectionMenuVC = EnhancedTrackingProtectionMenuVC(viewModel: oldEtpViewModel,
                                                                                      windowUUID: tabManager.windowUUID)
            legacyEnhancedTrackingProtectionMenuVC?.enhancedTrackingProtectionMenuDelegate = self
        }
    }

    func start(sourceView: UIView) {
        if trackingProtectionRefactorStatus, let enhancedTrackingProtectionMenuVC {
            if UIDevice.current.userInterfaceIdiom == .phone {
                if let sheetPresentationController = enhancedTrackingProtectionMenuVC.sheetPresentationController {
                    sheetPresentationController.detents = [.medium(), .large()]
                    sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = true
                    sheetPresentationController.preferredCornerRadius = TPMenuUX.UX.modalMenuCornerRadius
                }
                enhancedTrackingProtectionMenuVC.asPopover = true
                guard let trackingProtectionNavController = trackingProtectionNavController else { return }
                router.present(trackingProtectionNavController, animated: true, completion: nil)
            } else {
                guard let trackingProtectionNavController = trackingProtectionNavController else { return }
                trackingProtectionNavController.preferredContentSize = UX.popoverPreferredSize
                trackingProtectionNavController.modalPresentationStyle = .popover
                trackingProtectionNavController.popoverPresentationController?.sourceView = sourceView
                trackingProtectionNavController.popoverPresentationController?.permittedArrowDirections = .up
                router.present(trackingProtectionNavController, animated: true, completion: nil)
            }
        } else if let legacyEnhancedTrackingProtectionMenuVC {
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
