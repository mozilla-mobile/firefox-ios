// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation

/// Identifies the app flow that prompted showing the system camera interface
enum CameraReason: String {
    case googleLens
}

/// Presents the system camera capture UI and owns its delegate conformance.
final class CameraCoordinator: BaseCoordinator,
                               UIImagePickerControllerDelegate,
                               UINavigationControllerDelegate {
    private weak var parentCoordinatorDelegate: ParentCoordinatorDelegate?
    private let onComplete: (UIImage?) -> Void
    private let isCameraAvailable: Bool
    private let cameraAuthorizationStatus: () -> AVAuthorizationStatus
    private let requestCameraAccess: () async -> Bool
    private let cameraReason: CameraReason
    private let cameraTelemetry: SystemCameraTelemetryProtocol

    init(
        parentCoordinatorDelegate: ParentCoordinatorDelegate?,
        router: Router,
        isCameraAvailable: Bool = UIImagePickerController.isSourceTypeAvailable(.camera),
        cameraAuthorizationStatus: @escaping () -> AVAuthorizationStatus = {
            AVCaptureDevice.authorizationStatus(for: .video)
        },
        requestCameraAccess: @escaping () async -> Bool = {
            await AVCaptureDevice.requestAccess(for: .video)
        },
        cameraReason: CameraReason,
        cameraTelemetry: SystemCameraTelemetryProtocol = SystemCameraTelemetry(),
        onComplete: @escaping (UIImage?) -> Void
    ) {
        self.parentCoordinatorDelegate = parentCoordinatorDelegate
        self.onComplete = onComplete
        self.isCameraAvailable = isCameraAvailable
        self.cameraAuthorizationStatus = cameraAuthorizationStatus
        self.requestCameraAccess = requestCameraAccess
        self.cameraReason = cameraReason
        self.cameraTelemetry = cameraTelemetry
        super.init(router: router)
    }

    func start() {
        guard isCameraAvailable else {
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
            presentCameraAccessDeniedAlert(over: picker)
        case .notDetermined:
            // If not determined, presenting the interface triggers the system permission prompt.
            // Dismiss the interface if the user refuses access.
            Task { [weak self] in await self?.handleCameraAccessRequest() }
        case .authorized:
            cameraTelemetry.shown(reason: cameraReason)
        @unknown default:
            break
        }
    }

    // MARK: - Camera permission
    func handleCameraAccessRequest() async {
        let granted = await requestCameraAccess()
        cameraTelemetry.permissionResponded(reason: cameraReason, granted: granted)
        if granted {
            cameraTelemetry.shown(reason: cameraReason)
        } else {
            dismissCameraInterface()
        }
    }

    private func presentCameraAccessDeniedAlert(over presenter: UIViewController) {
        let alert = UIAlertController.cameraAccessDisabledAlert { [weak self] _ in
            self?.dismissCameraInterface()
        }

        // Wait for picker to finish presenting before presenting alert over it (in the case of .denied and .restricted)
        if let transitionCoordinator = presenter.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { [weak presenter] _ in
                presenter?.present(alert, animated: true)
            }
        } else {
            presenter.present(alert, animated: true)
        }
    }

    func dismissCameraInterface() {
        router.dismiss(animated: true)
        finish(with: nil)
    }

    private func finish(with image: UIImage?, photoSelected: Bool = false) {
        if isCameraAvailable && cameraAuthorizationStatus() == .authorized {
            cameraTelemetry.closed(reason: cameraReason, photoSelected: photoSelected)
        }
        onComplete(image)
        parentCoordinatorDelegate?.didFinish(from: self)
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        router.dismiss(animated: true)
        finish(with: info[.originalImage] as? UIImage, photoSelected: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        router.dismiss(animated: true)
        finish(with: nil)
    }
}
