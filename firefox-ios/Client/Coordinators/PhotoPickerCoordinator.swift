// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Photos
import PhotosUI
import UIKit

/// Presents the system photo library picker and owns its delegate conformance.
final class PhotoPickerCoordinator: BaseCoordinator, PHPickerViewControllerDelegate {
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let onComplete: ([PHPickerResult]) -> Void

    init(parentCoordinatorDelegate: ParentCoordinatorDelegate?,
         router: Router,
         onComplete: @escaping ([PHPickerResult]) -> Void) {
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.onComplete = onComplete
        super.init(router: router)
    }

    func start() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        router.present(picker, animated: true) { [weak self] in
            self?.finish(with: [])
        }
    }

    // MARK: - PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        router.dismiss(animated: true)
        finish(with: results)
    }

    private func finish(with results: [PHPickerResult]) {
        onComplete(results)
        parentCoordinatorDelegate?.didFinish(from: self)
    }
}
