// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import PhotosUI

/// Identifies the app flow that prompted showing the system photo picker interface
enum PhotoPickerReason: String {
    case googleLens
}

/// Presents the system photo library picker and owns its delegate conformance.
final class PhotoPickerCoordinator: BaseCoordinator, PHPickerViewControllerDelegate {
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let onComplete: ([PHPickerResult]) -> Void
    private let photoPickerReason: PhotoPickerReason
    private let photoPickerTelemetry: SystemPhotoPickerTelemetryProtocol

    init(parentCoordinatorDelegate: ParentCoordinatorDelegate?,
         router: Router,
         photoPickerReason: PhotoPickerReason,
         photoPickerTelemetry: SystemPhotoPickerTelemetryProtocol = SystemPhotoPickerTelemetry(),
         onComplete: @escaping ([PHPickerResult]) -> Void) {
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.onComplete = onComplete
        self.photoPickerReason = photoPickerReason
        self.photoPickerTelemetry = photoPickerTelemetry
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
        photoPickerTelemetry.shown(reason: photoPickerReason)
    }

    // MARK: - PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        router.dismiss(animated: true)
        finish(with: results)
    }

    private func finish(with results: [PHPickerResult]) {
        photoPickerTelemetry.closed(reason: photoPickerReason, photoSelected: !results.isEmpty)
        onComplete(results)
        parentCoordinatorDelegate?.didFinish(from: self)
    }
}
