// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation

/// Presents the system camera capture UI and owns its delegate conformance.
final class CameraCoordinator: BaseCoordinator,
                               UIImagePickerControllerDelegate,
                               UINavigationControllerDelegate {
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let onComplete: (UIImage?) -> Void
    private let isCameraAvailable: () -> Bool
    private let cameraAuthorizationStatus: () -> AVAuthorizationStatus
    private let requestCameraAccess: () async -> Bool

    init(parentCoordinatorDelegate: ParentCoordinatorDelegate?,
         router: Router,
         isCameraAvailable: @escaping () -> Bool = { UIImagePickerController.isSourceTypeAvailable(.camera) },
         cameraAuthorizationStatus: @escaping () -> AVAuthorizationStatus = {
             AVCaptureDevice.authorizationStatus(for: .video)
         },
         requestCameraAccess: @escaping () async -> Bool = {
             await AVCaptureDevice.requestAccess(for: .video)
         },
         onComplete: @escaping (UIImage?) -> Void) {
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.onComplete = onComplete
        self.isCameraAvailable = isCameraAvailable
        self.cameraAuthorizationStatus = cameraAuthorizationStatus
        self.requestCameraAccess = requestCameraAccess
        super.init(router: router)
    }

    func start() {
        guard isCameraAvailable() else {
            finish(with: nil)
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        router.present(picker, animated: true) { [weak self] in
            self?.finish(with: nil)
        }

        switch cameraAuthorizationStatus() {
        case .denied, .restricted:
            // Access was refused in a previous session: surface the alert over the interface.
            presentCameraAccessDeniedAlert(over: picker)
        case .notDetermined:
            // Presenting the interface triggers the system permission prompt; dismiss the
            // interface if the user refuses access, without surfacing a second alert.
            Task { [weak self] in await self?.dismissCameraInterfaceIfAccessRefused() }
        default:
            break
        }
    }

    // MARK: - Camera permission
    func dismissCameraInterfaceIfAccessRefused() async {
        let granted = await requestCameraAccess()
        guard !granted else { return }
        dismissCameraInterface()
    }

    private func presentCameraAccessDeniedAlert(over presenter: UIViewController) {
        let alert = UIAlertController.cameraAccessDisabledAlert { [weak self] _ in
            self?.dismissCameraInterface()
        }

        if let transitionCoordinator = presenter.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { [weak presenter] _ in
                presenter?.present(alert, animated: true)
            }
        } else {
            presenter.present(alert, animated: true)
        }
    }

    /// Dismisses the camera interface and ends the flow without a captured image.
    func dismissCameraInterface() {
        router.dismiss(animated: true)
        finish(with: nil)
    }

    private func finish(with image: UIImage?) {
        onComplete(image)
        parentCoordinatorDelegate?.didFinish(from: self)
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        router.dismiss(animated: true)
        finish(with: info[.originalImage] as? UIImage)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        router.dismiss(animated: true)
        finish(with: nil)
    }
}
