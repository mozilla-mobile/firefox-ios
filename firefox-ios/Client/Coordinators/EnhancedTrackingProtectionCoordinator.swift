// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

protocol EnhancedTrackingProtectionCoordinatorDelegate: AnyObject {
    @MainActor
    func didFinishEnhancedTrackingProtection(from coordinator: EnhancedTrackingProtectionCoordinator)
    @MainActor
    func settingsOpenPage(settings: Route.SettingsSection)
}

protocol ETPCoordinatorSSLStatusDelegate: AnyObject {
    @MainActor
    var showHasOnlySecureContentInTrackingPanel: Bool { get }
}

class EnhancedTrackingProtectionCoordinator: BaseCoordinator,
                                             TrackingProtectionMenuDelegate,
                                             FeatureFlaggable {
    private struct UX {
        static let popoverPreferredSize = CGSize(width: 480, height: 540)
    }

    private let profile: Profile
    private let tabManager: TabManager
    private var trackingProtectionMenuVC: TrackingProtectionViewController?
    weak var parentCoordinator: EnhancedTrackingProtectionCoordinatorDelegate?
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

        let etpViewModel = TrackingProtectionModel(
            userDefaults: UserDefaults(suiteName: AppInfo.sharedContainerIdentifier),
            url: url,
            displayTitle: displayTitle,
            connectionSecure: connectionSecure,
            globalETPIsEnabled: FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs),
            contentBlockerStatus: contentBlockerStatus,
            contentBlockerStats: contentBlockerStats,
            selectedTab: tabManager.selectedTab
        )

        trackingProtectionMenuVC = TrackingProtectionViewController(viewModel: etpViewModel,
                                                                    profile: profile,
                                                                    windowUUID: tabManager.windowUUID)
        trackingProtectionMenuVC?.trackingProtectionMenuDelegate = self
        trackingProtectionNavController = UINavigationController(
            rootViewController: trackingProtectionMenuVC ?? UIViewController()
        )
        trackingProtectionNavController?.isNavigationBarHidden = true
    }

    func start(sourceView: UIView) {
        guard let trackingProtectionMenuVC else { return }

        if UIDevice.current.userInterfaceIdiom == .phone {
            if let sheetPresentationController = trackingProtectionMenuVC.sheetPresentationController {
                sheetPresentationController.detents = [.medium(), .large()]
                sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = true
                sheetPresentationController.preferredCornerRadius = TPMenuUX.UX.modalMenuCornerRadius
            }
            trackingProtectionMenuVC.asPopover = true
            guard let trackingProtectionNavController = trackingProtectionNavController else { return }
            trackingProtectionNavController.sheetPresentationController?.prefersEdgeAttachedInCompactHeight = true
            router.present(trackingProtectionNavController, animated: true) { [weak self] in
                // Ensures the VC gets deinit when we dismiss through `UIAdaptivePresentationControllerDelegate`
                self?.didFinish()
            }
        } else {
            guard let trackingProtectionNavController = trackingProtectionNavController else { return }
            trackingProtectionNavController.preferredContentSize = UX.popoverPreferredSize
            trackingProtectionNavController.modalPresentationStyle = .popover
            trackingProtectionNavController.popoverPresentationController?.sourceView = sourceView
            trackingProtectionNavController.popoverPresentationController?.permittedArrowDirections = .up
            router.present(trackingProtectionNavController, animated: true) { [weak self] in
                // Ensures the VC gets deinit when we dismiss through `UIAdaptivePresentationControllerDelegate`
                self?.didFinish()
            }
        }
    }

    // MARK: - TrackingProtectionMenuDelegate
    func settingsOpenPage(settings: Route.SettingsSection) {
        parentCoordinator?.didFinishEnhancedTrackingProtection(from: self)
        parentCoordinator?.settingsOpenPage(settings: settings)
    }

    func didFinish() {
        parentCoordinator?.didFinishEnhancedTrackingProtection(from: self)
    }
}
