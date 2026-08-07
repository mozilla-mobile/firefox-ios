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
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private weak var parentCoordinator: ParentCoordinatorDelegate?
    /// The sheet's own stack, so Technical Data pushes over the preview rather than replacing it.
    private weak var previewNavigationController: UINavigationController?
    private var payload: WebCompatReportPayload?

    init(
        router: Router,
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        parentCoordinator: ParentCoordinatorDelegate?
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    func start(payload: WebCompatReportPayload) {
        self.payload = payload
        let previewViewController = WebCompatReportPreviewViewController(
            viewModel: payload.makeReportPreviewViewModel(),
            windowUUID: windowUUID,
            themeManager: themeManager
        )
        previewViewController.delegate = self
        let navigationController = UINavigationController(rootViewController: previewViewController)
        previewNavigationController = navigationController
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

    func webCompatReportPreviewDidTapScreenshot() {
        // Unreachable while the thumbnail is off; FXIOS-16450 wires up the screenshot viewer.
    }

    func webCompatReportPreviewDidTapTechnicalData() {
        guard let payload, let previewNavigationController else { return }
        let technicalDataViewController = WebCompatTechnicalDataViewController(
            viewModel: payload.makeTechnicalDataViewModel(),
            windowUUID: windowUUID,
            themeManager: themeManager
        )
        technicalDataViewController.delegate = self
        // The raw payload needs the room.
        previewNavigationController.sheetPresentationController?.selectedDetentIdentifier = .large
        previewNavigationController.pushViewController(technicalDataViewController, animated: true)
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
