// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import Shared
import ComponentLibrary

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
    private let oldEnhancedTrackingProtectionMenuVC: EnhancedTrackingProtectionMenuVC
    private let enhancedTrackingProtectionMenuVC: TrackingProtectionViewController
    weak var parentCoordinator: EnhancedTrackingProtectionCoordinatorDelegate?
    var trackingProtectionRefactorStatus = false

    init(router: Router,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager
    ) {
        let tab = tabManager.selectedTab
        let url = tab?.url ?? URL(fileURLWithPath: "")
        let displayTitle = tab?.displayTitle ?? ""
        let contentBlockerStatus = tab?.contentBlocker?.status ?? .blocking
        let connectionSecure = tab?.webView?.hasOnlySecureContent ?? true

        let etpViewModel = TrackingProtectionViewModel(
            url: url,
            displayTitle: displayTitle,
            connectionSecure: connectionSecure,
            globalETPIsEnabled: FirefoxTabContentBlocker.isTrackingProtectionEnabled(prefs: profile.prefs),
            contentBlockerStatus: contentBlockerStatus
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

        self.oldEnhancedTrackingProtectionMenuVC = EnhancedTrackingProtectionMenuVC(viewModel: oldEtpViewModel,
                                                                                    windowUUID: tabManager.windowUUID)

        self.profile = profile
        self.tabManager = tabManager
        super.init(router: router)
        enhancedTrackingProtectionMenuVC.enhancedTrackingProtectionMenuDelegate = self
        oldEnhancedTrackingProtectionMenuVC.enhancedTrackingProtectionMenuDelegate = self
    }

    func start(sourceView: UIView) {
        trackingProtectionRefactorStatus = featureFlags.isFeatureEnabled(.trackingProtectionRefactor, checking: .buildOnly)
        if trackingProtectionRefactorStatus {
            if UIDevice.current.userInterfaceIdiom == .phone {
                let bottomSheetViewModel = BottomSheetViewModel(
                    closeButtonA11yLabel: .CloseButtonTitle,
                    closeButtonA11yIdentifier:
                        AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.closeButton)
                let bottomSheetVC = BottomSheetViewController(viewModel: bottomSheetViewModel,
                                                              childViewController: enhancedTrackingProtectionMenuVC)
//                bottomSheetVC.
                router.present(bottomSheetVC)
//                enhancedTrackingProtectionMenuVC.modalPresentationStyle = .custom
//                enhancedTrackingProtectionMenuVC.transitioningDelegate = self
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
                oldEnhancedTrackingProtectionMenuVC.modalPresentationStyle = .custom
                oldEnhancedTrackingProtectionMenuVC.transitioningDelegate = self
            } else {
                oldEnhancedTrackingProtectionMenuVC.asPopover = true
                oldEnhancedTrackingProtectionMenuVC.modalPresentationStyle = .popover
                oldEnhancedTrackingProtectionMenuVC.popoverPresentationController?.sourceView = sourceView
                oldEnhancedTrackingProtectionMenuVC.popoverPresentationController?.permittedArrowDirections = .up
            }
            router.present(oldEnhancedTrackingProtectionMenuVC, animated: true, completion: nil)
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
