/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import SwiftKeychainWrapper

enum AuthenticationState {
    case notAuthenticating
    case presenting
}

class SensitiveViewController: UIViewController {
    var promptingForTouchID: Bool = false
    var backgroundedBlur: UIImageView?
    var authState: AuthenticationState = .notAuthenticating

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(checkIfUserRequiresValidation), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(checkIfUserRequiresValidation), name: UIApplication.didBecomeActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(blurContents), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(blurContents), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    @objc func checkIfUserRequiresValidation() {
        guard authState != .presenting else {
            return
        }

        presentedViewController?.dismiss(animated: false, completion: nil)
        guard let authInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo(), authInfo.requiresValidation() else {
            removeBackgroundedBlur()
            return
        }

        promptingForTouchID = true
        AppAuthenticator.presentAuthenticationUsingInfo(authInfo,
            touchIDReason: .AuthenticationLoginsTouchReason,
            success: {
                self.promptingForTouchID = false
                self.authState = .notAuthenticating
                self.removeBackgroundedBlur()
            },
            cancel: {
                self.promptingForTouchID = false
                self.authState = .notAuthenticating
                self.navigationController?.dismiss(animated: true, completion: nil)
                self.dismiss(animated: true)
            },
            fallback: {
                self.promptingForTouchID = false
                AppAuthenticator.presentPasscodeAuthentication(self.navigationController).uponQueue(.main) { isOk in
                    if isOk {
                        self.removeBackgroundedBlur()
                        self.navigationController?.dismiss(animated: true, completion: nil)
                        self.authState = .notAuthenticating
                    } else {
                        self.navigationController?.dismiss(animated: true, completion: nil)
                        self.dismiss(animated: true)
                        self.authState = .notAuthenticating
                    }
                }
            }
        )
        authState = .presenting
    }

    @objc func blurContents() {
        if backgroundedBlur == nil {
            backgroundedBlur = addBlurredContent()
        }
    }

    func removeBackgroundedBlur() {
        if !promptingForTouchID {
            backgroundedBlur?.removeFromSuperview()
            backgroundedBlur = nil
        }
    }

    fileprivate func addBlurredContent() -> UIImageView? {
        guard let snapshot = view.screenshot() else {
            return nil
        }

        let blurredSnapshot = snapshot.applyBlur(withRadius: 10, blurType: BOXFILTER, tintColor: UIColor(white: 1, alpha: 0.3), saturationDeltaFactor: 1.8, maskImage: nil)
        let blurView = UIImageView(image: blurredSnapshot)
        view.addSubview(blurView)
        blurView.snp.makeConstraints { $0.edges.equalTo(self.view) }
        view.layoutIfNeeded()

        return blurView
    }
}

