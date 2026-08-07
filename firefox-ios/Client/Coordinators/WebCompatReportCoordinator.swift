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

final class WebCompatReportCoordinator: BaseCoordinator,
                                        WebCompatReportCoordinatorDelegate,
                                        ParentCoordinatorDelegate {
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private weak var navigationDelegate: WebCompatReportCoordinatorNavigationDelegate?
    private weak var reportViewController: WebCompatReportViewController?

    private var previewCoordinator: WebCompatReportPreviewCoordinator? {
        return childCoordinators.first { $0 is WebCompatReportPreviewCoordinator }
            as? WebCompatReportPreviewCoordinator
    }

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

    func webCompatReportViewControllerDidTapPreview(payload: WebCompatReportPayload) {
        guard let reportViewController, previewCoordinator == nil else { return }
        // The main router presents from the browser, which already shows the sheet, so the preview
        // goes up from the sheet itself.
        let previewCoordinator = WebCompatReportPreviewCoordinator(
            router: DefaultRouter(navigationController: reportViewController),
            windowUUID: windowUUID,
            themeManager: themeManager,
            parentCoordinator: self
        )
        add(child: previewCoordinator)
        previewCoordinator.start(payload: payload)
    }

    // MARK: - ParentCoordinatorDelegate

    func didFinish(from childCoordinator: Coordinator) {
        remove(child: childCoordinator)
    }

    /// Dismisses the preview first, so the sheet isn't pulled out from under it.
    private func dismissReport(completion: (() -> Void)? = nil) {
        previewCoordinator?.dismissPreview(animated: false)
        router.dismiss(animated: true) { [weak self] in
            completion?()
            guard let self else { return }
            self.parentCoordinatorDelegate?.didFinish(from: self)
        }
    }
}
