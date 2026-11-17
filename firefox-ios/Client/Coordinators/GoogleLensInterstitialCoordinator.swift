// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebKit

final class GoogleLensInterstitialCoordinator: BaseCoordinator {
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let tab: Tab
    private let themeManager: ThemeManager
    private var overlay: GoogleLensInterstitialViewController?
    private var loadingObservation: NSKeyValueObservation?
    private var isFinished = false

    init(parentCoordinatorDelegate: ParentCoordinatorDelegate?,
         router: Router,
         tab: Tab,
         themeManager: ThemeManager) {
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.tab = tab
        self.themeManager = themeManager
        super.init(router: router)
    }

    func start() {
        guard !isFinished, overlay == nil else { return }
        guard let webView = tab.webView else {
            stop()
            return
        }
        overlay = GoogleLensInterstitialViewController(windowUUID: tab.windowUUID, themeManager: themeManager)
        loadingObservation = webView.observe(\.isLoading, options: [.old, .new]) { [weak self] _, change in
            guard change.oldValue == true, change.newValue == false else { return }
            ensureMainThread { self?.stop() }
        }
        if let presented = router.navigationController.presentedViewController {
            guard presented.isBeingDismissed, let transition = presented.transitionCoordinator else {
                stop()
                return
            }
            transition.animate(alongsideTransition: nil) { [weak self] context in
                if context.isCancelled {
                    self?.stop()
                } else {
                    self?.presentOverlay()
                }
            }
        } else {
            presentOverlay()
        }
    }

    func stop() {
        guard !isFinished else { return }
        isFinished = true
        loadingObservation?.invalidate()
        loadingObservation = nil
        if let overlay, router.navigationController.presentedViewController === overlay {
            router.dismiss(animated: false)
        }
        overlay = nil
        parentCoordinatorDelegate?.didFinish(from: self)
    }

    private func presentOverlay() {
        guard !isFinished, let overlay else { return }
        router.present(overlay, animated: false)
    }
}
