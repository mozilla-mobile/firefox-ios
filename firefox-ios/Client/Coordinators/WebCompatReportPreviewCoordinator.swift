// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import WebCompatReporterKit

/// Owns the Report Preview sheet and the Technical Data screen it pushes. The report sheet is the
/// presenting context, so this is rooted at a router over it rather than the browser's.
final class WebCompatReportPreviewCoordinator: BaseCoordinator,
                                               WebCompatReportPreviewDelegate,
                                               WebCompatTechnicalDataDelegate {
    private let payload: WebCompatReportPayload
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private weak var parentCoordinator: ParentCoordinatorDelegate?
    /// A second router, over the sheet's own stack: the injected one is rooted at the report form,
    /// so pushing through it would put Technical Data behind the sheet instead of on top of it.
    private var previewRouter: Router?
    private let previewRouterFactory: @MainActor (UINavigationController) -> Router
    /// Tracked so a second tap can't stack a duplicate on top.
    private weak var technicalDataViewController: WebCompatTechnicalDataViewController?

    init(
        payload: WebCompatReportPayload,
        router: Router,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        parentCoordinator: ParentCoordinatorDelegate?,
        previewRouterFactory: @MainActor @escaping (UINavigationController) -> Router = { navigationController in
            DefaultRouter(navigationController: navigationController)
        }
    ) {
        self.payload = payload
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.parentCoordinator = parentCoordinator
        self.previewRouterFactory = previewRouterFactory
        super.init(router: router)
    }

    func start() {
        let previewViewController = WebCompatReportPreviewViewController(
            viewModel: payload.makeReportPreviewViewModel(),
            windowUUID: windowUUID,
            themeManager: themeManager
        )
        previewViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: previewViewController)
        previewRouter = previewRouterFactory(navigationController)
        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        router.present(navigationController, animated: true) { [weak self] in
            // Runs when we dismiss through `UIAdaptivePresentationControllerDelegate`
            self?.didFinish()
        }
    }

    /// Takes the preview down without abandoning the report; only the form's own close does that.
    func dismissPreview(animated: Bool) {
        router.dismiss(animated: animated, completion: nil)
        didFinish()
    }

    // MARK: - WebCompatReportPreviewDelegate

    func webCompatReportPreviewDidRequestDismiss() {
        dismissPreview(animated: true)
    }

    func webCompatReportPreviewDidTapTechnicalData() {
        guard technicalDataViewController == nil else { return }
        let viewController = WebCompatTechnicalDataViewController(
            viewModel: payload.makeTechnicalDataViewModel(),
            windowUUID: windowUUID,
            themeManager: themeManager
        )
        viewController.delegate = self
        technicalDataViewController = viewController
        // The completion runs when it's popped, so the row can push a fresh screen again.
        previewRouter?.push(viewController) { [weak self] in
            self?.technicalDataViewController = nil
        }
    }

    // MARK: - WebCompatTechnicalDataDelegate

    func webCompatTechnicalDataDidRequestDismiss() {
        dismissPreview(animated: true)
    }

    // MARK: - Private

    private func didFinish() {
        parentCoordinator?.didFinish(from: self)
    }
}
