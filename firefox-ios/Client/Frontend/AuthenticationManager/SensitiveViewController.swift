// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

class SensitiveViewController: UIViewController {
    private var backgroundBlurView: UIVisualEffectView?
    private var isAuthenticated = false
    private var sceneWillEnterForegroundNotificationObserver: NSObjectProtocol?
    private var didEnterBackgroundNotificationObserver: NSObjectProtocol?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        sceneWillEnterForegroundNotificationObserver = NotificationCenter.default.addObserver(
            forName: UIScene.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let sensitiveWindowScene = self.view.window?.windowScene,
                  let notificationScene = notification.object as? UIWindowScene,
                  sensitiveWindowScene === notificationScene else { return }
            self.handleCheckAuthentication()
        }

        didEnterBackgroundNotificationObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }

            self.isAuthenticated = false
            self.installBlurredOverlay()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        [sceneWillEnterForegroundNotificationObserver,
         didEnterBackgroundNotificationObserver].forEach {
            guard let observer = $0 else { return }
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Utility func

    private func handleCheckAuthentication() {
        if !isAuthenticated {
            AppAuthenticator().authenticateWithDeviceOwnerAuthentication { [self] result in
                switch result {
                case .success:
                    isAuthenticated = false
                    removedBlurredOverlay()
                case .failure:
                    isAuthenticated = false
                    navigationController?.dismiss(animated: true, completion: nil)
                    dismiss(animated: true)
                }
            }
        }
    }
}

extension SensitiveViewController {
    private func installBlurredOverlay() {
        guard backgroundBlurView == nil else { return }
        let blur = UIBlurEffect(style: .systemMaterialDark)
        let backgroundBlurView = IntensityVisualEffectView(effect: blur, intensity: 0.2)
        view.addSubview(backgroundBlurView)
        backgroundBlurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundBlurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        self.backgroundBlurView = backgroundBlurView
    }

    private func removedBlurredOverlay() {
        backgroundBlurView?.removeFromSuperview()
        backgroundBlurView = nil
    }
}
