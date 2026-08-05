// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import WebCompatReporterKit

/// What the report flow needs from the browser, which the flow itself can't reach.
@MainActor
protocol WebCompatReportCoordinatorNavigationDelegate: AnyObject {
    func webCompatReportOpenURLInNewTab(_ url: URL)
    func webCompatReportDidSubmit()
}

final class WebCompatReportCoordinator: BaseCoordinator,
                                        WebCompatReportCoordinatorDelegate,
                                        WebCompatReportPreviewDelegate {
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private let tabManager: TabManager
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private weak var navigationDelegate: WebCompatReportCoordinatorNavigationDelegate?

    private weak var reportViewController: WebCompatReportViewController?
    /// The main router presents from the browser, which is already showing the sheet, so the
    /// preview needs a router rooted at the sheet itself.
    private var previewRouter: Router?

    init(
        router: Router,
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        tabManager: TabManager,
        parentCoordinatorDelegate: ParentCoordinatorDelegate?,
        navigationDelegate: WebCompatReportCoordinatorNavigationDelegate?
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.tabManager = tabManager
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
        // Dismiss first, otherwise the explainer loads in a tab hidden behind the sheet.
        dismissReport { [weak self] in
            self?.navigationDelegate?.webCompatReportOpenURLInNewTab(url)
        }
    }

    func webCompatReportViewControllerDidTapPreview(_ request: WebCompatPreviewRequest) {
        guard let reportViewController, let tab = tabManager.selectedTab else { return }
        let payload = WebCompatReportDataCollector.enrich(
            request.payload,
            tab: tab,
            includeBlockedList: request.includeBlockedList
        )
        let previewViewController = WebCompatReportPreviewViewController(
            viewModel: WebCompatReportViewController.makePreviewViewModel(payload: payload),
            windowUUID: windowUUID,
            themeManager: themeManager
        )
        previewViewController.delegate = self
        // The thumbnail is disabled for this integration: never handing the screen a screenshot
        // keeps the section out of the list entirely.
        let previewNavigationController = UINavigationController(rootViewController: previewViewController)
        if let sheet = previewNavigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        let previewRouter = DefaultRouter(navigationController: reportViewController)
        self.previewRouter = previewRouter
        previewRouter.present(previewNavigationController, animated: true)
    }

    // MARK: - WebCompatReportPreviewDelegate

    func webCompatReportPreviewDidRequestDismiss() {
        // Only the form's own close abandons the report; this keeps the draft.
        previewRouter?.dismiss(animated: true, completion: nil)
        previewRouter = nil
    }

    func webCompatReportPreviewDidTapScreenshot() {
        // Unreachable while the thumbnail is disabled. FXIOS-16186 wires this to
        // WebCompatFullPageScreenshotViewController once the screenshot ships.
    }

    /// Dismisses the preview first when it's up, so the sheet underneath isn't pulled out from
    /// under it.
    private func dismissReport(completion: (() -> Void)? = nil) {
        previewRouter?.dismiss(animated: false, completion: nil)
        previewRouter = nil
        router.dismiss(animated: true) { [weak self] in
            completion?()
            guard let self else { return }
            self.parentCoordinatorDelegate?.didFinish(from: self)
        }
    }
}
