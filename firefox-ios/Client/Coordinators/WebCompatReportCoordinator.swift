// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit

@MainActor
protocol WebCompatReportCoordinatorNavigationDelegate: AnyObject {
    func webCompatReportOpenURLInNewTab(_ url: URL)
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
        themeManager: ThemeManager = AppContainer.shared.resolve(),
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
        // Dismiss first, otherwise the explainer loads in a tab hidden behind the sheet.
        dismissReport { [weak self] in
            self?.navigationDelegate?.webCompatReportOpenURLInNewTab(url)
        }
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
