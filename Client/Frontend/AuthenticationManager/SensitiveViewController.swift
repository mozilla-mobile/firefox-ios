/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Shared

class SensitiveViewController: UIViewController {
    private var backgroundedBlur: UIVisualEffectView?
    private var isAuthenticated: Bool = false

    private var willEnterForegroundNotificationObserver: NSObjectProtocol?
    private var didEnterBackgroundNotificationObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        willEnterForegroundNotificationObserver = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [unowned self] notification in
            if !self.isAuthenticated {
                AppAuthenticator.authenticateWithDeviceOwnerAuthentication { result in
                    switch result {
                        case .success():
                            self.isAuthenticated = true
                            self.removeBackgroundedBlur()
                        case .failure(_):
                            self.isAuthenticated = false
                            self.navigationController?.dismiss(animated: true, completion: nil)
                            self.dismiss(animated: true)
                    }
                }
            }
        }

        didEnterBackgroundNotificationObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [unowned self] notification in
            self.isAuthenticated = false
            self.blurContents()
        }
    }
    
    deinit {
        if let observer = willEnterForegroundNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = didEnterBackgroundNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

extension SensitiveViewController {
    private func blurContents() {
        if backgroundedBlur == nil {
            backgroundedBlur = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
            view.addSubview(backgroundedBlur!)
            backgroundedBlur!.snp.makeConstraints { $0.edges.equalTo(self.view) }
            view.layoutIfNeeded()
        }
    }

    private func removeBackgroundedBlur() {
        backgroundedBlur?.removeFromSuperview()
        backgroundedBlur = nil
    }
}
