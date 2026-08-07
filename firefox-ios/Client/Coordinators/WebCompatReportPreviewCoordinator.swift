// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import WebCompatReporterKit

/// Owns the Report Preview sheet for as long as it is on screen. The report sheet is the
/// presenting context, so this is rooted at a router over it rather than the browser's.
final class WebCompatReportPreviewCoordinator: BaseCoordinator, WebCompatTechnicalDataDelegate {
    private let windowUUID: WindowUUID
    private let themeManager: ThemeManager
    private weak var parentCoordinator: ParentCoordinatorDelegate?

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
        let previewViewController = WebCompatTechnicalDataViewController(
            viewModel: payload.makePreviewViewModel(),
            windowUUID: windowUUID,
            themeManager: themeManager
        )
        previewViewController.delegate = self
        let previewNavigationController = UINavigationController(rootViewController: previewViewController)
        if let sheet = previewNavigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        router.present(previewNavigationController, animated: true) { [weak self] in
            // Runs when we dismiss through `UIAdaptivePresentationControllerDelegate`
            self?.didFinish()
        }
    }

    /// Takes the preview down without abandoning the report; only the form's own close does that.
    func dismissPreview(animated: Bool) {
        router.dismiss(animated: animated, completion: nil)
        didFinish()
    }

    // MARK: - WebCompatTechnicalDataDelegate

    func webCompatTechnicalDataDidRequestDismiss() {
        dismissPreview(animated: true)
    }

    func webCompatTechnicalDataDidTapScreenshot() {
        // Unreachable while the thumbnail is off; FXIOS-16450 wires up the screenshot viewer.
    }

    // MARK: - Private

    private func didFinish() {
        parentCoordinator?.didFinish(from: self)
    }
}
