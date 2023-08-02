// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol DownloadsNavigationHandler: AnyObject {
    /// Handles the possibile navigations for a file.
    /// The source view is the view used to display a popover for the share controller.
    func handleFile(_ file: DownloadedFile, sourceView: UIView)
}

class DownloadsCoordinator: BaseCoordinator, DownloadsNavigationHandler, UIDocumentInteractionControllerDelegate {
    // MARK: - Properties

    private weak var parentCoordinator: LibraryCoordinatorDelegate?

    // MARK: - Initializers

    init(
        router: Router,
        parentCoordinator: LibraryCoordinatorDelegate?
    ) {
        self.parentCoordinator = parentCoordinator
        super.init(router: router)
    }

    // MARK: - DownloadsNavigationHandler

    func handleFile(_ file: DownloadedFile, sourceView: UIView) {
        if file.mimeType == MIMEType.Calendar {
            let docController = UIDocumentInteractionController(url: file.path)
            docController.delegate = self
            docController.presentPreview(animated: true)
            return
        }

        guard file.canShowInWebView
        else {
            shareFile(file, sourceView: sourceView)
            return
        }
        parentCoordinator?.libraryPanel(didSelectURL: file.path, visitType: .typed)
    }

    private func shareFile(_ file: DownloadedFile, sourceView: UIView) {
        let helper = ShareExtensionHelper(url: file.path, tab: nil)
        let controller = helper.createActivityViewController { _, _ in }

        if let popoverPresentationController = controller.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceView.bounds
            popoverPresentationController.permittedArrowDirections = .any
        }

        router.present(controller)
    }

    // MARK: - UIDocumentInteractionControllerDelegate

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return router.rootViewController ?? UIViewController()
    }
}
