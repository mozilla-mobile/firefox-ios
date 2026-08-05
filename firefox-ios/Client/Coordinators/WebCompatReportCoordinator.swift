// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

/// What the report flow needs from the browser, which the flow itself can't reach.
@MainActor
protocol WebCompatReportCoordinatorNavigationDelegate: AnyObject {
    func webCompatReportOpenURLInNewTab(_ url: URL)
    func webCompatReportDidSubmit()
}

final class WebCompatReportCoordinator: BaseCoordinator, WebCompatReportCoordinatorDelegate {
    private let windowUUID: WindowUUID
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private weak var navigationDelegate: WebCompatReportCoordinatorNavigationDelegate?

    init(
        router: Router,
        windowUUID: WindowUUID,
        parentCoordinatorDelegate: ParentCoordinatorDelegate?,
        navigationDelegate: WebCompatReportCoordinatorNavigationDelegate?
    ) {
        self.windowUUID = windowUUID
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.navigationDelegate = navigationDelegate
        super.init(router: router)
    }

    func start(reportedURL: URL?) {
        let reportViewController = WebCompatReportViewController(windowUUID: windowUUID, reportedURL: reportedURL)
        reportViewController.reportCoordinator = self
        router.present(reportViewController, animated: true, completion: nil)
    }

    // MARK: - WebCompatReportCoordinatorDelegate

    func webCompatReportViewControllerDidFinish() {
        dismissReport()
    }

    func webCompatReportViewControllerDidSubmit() {
        // Dismiss first, otherwise the toast is covered by the sheet.
        dismissReport { [weak self] in
            self?.navigationDelegate?.webCompatReportDidSubmit()
        }
    }

    func webCompatReportViewControllerDidTapLearnMore(url: URL) {
        // Dismiss first, otherwise the explainer loads in a tab hidden behind the sheet.
        dismissReport { [weak self] in
            self?.navigationDelegate?.webCompatReportOpenURLInNewTab(url)
        }
    }

    private func dismissReport(completion: (() -> Void)? = nil) {
        router.dismiss(animated: true) { [weak self] in
            completion?()
            guard let self else { return }
            self.parentCoordinatorDelegate?.didFinish(from: self)
        }
    }
}
