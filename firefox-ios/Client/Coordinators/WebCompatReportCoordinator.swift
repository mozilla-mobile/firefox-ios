// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

/// What the report flow needs from the browser, which the flow itself can't reach.
@MainActor
protocol WebCompatReportCoordinatorNavigationDelegate: AnyObject {
    func webCompatReportDidSubmit()
}

final class WebCompatReportCoordinator: BaseCoordinator, WebCompatReportCoordinatorDelegate {
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private weak var navigationDelegate: WebCompatReportCoordinatorNavigationDelegate?
    private weak var reportViewController: WebCompatReportViewController?

    init(
        router: Router,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        parentCoordinatorDelegate: ParentCoordinatorDelegate?,
        navigationDelegate: WebCompatReportCoordinatorNavigationDelegate?
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.navigationDelegate = navigationDelegate
        super.init(router: router)
    }

    func start(reportedURL: URL?) {
        let reportViewController = WebCompatReportViewController(windowUUID: windowUUID, reportedURL: reportedURL)
        reportViewController.reportCoordinator = self
        self.reportViewController = reportViewController
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
        // Dismissing the sheet or opening a tab tears its Redux state down and loses the report.
        // `TermsOfUseLinkViewController` is a generic in-app web view, reused here despite the name.
        let linkViewController = TermsOfUseLinkViewController(
            url: url,
            windowUUID: windowUUID,
            themeManager: themeManager
        )
        let navigationController = UINavigationController(rootViewController: linkViewController)
        navigationController.modalPresentationStyle = .pageSheet
        reportViewController?.present(navigationController, animated: true)
    }

    private func dismissReport(completion: (() -> Void)? = nil) {
        router.dismiss(animated: true) { [weak self] in
            completion?()
            guard let self else { return }
            self.parentCoordinatorDelegate?.didFinish(from: self)
        }
    }
}
