// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

import Shared

class SensitiveViewController: UIViewController {
    private var blurredOverlay: UIImageView?
    private var isAuthenticated = false
    private var willEnterForegroundNotificationObserver: NSObjectProtocol?
    private var didEnterBackgroundNotificationObserver: NSObjectProtocol?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        willEnterForegroundNotificationObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [self] notification in
            if !isAuthenticated {
                AppAuthenticator.authenticateWithDeviceOwnerAuthentication { [self] result in
                    switch result {
                        case .success():
                            isAuthenticated = false
                            removedBlurredOverlay()
                        case .failure(_):
                            isAuthenticated = false
                            navigationController?.dismiss(animated: true, completion: nil)
                            dismiss(animated: true)
                    }
                }
            }
        }

        didEnterBackgroundNotificationObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [self] notification in
            isAuthenticated = false
            installBlurredOverlay()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let observer = willEnterForegroundNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        if let observer = didEnterBackgroundNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

extension SensitiveViewController {
    private func installBlurredOverlay() {
        if blurredOverlay == nil {
            if let snapshot = view.screenshot() {
                let blurredSnapshot = snapshot.applyBlur(withRadius: 10, blurType: BOXFILTER, tintColor: UIColor(white: 1, alpha: 0.3), saturationDeltaFactor: 1.8, maskImage: nil)
                let blurredOverlay = UIImageView(image: blurredSnapshot)
                self.blurredOverlay = blurredOverlay
                view.addSubview(blurredOverlay)

                NSLayoutConstraint.activate([
                    blurredOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    blurredOverlay.topAnchor.constraint(equalTo: view.topAnchor),
                    blurredOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    blurredOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])

                view.layoutIfNeeded()
            }
        }
    }

    private func removedBlurredOverlay() {
        blurredOverlay?.removeFromSuperview()
        blurredOverlay = nil
    }
}
