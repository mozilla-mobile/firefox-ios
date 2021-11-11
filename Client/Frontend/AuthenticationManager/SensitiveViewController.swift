// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import SnapKit
import Shared

class SensitiveViewController: UIViewController {
    private var blurredOverlay: UIImageView?
    private var isAuthenticated = false
    private var willEnterForegroundNotificationObserver: NSObjectProtocol?
    private var didEnterBackgroundNotificationObserver: NSObjectProtocol?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        willEnterForegroundNotificationObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [self] notification in
            if !self.isAuthenticated {
                AppAuthenticator.authenticateWithDeviceOwnerAuthentication { [self] result in
                    switch result {
                        case .success():
                            self.isAuthenticated = false
                            self.removedBlurredOverlay()
                        case .failure(_):
                            self.isAuthenticated = false
                            self.navigationController?.dismiss(animated: true, completion: nil)
                            self.dismiss(animated: true)
                    }
                }
            }
        }

        didEnterBackgroundNotificationObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [self] notification in
            self.isAuthenticated = false
            self.installBlurredOverlay()
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
        if self.blurredOverlay == nil {
            if let snapshot = view.screenshot() {
                let blurredSnapshot = snapshot.applyBlur(withRadius: 10, blurType: BOXFILTER, tintColor: UIColor(white: 1, alpha: 0.3), saturationDeltaFactor: 1.8, maskImage: nil)
                let blurredOverlay = UIImageView(image: blurredSnapshot)
                self.blurredOverlay = blurredOverlay
                view.addSubview(blurredOverlay)
                blurredOverlay.snp.makeConstraints { $0.edges.equalTo(self.view) }
                view.layoutIfNeeded()
            }
        }
    }

    private func removedBlurredOverlay() {
        self.blurredOverlay?.removeFromSuperview()
        self.blurredOverlay = nil
    }
}
